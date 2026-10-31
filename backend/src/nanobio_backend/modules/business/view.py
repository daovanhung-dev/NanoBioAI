from __future__ import annotations

import hashlib
import re
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal, InvalidOperation
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.business_models import (
    AdminReconciliationDiscrepancy,
    AdminReconciliationRun,
    CommissionRecord,
    PaymentEvent,
    ReportExport,
    SalePayoutProfile,
    SalePointAdjustment,
    SalePointConversion,
    SaleProfile,
    SystemConfigVersion,
    WellnessPointAllocation,
    WellnessPointLedger,
    WellnessRankAccount,
    WellnessRedemptionAllocationUsage,
    WellnessRewardCode,
    WellnessRewardOffer,
    WellnessRewardRedemption,
    WellnessRewardWallet,
)
from nanobio_backend.db.models import (
    HealthSubject,
    ManualPaymentEvent,
    MembershipSubscription,
    ReferralCode,
    ReferralRelationship,
    User,
    now_utc,
)
from nanobio_backend.modules.admin.query import (
    add_audit,
    add_idempotency,
    find_idempotency,
    payload_hash,
)
from nanobio_backend.modules.business.models import (
    BusinessAdminMutation,
    ReferralAttachRequest,
    SaleConversionRequest,
    SaleParticipationRequest,
    SalePayoutProfileRequest,
    WellnessRedemptionRequest,
)


def get_sale_state(db: Session, user: User) -> dict[str, Any]:
    profile = db.get(SaleProfile, user.id)
    payout = db.get(SalePayoutProfile, user.id)
    referral_code = db.scalar(select(ReferralCode.code).where(ReferralCode.user_id == user.id))
    return {
        "sale_status": profile.status if profile else user.sale_status,
        "status": profile.status if profile else user.sale_status,
        "referral_code": referral_code,
        "terms_version": profile.terms_version if profile else None,
        "approved_at": _iso(profile.approved_at) if profile else None,
        "note": profile.note if profile else None,
        "payout_profile_complete": _payout_complete(payout),
    }


def request_sale_participation(
    db: Session, user: User, payload: SaleParticipationRequest
) -> dict[str, Any]:
    device_hash = payload.device_hash.strip().casefold()
    if not re.fullmatch(r"[a-f0-9]{32,128}", device_hash):
        raise ApiError(422, "INVALID_DEVICE_HASH", "Thiết bị chưa được xác thực.")
    with atomic(db):
        existing = db.get(SaleProfile, user.id)
        if existing is None:
            reused = db.scalar(
                select(SaleProfile.user_id).where(
                    SaleProfile.participation_device_hash == device_hash,
                    SaleProfile.user_id != user.id,
                    SaleProfile.status.not_in(("closed", "rejected")),
                )
            )
            if reused is not None:
                raise ApiError(
                    409, "SALE_DEVICE_ALREADY_USED", "Thiết bị đã được dùng cho một hồ sơ khác."
                )
            existing = SaleProfile(
                user_id=user.id,
                status="pending",
                terms_version=payload.terms_version.strip(),
                terms_accepted_at=now_utc(),
                participation_device_hash=device_hash,
                metadata_json={"accepted_from": "mobile"},
            )
            db.add(existing)
            user.sale_status = "pending"
        elif existing.status not in {"pending", "active", "suspended"}:
            raise ApiError(409, "SALE_PROFILE_CLOSED", "Hồ sơ cộng tác viên đã đóng.")
        elif existing.status == "pending":
            existing.terms_version = payload.terms_version.strip()
            existing.terms_accepted_at = now_utc()
            existing.participation_device_hash = device_hash
            existing.updated_at = now_utc()
        return get_sale_state(db, user)


def attach_referral(db: Session, user: User, payload: ReferralAttachRequest) -> dict[str, Any]:
    code_value = payload.referral_code.strip().upper()
    device_hash = payload.device_hash.strip().casefold()
    if not re.fullmatch(r"[a-f0-9]{32,128}", device_hash):
        raise ApiError(422, "INVALID_DEVICE_HASH", "Thiết bị chưa được xác thực.")
    with atomic(db):
        code = db.scalar(
            select(ReferralCode).where(ReferralCode.code == code_value).with_for_update()
        )
        if code is None or not code.is_active:
            raise ApiError(404, "REFERRAL_CODE_NOT_FOUND", "Mã giới thiệu không hợp lệ.")
        if code.user_id == user.id:
            raise ApiError(
                409, "REFERRAL_SELF_USE", "Bạn không thể tự dùng mã giới thiệu của mình."
            )
        existing = db.scalar(
            select(ReferralRelationship).where(ReferralRelationship.referred_id == user.id)
        )
        if existing:
            raise ApiError(409, "REFERRAL_ALREADY_ATTACHED", "Tài khoản đã có mã giới thiệu.")
        device_used = db.scalar(
            select(ReferralRelationship.id).where(
                ReferralRelationship.device_fingerprint_hash == device_hash
            )
        )
        if device_used:
            raise ApiError(409, "REFERRAL_DEVICE_REUSED", "Thiết bị này đã ghi nhận mã giới thiệu.")
        db.add(
            ReferralRelationship(
                referrer_id=code.user_id,
                referred_id=user.id,
                device_fingerprint_hash=device_hash,
            )
        )
        return {"success": True, "message": "Đã gắn mã giới thiệu."}


def get_payout_profile(db: Session, user: User) -> dict[str, Any] | None:
    _require_active_sale(db, user.id)
    profile = db.get(SalePayoutProfile, user.id)
    if profile is None:
        return None
    return _payout_to_dict(profile)


def upsert_payout_profile(
    db: Session, user: User, payload: SalePayoutProfileRequest
) -> dict[str, Any]:
    _require_active_sale(db, user.id)
    values = {
        "citizen_id": payload.citizen_id.strip(),
        "bank_bin": payload.bank_bin.strip(),
        "bank_name": payload.bank_name.strip(),
        "bank_account_number": payload.bank_account_number.strip(),
        "bank_account_name": payload.bank_account_name.strip().upper(),
    }
    if not values["citizen_id"].isalnum() or not values["bank_bin"].isalnum():
        raise ApiError(422, "SALE_PAYOUT_PROFILE_INVALID", "Thông tin nhận thanh toán chưa hợp lệ.")
    with atomic(db):
        profile = db.scalar(
            select(SalePayoutProfile)
            .where(SalePayoutProfile.sale_user_id == user.id)
            .with_for_update()
        )
        if profile is None:
            profile = SalePayoutProfile(sale_user_id=user.id, updated_by=user.id, metadata_json={})
            db.add(profile)
        for key, value in values.items():
            setattr(profile, key, value)
        profile.updated_by = user.id
        profile.updated_at = now_utc()
        return _payout_to_dict(profile)


def get_sale_dashboard(db: Session, user: User) -> dict[str, Any]:
    _require_active_sale(db, user.id)
    commissions = list(
        db.scalars(select(CommissionRecord).where(CommissionRecord.receiver_user_id == user.id))
    )
    adjustments = list(
        db.scalars(select(SalePointAdjustment).where(SalePointAdjustment.sale_user_id == user.id))
    )
    conversions = list(
        db.scalars(select(SalePointConversion).where(SalePointConversion.sale_user_id == user.id))
    )
    direct_customers = (
        db.scalar(
            select(func.count())
            .select_from(ReferralRelationship)
            .where(ReferralRelationship.referrer_id == user.id)
        )
        or 0
    )
    customer_ids = select(ReferralRelationship.referred_id).where(
        ReferralRelationship.referrer_id == user.id
    )
    successful_payments = (
        db.scalar(
            select(func.count())
            .select_from(PaymentEvent)
            .where(PaymentEvent.payer_user_id.in_(customer_ids), PaymentEvent.status == "succeeded")
        )
        or 0
    )
    pending = sum(
        c.amount_cents
        for c in commissions
        if c.status in {"pending", "approved"} and _future(c.available_at)
    )
    approved = sum(
        c.amount_cents
        for c in commissions
        if c.status in {"pending", "approved"} and not _future(c.available_at)
    )
    approved += sum(a.point_delta_cents for a in adjustments if a.status == "approved")
    paid = sum(c.amount_cents for c in commissions if c.status == "paid")
    converted = sum(
        c.requested_point_cents
        for c in conversions
        if c.status in {"approved", "paid", "completed"}
    )
    config = _active_config(db, "sale_point_conversion")
    enabled = config.get("enabled") is True
    rate = _decimal(config.get("point_to_money_rate"))
    minimum = _integer(config.get("minimum_point_cents"))
    currency = str(config.get("currency") or "VND")
    return {
        "direct_customers": int(direct_customers),
        "successful_payments": int(successful_payments),
        "pending_point_cents": pending,
        "approved_point_cents": approved,
        "paid_point_cents": paid,
        "converted_point_cents": converted,
        "available_point_cents": max(0, approved - converted),
        "currency": currency,
        "conversion_enabled": enabled and rate > 0 and minimum > 0,
        "conversion_rate": float(rate),
        "conversion_minimum_point_cents": minimum,
        "conversion_currency": currency,
    }


def get_sale_customers(db: Session, user: User) -> list[dict[str, Any]]:
    _require_active_sale(db, user.id)
    referrals = list(
        db.scalars(
            select(ReferralRelationship)
            .where(ReferralRelationship.referrer_id == user.id)
            .order_by(ReferralRelationship.created_at.desc())
        )
    )
    result = []
    for referral in referrals:
        customer = db.get(User, referral.referred_id)
        if customer is None:
            continue
        payments = (
            db.scalar(
                select(func.count())
                .select_from(PaymentEvent)
                .where(
                    PaymentEvent.payer_user_id == customer.id,
                    PaymentEvent.status == "succeeded",
                )
            )
            or 0
        )
        points = (
            db.scalar(
                select(func.coalesce(func.sum(CommissionRecord.amount_cents), 0)).where(
                    CommissionRecord.receiver_user_id == user.id,
                    CommissionRecord.payer_user_id == customer.id,
                    CommissionRecord.status.in_(("pending", "approved")),
                    CommissionRecord.available_at <= now_utc(),
                )
            )
            or 0
        )
        result.append(
            {
                "display_name": customer.full_name or "Người dùng NanoBio",
                "full_name": customer.full_name,
                "age": (date.today().year - customer.birth_year) if customer.birth_year else None,
                "phone": customer.phone,
                "accepted_at": _iso(referral.created_at),
                "successful_payments": int(payments),
                "approved_point_cents": int(points),
                "currency": "VND",
            }
        )
    return result


def get_sale_point_ledger(db: Session, user: User) -> list[dict[str, Any]]:
    _require_active_sale(db, user.id)
    commissions = list(
        db.scalars(select(CommissionRecord).where(CommissionRecord.receiver_user_id == user.id))
    )
    result: list[dict[str, Any]] = []
    for commission in commissions:
        payment = db.get(PaymentEvent, commission.payment_event_id)
        customer = db.get(User, commission.payer_user_id)
        result.append(
            {
                "id": str(commission.id),
                "customer_name": customer.full_name if customer else "Người dùng NanoBio",
                "plan_code": payment.plan_code if payment else "",
                "payment_amount_cents": payment.amount_cents if payment else 0,
                "point_amount_cents": commission.amount_cents,
                "currency": commission.currency,
                "status": commission.status,
                "created_at": _iso(commission.created_at),
            }
        )
    for adjustment in db.scalars(
        select(SalePointAdjustment).where(SalePointAdjustment.sale_user_id == user.id)
    ):
        result.append(
            {
                "id": str(adjustment.id),
                "customer_name": "Điều chỉnh Admin",
                "plan_code": "manual_adjustment",
                "payment_amount_cents": 0,
                "point_amount_cents": adjustment.point_delta_cents,
                "currency": adjustment.currency,
                "status": adjustment.status,
                "created_at": _iso(adjustment.created_at),
            }
        )
    return sorted(result, key=lambda row: row.get("created_at") or "", reverse=True)


def get_sale_conversions(db: Session, user: User) -> list[dict[str, Any]]:
    _require_active_sale(db, user.id)
    rows = db.scalars(
        select(SalePointConversion)
        .where(SalePointConversion.sale_user_id == user.id)
        .order_by(SalePointConversion.created_at.desc())
    )
    return [_conversion_to_dict(row) for row in rows]


def request_sale_conversion(
    db: Session, user: User, payload: SaleConversionRequest
) -> dict[str, Any]:
    _require_active_sale(db, user.id)
    profile = db.get(SalePayoutProfile, user.id)
    if not _payout_complete(profile):
        raise ApiError(
            409, "SALE_PAYOUT_PROFILE_REQUIRED", "Hãy hoàn tất thông tin nhận thanh toán trước."
        )
    config = _active_config(db, "sale_point_conversion")
    rate = _decimal(config.get("point_to_money_rate"))
    minimum = _integer(config.get("minimum_point_cents"))
    currency = str(config.get("currency") or "VND")
    if config.get("enabled") is not True or rate <= 0 or minimum <= 0:
        raise ApiError(409, "SALE_CONVERSION_DISABLED", "Chức năng quy đổi hiện chưa được mở.")
    if payload.requested_point_cents < minimum:
        raise ApiError(
            422, "SALE_CONVERSION_BELOW_MINIMUM", "Số điểm quy đổi thấp hơn mức tối thiểu."
        )
    key = payload.idempotency_key.strip()
    with atomic(db):
        existing = db.scalar(
            select(SalePointConversion)
            .where(
                SalePointConversion.sale_user_id == user.id,
                SalePointConversion.idempotency_key == key,
            )
            .with_for_update()
        )
        if existing:
            if existing.requested_point_cents != payload.requested_point_cents:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã yêu cầu đã được dùng cho nội dung khác."
                )
            return _conversion_to_dict(existing)
        dashboard = get_sale_dashboard(db, user)
        if dashboard["available_point_cents"] < payload.requested_point_cents:
            raise ApiError(409, "INSUFFICIENT_SALE_POINTS", "Số điểm khả dụng chưa đủ.")
        conversion = SalePointConversion(
            sale_user_id=user.id,
            requested_point_cents=payload.requested_point_cents,
            point_to_money_rate=rate,
            money_amount_cents=int(
                (Decimal(payload.requested_point_cents) * rate).quantize(Decimal("1"))
            ),
            currency=currency,
            status="requested",
            idempotency_key=key,
            metadata_json={},
        )
        db.add(conversion)
        db.flush()
        return _conversion_to_dict(conversion)


def get_wellness_reward_summary(db: Session, user: User) -> dict[str, Any]:
    now = now_utc()
    wallet = _get_or_create_wallet(db, user.id)
    expiring = list(
        db.scalars(
            select(WellnessPointAllocation).where(
                WellnessPointAllocation.user_id == user.id,
                WellnessPointAllocation.status == "available",
                WellnessPointAllocation.remaining_points > 0,
                WellnessPointAllocation.expires_at > now,
                WellnessPointAllocation.expires_at <= now + timedelta(days=30),
            )
        )
    )
    return {
        "pending_points": wallet.pending_points,
        "available_points": wallet.available_points,
        "expiring_soon_points": sum(row.remaining_points for row in expiring),
        "next_expiry_at": _iso(min((row.expires_at for row in expiring), default=None)),
        "synced_at": _iso(now),
        "program_enabled": True,
        "lifetime_earned_points": wallet.lifetime_earned_points,
        "lifetime_spent_points": wallet.lifetime_spent_points,
    }


def list_wellness_point_history(db: Session, user: User, limit: int) -> list[dict[str, Any]]:
    rows = list(
        db.scalars(
            select(WellnessPointLedger)
            .where(WellnessPointLedger.user_id == user.id)
            .order_by(WellnessPointLedger.created_at.desc(), WellnessPointLedger.id.desc())
            .limit(limit)
        )
    )
    return [
        {
            "id": str(row.id),
            "points_delta": row.points_delta,
            "event_type": row.event_type,
            "status": row.status,
            "title": row.title,
            "is_redeemable": row.is_redeemable,
            "available_at": _iso(row.available_at),
            "expires_at": _iso(row.expires_at),
            "created_at": _iso(row.created_at),
        }
        for row in rows
    ]


def list_wellness_offers(db: Session, user: User, limit: int) -> list[dict[str, Any]]:
    now = now_utc()
    plan = _current_plan(db, user.id, now)
    offers = list(
        db.scalars(
            select(WellnessRewardOffer)
            .where(
                WellnessRewardOffer.is_active.is_(True),
                or_(
                    WellnessRewardOffer.available_from.is_(None),
                    WellnessRewardOffer.available_from <= now,
                ),
                or_(
                    WellnessRewardOffer.available_until.is_(None),
                    WellnessRewardOffer.available_until > now,
                ),
            )
            .order_by(WellnessRewardOffer.cost_points, WellnessRewardOffer.created_at.desc())
            .limit(limit)
        )
    )
    result = []
    for offer in offers:
        available_codes = (
            db.scalar(
                select(func.count())
                .select_from(WellnessRewardCode)
                .where(
                    WellnessRewardCode.offer_id == offer.id,
                    WellnessRewardCode.status == "available",
                    or_(
                        WellnessRewardCode.voucher_expires_at.is_(None),
                        WellnessRewardCode.voucher_expires_at > now,
                    ),
                )
            )
            or 0
        )
        result.append(
            {
                "id": str(offer.id),
                "offer_id": str(offer.id),
                "offer_code": offer.offer_code,
                "title": offer.title,
                "description": offer.description,
                "provider_name": offer.provider_name,
                "cost_points": offer.cost_points,
                "available_codes": (
                    int(available_codes) if offer.reward_type == "voucher" else offer.stock_count
                ),
                "stock_count": offer.stock_count,
                "reward_type": offer.reward_type,
                "eligible_plan_codes": offer.eligible_plan_codes,
                "available_from": _iso(offer.available_from),
                "available_until": _iso(offer.available_until),
                "voucher_expires_at": _iso(offer.voucher_expires_at),
                "is_active": offer.is_active,
                "is_eligible": plan in (offer.eligible_plan_codes or []),
            }
        )
    return result


def list_wellness_redemptions(db: Session, user: User, limit: int) -> list[dict[str, Any]]:
    rows = db.scalars(
        select(WellnessRewardRedemption)
        .where(WellnessRewardRedemption.user_id == user.id)
        .order_by(WellnessRewardRedemption.created_at.desc())
        .limit(limit)
    )
    return [_redemption_to_dict(row) for row in rows]


def redeem_wellness_offer(
    db: Session, user: User, payload: WellnessRedemptionRequest
) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        existing = db.scalar(
            select(WellnessRewardRedemption)
            .where(
                WellnessRewardRedemption.user_id == user.id,
                WellnessRewardRedemption.idempotency_key == payload.idempotency_key,
            )
            .with_for_update()
        )
        if existing:
            if existing.offer_id != payload.offer_id:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã yêu cầu đã được dùng cho phần thưởng khác."
                )
            return _redemption_to_dict(existing, include_code=True, db=db)
        offer = db.scalar(
            select(WellnessRewardOffer)
            .where(WellnessRewardOffer.id == payload.offer_id)
            .with_for_update()
        )
        if (
            offer is None
            or not offer.is_active
            or (offer.available_from and offer.available_from > now)
            or (offer.available_until and offer.available_until <= now)
        ):
            raise ApiError(404, "OFFER_UNAVAILABLE", "Phần thưởng hiện không khả dụng.")
        if _current_plan(db, user.id, now) not in (offer.eligible_plan_codes or []):
            raise ApiError(403, "OFFER_INELIGIBLE", "Gói thành viên hiện tại chưa đủ điều kiện.")
        subject = db.scalar(
            select(HealthSubject).where(
                HealthSubject.owner_user_id == user.id,
                HealthSubject.subject_type == "self",
                HealthSubject.is_active.is_(True),
            )
        )
        if subject is None:
            raise ApiError(
                409, "HEALTH_SUBJECT_REQUIRED", "Chưa tìm thấy hồ sơ sức khỏe của tài khoản."
            )
        wallet = _get_or_create_wallet(db, user.id, lock=True)
        if wallet.available_points < offer.cost_points:
            raise ApiError(409, "INSUFFICIENT_POINTS", "Điểm khả dụng chưa đủ để đổi phần thưởng.")
        code: WellnessRewardCode | None = None
        if offer.reward_type == "voucher":
            code = db.scalar(
                select(WellnessRewardCode)
                .where(
                    WellnessRewardCode.offer_id == offer.id,
                    WellnessRewardCode.status == "available",
                    or_(
                        WellnessRewardCode.voucher_expires_at.is_(None),
                        WellnessRewardCode.voucher_expires_at > now,
                    ),
                )
                .order_by(WellnessRewardCode.voucher_expires_at, WellnessRewardCode.created_at)
                .with_for_update(skip_locked=True)
                .limit(1)
            )
            if code is None:
                raise ApiError(409, "OFFER_OUT_OF_STOCK", "Phần thưởng đã hết mã đổi.")
        elif offer.stock_count < 1:
            raise ApiError(409, "OFFER_OUT_OF_STOCK", "Phần thưởng đã hết số lượng.")
        expires = (code.voucher_expires_at or offer.voucher_expires_at) if code else None
        if offer.reward_type == "voucher" and expires is None:
            raise ApiError(
                409, "OFFER_EXPIRY_UNCONFIGURED", "Phần thưởng chưa được cấu hình hạn dùng."
            )
        redemption = WellnessRewardRedemption(
            user_id=user.id,
            offer_id=offer.id,
            reward_code_id=code.id if code else None,
            offer_title_snapshot=offer.title,
            provider_name_snapshot=offer.provider_name,
            points_spent=offer.cost_points,
            status="issued" if offer.reward_type == "voucher" else "redeemed",
            voucher_expires_at=expires,
            reward_type_snapshot=offer.reward_type,
            idempotency_key=payload.idempotency_key,
        )
        db.add(redemption)
        db.flush()
        left = offer.cost_points
        allocations = db.scalars(
            select(WellnessPointAllocation)
            .where(
                WellnessPointAllocation.user_id == user.id,
                WellnessPointAllocation.status == "available",
                WellnessPointAllocation.remaining_points > 0,
                WellnessPointAllocation.expires_at > now,
            )
            .order_by(
                WellnessPointAllocation.expires_at,
                WellnessPointAllocation.created_at,
                WellnessPointAllocation.id,
            )
            .with_for_update()
        )
        for allocation in allocations:
            if left <= 0:
                break
            used = min(left, allocation.remaining_points)
            allocation.remaining_points -= used
            if allocation.remaining_points == 0:
                allocation.status = "spent"
            db.add(
                WellnessRedemptionAllocationUsage(
                    redemption_id=redemption.id, allocation_id=allocation.id, points_used=used
                )
            )
            left -= used
        if left:
            raise ApiError(409, "WELLNESS_WALLET_INCONSISTENT", "Số dư điểm chưa thể đối soát.")
        if code:
            code.status = "issued"
            code.assigned_user_id = user.id
            code.assigned_redemption_id = redemption.id
            code.issued_at = now
        else:
            offer.stock_count -= 1
        wallet.available_points -= offer.cost_points
        wallet.lifetime_spent_points += offer.cost_points
        wallet.lock_version += 1
        wallet.updated_at = now
        ledger = WellnessPointLedger(
            user_id=user.id,
            subject_id=subject.id,
            source_type="reward_redemption",
            source_id=redemption.id,
            schedule_date=now.date(),
            points_delta=-offer.cost_points,
            program_code="wellness_rewards_v2",
            idempotency_key=f"redeem:{payload.idempotency_key}",
            event_type="reward_redemption",
            status="spent",
            title=f"Đổi phần thưởng: {offer.title}",
            is_redeemable=False,
            redemption_id=redemption.id,
            metadata_json={"offer_id": str(offer.id)},
        )
        db.add(ledger)
        return _redemption_to_dict(redemption, include_code=True, db=db)


def get_wellness_reward_code(db: Session, user: User, redemption_id: UUID) -> dict[str, Any]:
    redemption = db.scalar(
        select(WellnessRewardRedemption).where(
            WellnessRewardRedemption.id == redemption_id,
            WellnessRewardRedemption.user_id == user.id,
        )
    )
    if redemption is None:
        raise ApiError(404, "REWARD_NOT_FOUND", "Không tìm thấy phần thưởng.")
    code = db.get(WellnessRewardCode, redemption.reward_code_id)
    if code is None or redemption.status != "issued":
        raise ApiError(410, "REWARD_CODE_UNAVAILABLE", "Mã phần thưởng không còn khả dụng.")
    return {
        "voucher_code": code.code_value,
        "code": code.code_value,
        "expires_at": _iso(redemption.voucher_expires_at),
    }


def get_wellness_rank_summary(db: Session, user: User) -> dict[str, Any]:
    now = now_utc()
    account = db.get(WellnessRankAccount, user.id)
    points = account.experience_points if account else 0
    level, title, current, next_value = _rank(points)
    return {
        "rank_code": f"wellness_rank_{level}",
        "rank_level": level,
        "title": title,
        "experience_points": points,
        "current_rank_threshold": current,
        "next_rank_threshold": next_value,
        "experience_to_next_rank": max(0, next_value - points) if next_value else 0,
        "rank_progress_exp": max(0, points - current),
        "rank_progress_target": next_value - current if next_value else 0,
        "computed_at": _iso(now),
        "next_decay_at": _iso(account.next_decay_at) if account else None,
        "synced_at": _iso(now),
    }


def get_admin_dashboard(
    db: Session, from_value: str | None, to_value: str | None
) -> list[dict[str, Any]]:
    since = _parse_datetime(from_value) or now_utc() - timedelta(days=30)
    until = _parse_datetime(to_value) or now_utc()
    metrics = [
        ("users", "Tài khoản", db.scalar(select(func.count()).select_from(User)) or 0, "users"),
        (
            "active_memberships",
            "Thành viên đang hoạt động",
            db.scalar(
                select(func.count())
                .select_from(MembershipSubscription)
                .where(
                    MembershipSubscription.status == "active",
                    MembershipSubscription.starts_at <= until,
                    or_(
                        MembershipSubscription.ends_at.is_(None),
                        MembershipSubscription.ends_at > until,
                    ),
                )
            )
            or 0,
            "users",
        ),
        (
            "sale_profiles_pending",
            "Hồ sơ cộng tác viên chờ duyệt",
            db.scalar(
                select(func.count()).select_from(SaleProfile).where(SaleProfile.status == "pending")
            )
            or 0,
            "sales",
        ),
        (
            "payment_reviews",
            "Thanh toán chờ rà soát",
            db.scalar(
                select(func.count())
                .select_from(ManualPaymentEvent)
                .where(ManualPaymentEvent.status.in_(("pending_review", "pending")))
            )
            or 0,
            "payments",
        ),
        (
            "reward_redemptions",
            "Đổi thưởng trong kỳ",
            db.scalar(
                select(func.count())
                .select_from(WellnessRewardRedemption)
                .where(
                    WellnessRewardRedemption.created_at >= since,
                    WellnessRewardRedemption.created_at <= until,
                )
            )
            or 0,
            "wellness-rewards",
        ),
    ]
    return [
        {
            "metric_key": key,
            "label": label,
            "metric_value": int(value),
            "status": "ready",
            "target_section": target,
        }
        for key, label, value, target in metrics
    ]


def admin_list_business_items(
    db: Session, section: str, term: str, limit: int
) -> list[dict[str, Any]]:
    q = term.strip()
    if section == "sales":
        sales_stmt = select(SaleProfile, User).join(User, User.id == SaleProfile.user_id)
        if q:
            sales_stmt = sales_stmt.where(
                or_(
                    User.phone.ilike(f"%{q}%"),
                    User.full_name.ilike(f"%{q}%"),
                    User.email.ilike(f"%{q}%"),
                )
            )
        rows = db.execute(sales_stmt.order_by(SaleProfile.created_at.desc()).limit(limit))
        return [
            {
                "id": str(profile.user_id),
                "title": user.full_name,
                "subtitle": user.phone or user.email or "",
                "status": profile.status,
                "metadata": {
                    "sale_user_id": str(profile.user_id),
                    "terms_version": profile.terms_version,
                    "created_at": _iso(profile.created_at),
                },
            }
            for profile, user in rows
        ]
    if section == "sale-conversions":
        conversion_stmt = (
            select(SalePointConversion, SalePayoutProfile, User)
            .join(User, User.id == SalePointConversion.sale_user_id)
            .outerjoin(
                SalePayoutProfile,
                SalePayoutProfile.sale_user_id == SalePointConversion.sale_user_id,
            )
        )
        if q:
            conversion_stmt = conversion_stmt.where(
                or_(User.phone.ilike(f"%{q}%"), User.full_name.ilike(f"%{q}%"))
            )
        return [
            {
                "id": str(row.id),
                "title": customer.full_name,
                "subtitle": customer.phone or "",
                "status": row.status,
                "metadata": {
                    "sale_user_id": str(row.sale_user_id),
                    "requested_point_cents": row.requested_point_cents,
                    "money_amount_cents": row.money_amount_cents,
                    "currency": row.currency,
                    "bank_name": payout.bank_name if payout else None,
                    "bank_account_number": payout.bank_account_number if payout else None,
                    "payment_proof_path": row.metadata_json.get("payment_proof_path"),
                },
            }
            for row, payout, customer in db.execute(
                conversion_stmt.order_by(SalePointConversion.created_at.desc()).limit(limit)
            )
        ]
    if section == "wellness-rewards":
        offer_stmt = select(WellnessRewardOffer)
        if q:
            offer_stmt = offer_stmt.where(
                or_(
                    WellnessRewardOffer.title.ilike(f"%{q}%"),
                    WellnessRewardOffer.offer_code.ilike(f"%{q}%"),
                )
            )
        offers = db.scalars(offer_stmt.order_by(WellnessRewardOffer.created_at.desc()).limit(limit))
        result = [
            {
                "item_type": "offer",
                "id": str(row.id),
                "offer_id": str(row.id),
                "title": row.title,
                "description": row.description,
                "provider_name": row.provider_name,
                "cost_points": row.cost_points,
                "reward_type": row.reward_type,
                "stock_count": row.stock_count,
                "eligible_plan_codes": row.eligible_plan_codes,
                "available_from": _iso(row.available_from),
                "available_until": _iso(row.available_until),
                "voucher_expires_at": _iso(row.voucher_expires_at),
                "is_active": row.is_active,
                "available_codes": db.scalar(
                    select(func.count())
                    .select_from(WellnessRewardCode)
                    .where(
                        WellnessRewardCode.offer_id == row.id,
                        WellnessRewardCode.status == "available",
                    )
                )
                or 0,
                "issued_codes": db.scalar(
                    select(func.count())
                    .select_from(WellnessRewardCode)
                    .where(
                        WellnessRewardCode.offer_id == row.id,
                        WellnessRewardCode.status == "issued",
                    )
                )
                or 0,
                "subtitle": f"{row.provider_name} · {row.cost_points} điểm",
                "status": "active" if row.is_active else "inactive",
                "metadata": {
                    "kind": "offer",
                    "offer_code": row.offer_code,
                    "reward_type": row.reward_type,
                    "stock_count": row.stock_count,
                    "cost_points": row.cost_points,
                    "available_codes": db.scalar(
                        select(func.count())
                        .select_from(WellnessRewardCode)
                        .where(
                            WellnessRewardCode.offer_id == row.id,
                            WellnessRewardCode.status == "available",
                        )
                    )
                    or 0,
                },
            }
            for row in offers
        ]
        redemptions = db.scalars(
            select(WellnessRewardRedemption)
            .order_by(WellnessRewardRedemption.created_at.desc())
            .limit(limit)
        )
        result.extend(
            {
                "item_type": "redemption",
                "id": str(row.id),
                "redemption_id": str(row.id),
                "offer_id": str(row.offer_id),
                "reward_type": row.reward_type_snapshot,
                "title": row.offer_title_snapshot,
                "provider_name": row.provider_name_snapshot,
                "points_spent": row.points_spent,
                "user_label": _admin_user_label(db, row.user_id),
                "status": row.status,
                "masked_code": "••••••" if row.reward_type_snapshot == "voucher" else None,
                "created_at": _iso(row.created_at),
                "cancelled_at": _iso(row.cancelled_at),
                "received_at": _iso(row.received_at),
                "subtitle": f"{row.provider_name_snapshot} · {row.points_spent} điểm",
                "metadata": {
                    "kind": "redemption",
                    "user_id": str(row.user_id),
                    "offer_id": str(row.offer_id),
                    "reward_type": row.reward_type_snapshot,
                    "points_spent": row.points_spent,
                    "voucher_expires_at": _iso(row.voucher_expires_at),
                },
            }
            for row in redemptions
        )
        return result[:limit]
    if section == "reconciliation":
        discrepancy_stmt = select(AdminReconciliationDiscrepancy)
        if q:
            discrepancy_stmt = discrepancy_stmt.where(
                or_(
                    AdminReconciliationDiscrepancy.summary.ilike(f"%{q}%"),
                    AdminReconciliationDiscrepancy.target_id.ilike(f"%{q}%"),
                )
            )
        return [
            {
                "id": str(row.id),
                "title": row.summary,
                "subtitle": f"{row.target_type} · {row.target_id}",
                "status": row.status,
                "metadata": {
                    "severity": row.severity,
                    "run_id": str(row.run_id) if row.run_id else None,
                },
            }
            for row in db.scalars(
                discrepancy_stmt.order_by(AdminReconciliationDiscrepancy.created_at.desc()).limit(
                    limit
                )
            )
        ]
    if section in {"plans", "config"}:
        config_stmt = select(SystemConfigVersion)
        if q:
            config_stmt = config_stmt.where(
                or_(
                    SystemConfigVersion.config_key.ilike(f"%{q}%"),
                    SystemConfigVersion.reason.ilike(f"%{q}%"),
                )
            )
        return [
            {
                "id": str(row.id),
                "title": row.config_key,
                "subtitle": row.reason,
                "status": row.status,
                "metadata": {
                    "config_key": row.config_key,
                    "config_value": row.config_value,
                    "version": row.version,
                    "activated_at": _iso(row.activated_at),
                },
            }
            for row in db.scalars(
                config_stmt.order_by(SystemConfigVersion.created_at.desc()).limit(limit)
            )
        ]
    if section in {"reports", "report-exports"}:
        report_stmt = select(ReportExport)
        if q:
            report_stmt = report_stmt.where(
                or_(ReportExport.report_type.ilike(f"%{q}%"), ReportExport.reason.ilike(f"%{q}%"))
            )
        return [
            {
                "id": str(row.id),
                "title": row.report_type,
                "subtitle": row.reason,
                "status": row.status,
                "metadata": {"filters": row.filters, "created_at": _iso(row.created_at)},
            }
            for row in db.scalars(report_stmt.order_by(ReportExport.created_at.desc()).limit(limit))
        ]
    raise ApiError(404, "ADMIN_SECTION_NOT_FOUND", "Khu vực quản trị chưa được hỗ trợ.")


def admin_mutate_business_item(
    db: Session, actor: User, section: str, payload: BusinessAdminMutation
) -> dict[str, Any]:
    role_scope = {
        "sales": {"super_admin", "operations_admin"},
        "sale-conversions": {"super_admin", "finance_admin"},
        "wellness-rewards": {"super_admin", "content_admin"},
        "reconciliation": {"super_admin", "finance_admin", "operations_admin"},
        "plans": {"super_admin", "operations_admin"},
        "config": {"super_admin", "operations_admin"},
        "reports": {"super_admin", "operations_admin"},
        "report-exports": {"super_admin", "operations_admin"},
    }
    if not (actor.admin_roles & role_scope.get(section, {"super_admin"})):
        raise ApiError(403, "ADMIN_PERMISSION_DENIED", "Bạn không có quyền cho thao tác này.")
    operation = f"business:{section}:{payload.action}"
    body = payload.model_dump(mode="json")
    digest = payload_hash(body)
    with atomic(db):
        prior = find_idempotency(
            db, actor_id=actor.id, operation=operation, key=payload.idempotency_key
        )
        if prior:
            if prior.request_hash != digest:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã thao tác đã được dùng cho yêu cầu khác."
                )
            return prior.response_data or {"idempotent_replay": True}
        result: dict[str, Any]
        target_user_id: UUID | None = None
        if section == "sales":
            user_id = _uuid(payload.target_id)
            profile = db.scalar(
                select(SaleProfile).where(SaleProfile.user_id == user_id).with_for_update()
            )
            if profile is None:
                raise ApiError(404, "SALE_PROFILE_NOT_FOUND", "Không tìm thấy hồ sơ cộng tác viên.")
            status_map = {
                "approve": "active",
                "reject": "rejected",
                "suspend": "suspended",
                "close": "closed",
            }
            if payload.action not in status_map:
                raise ApiError(422, "INVALID_SALE_DECISION", "Thao tác hồ sơ chưa hợp lệ.")
            profile.status = status_map[payload.action]
            profile.note = payload.reason
            profile.approved_at = now_utc() if payload.action == "approve" else profile.approved_at
            profile.updated_at = now_utc()
            member = db.get(User, user_id)
            if member:
                member.sale_status = profile.status
            if (
                payload.action == "approve"
                and db.scalar(select(ReferralCode).where(ReferralCode.user_id == user_id)) is None
            ):
                db.add(ReferralCode(code=uuid4().hex[:10].upper(), user_id=user_id, is_active=True))
            target_user_id = user_id
            result = {"id": str(user_id), "status": profile.status}
        elif section == "sale-conversions":
            if payload.action == "adjust_points":
                user_id = _uuid(payload.target_id)
                delta = _integer(payload.payload.get("point_delta_cents"))
                if delta == 0:
                    raise ApiError(
                        422, "INVALID_POINT_ADJUSTMENT", "Số điểm điều chỉnh không hợp lệ."
                    )
                adjustment = SalePointAdjustment(
                    sale_user_id=user_id,
                    point_delta_cents=delta,
                    status="approved",
                    reason=payload.reason,
                    reviewed_by=actor.id,
                    idempotency_key=payload.idempotency_key,
                    metadata_json={},
                )
                db.add(adjustment)
                target_user_id = user_id
                result = {"id": str(adjustment.id), "status": adjustment.status}
            else:
                conversion_id = _uuid(payload.target_id)
                conversion = db.scalar(
                    select(SalePointConversion)
                    .where(SalePointConversion.id == conversion_id)
                    .with_for_update()
                )
                if conversion is None:
                    raise ApiError(
                        404, "SALE_CONVERSION_NOT_FOUND", "Không tìm thấy yêu cầu quy đổi."
                    )
                status_map = {
                    "approve": "approved",
                    "reject": "rejected",
                    "paid": "paid",
                    "cancel": "cancelled",
                }
                if payload.action not in status_map:
                    raise ApiError(
                        422, "INVALID_CONVERSION_DECISION", "Thao tác quy đổi chưa hợp lệ."
                    )
                conversion.status = status_map[payload.action]
                conversion.reviewed_by = actor.id
                conversion.reviewed_at = now_utc()
                conversion.review_reason = payload.reason
                proof_path = payload.payload.get("payment_proof_path")
                if isinstance(proof_path, str) and proof_path:
                    conversion.metadata_json = {
                        **conversion.metadata_json,
                        "payment_proof_path": proof_path,
                    }
                if payload.action == "paid":
                    conversion.paid_at = now_utc()
                target_user_id = conversion.sale_user_id
                result = {"id": str(conversion.id), "status": conversion.status}
        elif section == "wellness-rewards":
            if payload.action == "upsert_offer":
                offer_id = _uuid(payload.target_id) if payload.target_id else uuid4()
                offer = db.scalar(
                    select(WellnessRewardOffer)
                    .where(WellnessRewardOffer.id == offer_id)
                    .with_for_update()
                )
                data = payload.payload
                if offer is None:
                    offer = WellnessRewardOffer(
                        id=offer_id,
                        offer_code=_clean_text(
                            data.get("offer_code") or f"reward_{offer_id.hex}", 80
                        ),
                        title=_clean_text(data.get("title"), 200),
                        description=_clean_text(data.get("description"), 2000),
                        provider_name=_clean_text(data.get("provider_name"), 160),
                        cost_points=_integer(data.get("cost_points")),
                        reward_type=(
                            "physical" if data.get("reward_type") == "physical" else "voucher"
                        ),
                        stock_count=max(0, _integer(data.get("stock_count"))),
                        eligible_plan_codes=_string_list(data.get("eligible_plan_codes")),
                        is_active=data.get("is_active") is not False,
                        created_by=actor.id,
                        updated_by=actor.id,
                        metadata_json={},
                    )
                    db.add(offer)
                else:
                    reward_type = data.get("reward_type")
                    if reward_type in {"voucher", "physical"} and reward_type != offer.reward_type:
                        raise ApiError(
                            409,
                            "REWARD_TYPE_IMMUTABLE",
                            "Loại phần thưởng không thể thay đổi sau khi tạo.",
                        )
                    offer.title = _clean_text(data.get("title", offer.title), 200)
                    offer.description = _clean_text(
                        data.get("description", offer.description), 2000
                    )
                    offer.provider_name = _clean_text(
                        data.get("provider_name", offer.provider_name), 160
                    )
                    offer.cost_points = _integer(data.get("cost_points", offer.cost_points))
                    offer.stock_count = max(0, _integer(data.get("stock_count", offer.stock_count)))
                    offer.eligible_plan_codes = _string_list(
                        data.get("eligible_plan_codes", offer.eligible_plan_codes)
                    )
                    offer.is_active = data.get("is_active") is not False
                    offer.updated_by = actor.id
                    offer.updated_at = now_utc()
                if offer.cost_points <= 0:
                    raise ApiError(422, "INVALID_OFFER_COST", "Số điểm đổi phải lớn hơn 0.")
                available_from = (
                    _parse_datetime(str(data.get("available_from")))
                    if data.get("available_from")
                    else None
                )
                available_until = (
                    _parse_datetime(str(data.get("available_until")))
                    if data.get("available_until")
                    else None
                )
                if available_from and available_until and available_until <= available_from:
                    raise ApiError(422, "INVALID_OFFER_WINDOW", "Thời gian ưu đãi chưa hợp lệ.")
                if data.get("available_from"):
                    offer.available_from = available_from
                if data.get("available_until"):
                    offer.available_until = available_until
                if data.get("voucher_expires_at"):
                    offer.voucher_expires_at = _parse_datetime(str(data.get("voucher_expires_at")))
                offer.updated_at = now_utc()
                target_user_id = None
                result = {
                    "id": str(offer.id),
                    "status": "active" if offer.is_active else "inactive",
                }
            elif payload.action == "import_codes":
                offer = db.get(WellnessRewardOffer, _uuid(payload.target_id))
                if offer is None or offer.reward_type != "voucher":
                    raise ApiError(404, "OFFER_NOT_FOUND", "Không tìm thấy ưu đãi voucher.")
                raw_codes = payload.payload.get("codes")
                codes = (
                    [str(value).strip() for value in raw_codes if str(value).strip()]
                    if isinstance(raw_codes, list)
                    else []
                )
                if not 1 <= len(codes) <= 500 or len(codes) != len(set(codes)):
                    raise ApiError(
                        422,
                        "INVALID_REWARD_CODES",
                        "Danh sách mã voucher bị trùng hoặc không hợp lệ.",
                    )
                expiry = (
                    _parse_datetime(str(payload.payload.get("voucher_expires_at")))
                    if payload.payload.get("voucher_expires_at")
                    else offer.voucher_expires_at
                )
                if expiry is None or expiry <= now_utc():
                    raise ApiError(
                        422,
                        "INVALID_VOUCHER_EXPIRY",
                        "Voucher cần có hạn dùng trong tương lai.",
                    )
                code_hashes = [hashlib.sha256(code.encode()).hexdigest() for code in codes]
                existing_hashes = set(
                    db.scalars(
                        select(WellnessRewardCode.code_hash).where(
                            WellnessRewardCode.code_hash.in_(code_hashes)
                        )
                    )
                )
                accepted = 0
                duplicates = 0
                for code_value, digest_code in zip(codes, code_hashes, strict=True):
                    if digest_code in existing_hashes:
                        duplicates += 1
                        continue
                    existing_hashes.add(digest_code)
                    db.add(
                        WellnessRewardCode(
                            offer_id=offer.id,
                            code_value=code_value,
                            code_hash=digest_code,
                            status="available",
                            voucher_expires_at=expiry,
                            imported_by=actor.id,
                            import_batch_key=payload.idempotency_key,
                        )
                    )
                    accepted += 1
                target_user_id = None
                result = {
                    "success": True,
                    "message": "Đã nhập kho mã voucher.",
                    "accepted_count": accepted,
                    "duplicate_count": duplicates,
                    "rejected_count": 0,
                }
            elif payload.action in {"cancel", "mark_received"}:
                redemption = db.scalar(
                    select(WellnessRewardRedemption)
                    .where(WellnessRewardRedemption.id == _uuid(payload.target_id))
                    .with_for_update()
                )
                if redemption is None:
                    raise ApiError(404, "REDEMPTION_NOT_FOUND", "Không tìm thấy lượt đổi thưởng.")
                if payload.action == "cancel":
                    if payload.payload.get("external_revocation_confirmed") is not True:
                        raise ApiError(
                            422,
                            "REVOCATION_CONFIRMATION_REQUIRED",
                            "Cần xác nhận mã đã được thu hồi bên nhà cung cấp.",
                        )
                    if redemption.status != "issued":
                        raise ApiError(
                            409,
                            "REWARD_CANNOT_BE_UNDONE",
                            "Giao dịch này không còn đủ điều kiện để hủy.",
                        )
                    redemption.status = "cancelled"
                    redemption.cancelled_at = now_utc()
                    redemption.cancelled_by = actor.id
                    redemption.cancellation_reason = payload.reason
                    code = db.get(WellnessRewardCode, redemption.reward_code_id)
                    if code:
                        code.status = "retired"
                        code.retired_at = now_utc()
                    now = now_utc()
                    usages = db.execute(
                        select(WellnessRedemptionAllocationUsage, WellnessPointAllocation)
                        .join(
                            WellnessPointAllocation,
                            WellnessPointAllocation.id
                            == WellnessRedemptionAllocationUsage.allocation_id,
                        )
                        .where(WellnessRedemptionAllocationUsage.redemption_id == redemption.id)
                        .with_for_update()
                    ).all()
                    refundable = 0
                    for usage, allocation in usages:
                        if allocation.expires_at > now:
                            allocation.remaining_points += usage.points_used
                            allocation.status = "available"
                            allocation.updated_at = now
                            refundable += usage.points_used
                    wallet = _get_or_create_wallet(db, redemption.user_id, lock=True)
                    if refundable:
                        subject = db.scalar(
                            select(HealthSubject).where(
                                HealthSubject.owner_user_id == redemption.user_id,
                                HealthSubject.subject_type == "self",
                                HealthSubject.is_active.is_(True),
                            )
                        )
                        if subject is None:
                            raise ApiError(
                                409,
                                "HEALTH_SUBJECT_REQUIRED",
                                "Chưa tìm thấy hồ sơ sức khỏe của tài khoản.",
                            )
                        wallet.available_points += refundable
                        wallet.lifetime_refunded_points += refundable
                        db.add(
                            WellnessPointLedger(
                                user_id=redemption.user_id,
                                subject_id=subject.id,
                                source_type="reward_refund",
                                source_id=redemption.id,
                                schedule_date=now.date(),
                                points_delta=refundable,
                                program_code="wellness_rewards_v2",
                                idempotency_key=f"refund:{payload.idempotency_key}",
                                event_type="reward_refund",
                                status="available",
                                title=f"Hoàn điểm: {redemption.offer_title_snapshot}",
                                is_redeemable=True,
                                available_at=now,
                                redemption_id=redemption.id,
                                metadata_json={"reason": payload.reason},
                            )
                        )
                    wallet.lock_version += 1
                    wallet.updated_at = now_utc()
                    result = {
                        "id": str(redemption.id),
                        "status": "cancelled",
                        "success": True,
                        "message": "Đã hủy giao dịch và hoàn điểm còn hạn.",
                    }
                else:
                    if redemption.reward_type_snapshot != "physical":
                        raise ApiError(
                            409,
                            "PHYSICAL_REWARD_REQUIRED",
                            "Chỉ có thể xác nhận đã nhận quà vật lý.",
                        )
                    if redemption.status != "redeemed":
                        raise ApiError(
                            409,
                            "REWARD_CANNOT_BE_RECEIVED",
                            "Giao dịch chưa đủ điều kiện xác nhận đã nhận.",
                        )
                    redemption.status = "received"
                    redemption.received_at = now_utc()
                    redemption.received_by = actor.id
                    redemption.updated_at = now_utc()
                    result = {
                        "id": str(redemption.id),
                        "status": "received",
                        "success": True,
                        "message": "Đã xác nhận khách hàng nhận quà.",
                    }
                target_user_id = redemption.user_id
            else:
                raise ApiError(422, "INVALID_REWARD_ACTION", "Thao tác phần thưởng chưa hợp lệ.")
        elif section == "reconciliation":
            if payload.action == "create_run":
                run = db.scalar(
                    select(AdminReconciliationRun)
                    .where(AdminReconciliationRun.idempotency_key == payload.idempotency_key)
                    .with_for_update()
                )
                if run is None:
                    run = AdminReconciliationRun(
                        scope=payload.target_id or "payments",
                        status="open",
                        reason=payload.reason,
                        created_by=actor.id,
                        idempotency_key=payload.idempotency_key,
                        metadata_json={},
                    )
                    db.add(run)
                    db.flush()
                    pending = (
                        db.scalar(
                            select(func.count())
                            .select_from(ManualPaymentEvent)
                            .where(ManualPaymentEvent.status.in_(("pending_review", "pending")))
                        )
                        or 0
                    )
                    if pending:
                        db.add(
                            AdminReconciliationDiscrepancy(
                                run_id=run.id,
                                target_type="membership_payment",
                                target_id="pending-payment-queue",
                                severity="medium",
                                status="open",
                                summary=f"Có {pending} giao dịch cần đối soát.",
                                metadata_json={},
                            )
                        )
                result = {"id": str(run.id), "status": run.status}
            else:
                discrepancy = db.get(AdminReconciliationDiscrepancy, _uuid(payload.target_id))
                if discrepancy is None:
                    raise ApiError(
                        404, "DISCREPANCY_NOT_FOUND", "Không tìm thấy sai lệch đối soát."
                    )
                if payload.action not in {"resolved", "needs_follow_up", "adjusted", "dismissed"}:
                    raise ApiError(
                        422, "INVALID_RECONCILIATION_STATUS", "Trạng thái đối soát chưa hợp lệ."
                    )
                discrepancy.status = payload.action
                discrepancy.reviewed_by = actor.id
                discrepancy.reviewed_at = now_utc()
                discrepancy.review_reason = payload.reason
                result = {"id": str(discrepancy.id), "status": discrepancy.status}
        elif section in {"plans", "config"}:
            key = payload.target_id.strip()
            if not key:
                raise ApiError(422, "CONFIG_KEY_REQUIRED", "Thiếu khóa cấu hình.")
            value = payload.payload.get("config_value", {})
            if not isinstance(value, dict):
                raise ApiError(422, "INVALID_CONFIG_VALUE", "Giá trị cấu hình phải là object.")
            current_version = (
                db.scalar(
                    select(func.max(SystemConfigVersion.version)).where(
                        SystemConfigVersion.config_key == key
                    )
                )
                or 0
            )
            db.query(SystemConfigVersion).filter(
                SystemConfigVersion.config_key == key, SystemConfigVersion.status == "active"
            ).update({SystemConfigVersion.status: "superseded"}, synchronize_session=False)
            version = SystemConfigVersion(
                config_key=key,
                config_value=value,
                version=int(current_version) + 1,
                status="active",
                reason=payload.reason,
                created_by=actor.id,
                activated_at=now_utc(),
            )
            db.add(version)
            result = {"id": str(version.id), "status": version.status, "version": version.version}
        elif section in {"reports", "report-exports"}:
            report_type = payload.target_id.strip()
            if not report_type:
                raise ApiError(422, "REPORT_TYPE_REQUIRED", "Thiếu loại báo cáo.")
            filters = payload.payload.get("filters", {})
            if not isinstance(filters, dict):
                raise ApiError(422, "INVALID_REPORT_FILTERS", "Bộ lọc báo cáo chưa hợp lệ.")
            export = ReportExport(
                report_type=report_type,
                filters=filters,
                status="requested",
                reason=payload.reason,
                requested_by=actor.id,
            )
            db.add(export)
            result = {"id": str(export.id), "status": export.status}
        else:
            raise ApiError(404, "ADMIN_SECTION_NOT_FOUND", "Khu vực quản trị chưa được hỗ trợ.")
        add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=target_user_id,
            reason=payload.reason,
            idempotency_key=payload.idempotency_key,
            metadata={"target_id": payload.target_id, "action": payload.action},
        )
        add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=payload.idempotency_key,
            digest=digest,
            result=result,
        )
        return result


def _require_active_sale(db: Session, user_id: UUID) -> SaleProfile:
    profile = db.get(SaleProfile, user_id)
    if profile is None or profile.status != "active":
        raise ApiError(403, "SALE_ACCESS_REQUIRED", "Quyền cộng tác viên chưa hoạt động.")
    return profile


def _get_or_create_wallet(
    db: Session, user_id: UUID, *, lock: bool = False
) -> WellnessRewardWallet:
    stmt = select(WellnessRewardWallet).where(WellnessRewardWallet.user_id == user_id)
    if lock:
        stmt = stmt.with_for_update()
    wallet = db.scalar(stmt)
    if wallet is None:
        wallet = WellnessRewardWallet(user_id=user_id)
        db.add(wallet)
        db.flush()
    return wallet


def _current_plan(db: Session, user_id: UUID, now: datetime) -> str:
    subscription = db.scalar(
        select(MembershipSubscription)
        .where(
            MembershipSubscription.user_id == user_id,
            MembershipSubscription.status == "active",
            MembershipSubscription.starts_at <= now,
            or_(MembershipSubscription.ends_at.is_(None), MembershipSubscription.ends_at > now),
        )
        .order_by(
            MembershipSubscription.ends_at.desc().nullsfirst(),
            MembershipSubscription.created_at.desc(),
        )
        .limit(1)
    )
    plan = subscription.plan_code.casefold() if subscription else "free"
    return plan if plan in {"free", "plus", "family_plus"} else "free"


def _active_config(db: Session, key: str) -> dict[str, Any]:
    row = db.scalar(
        select(SystemConfigVersion)
        .where(SystemConfigVersion.config_key == key, SystemConfigVersion.status == "active")
        .order_by(SystemConfigVersion.created_at.desc())
        .limit(1)
    )
    return row.config_value if row and isinstance(row.config_value, dict) else {}


def _payout_complete(profile: SalePayoutProfile | None) -> bool:
    return bool(
        profile
        and all(
            (
                profile.citizen_id,
                profile.bank_bin,
                profile.bank_name,
                profile.bank_account_number,
                profile.bank_account_name,
            )
        )
    )


def _payout_to_dict(profile: SalePayoutProfile) -> dict[str, Any]:
    return {
        "citizen_id": profile.citizen_id,
        "bank_bin": profile.bank_bin,
        "bank_name": profile.bank_name,
        "bank_account_number": profile.bank_account_number,
        "bank_account_name": profile.bank_account_name,
        "updated_at": _iso(profile.updated_at),
    }


def _conversion_to_dict(row: SalePointConversion) -> dict[str, Any]:
    return {
        "id": str(row.id),
        "requested_point_cents": row.requested_point_cents,
        "money_amount_cents": row.money_amount_cents,
        "currency": row.currency,
        "status": row.status,
        "requested_at": _iso(row.requested_at),
        "reviewed_at": _iso(row.reviewed_at),
        "note": row.review_reason,
    }


def _redemption_to_dict(
    row: WellnessRewardRedemption, *, include_code: bool = False, db: Session | None = None
) -> dict[str, Any]:
    code = (
        db.get(WellnessRewardCode, row.reward_code_id)
        if include_code and db and row.reward_code_id
        else None
    )
    return {
        "id": str(row.id),
        "redemption_id": str(row.id),
        "offer_id": str(row.offer_id),
        "title": row.offer_title_snapshot,
        "provider_name": row.provider_name_snapshot,
        "points_spent": row.points_spent,
        "status": row.status,
        "reward_type": row.reward_type_snapshot,
        "voucher_code": code.code_value if code and row.status == "issued" else None,
        "voucher_expires_at": _iso(row.voucher_expires_at),
        "created_at": _iso(row.created_at),
        "cancelled_at": _iso(row.cancelled_at),
    }


def _rank(points: int) -> tuple[int, str, int, int | None]:
    if points >= 5200:
        return 5, "Tinh Tú Hộ Mệnh", 5200, None
    if points >= 2600:
        return 4, "Hộ Vệ Sức Sống", 2600, 5200
    if points >= 1200:
        return 3, "Người Gìn Giữ Nhịp Sống", 1200, 2600
    if points >= 600:
        return 2, "Người Ươm Nếp Lành", 600, 1200
    return 1, "Mầm An Nhiên", 0, 600


def _admin_user_label(db: Session, user_id: UUID) -> str:
    user = db.get(User, user_id)
    if user is None:
        return "Tài khoản NanoBio"
    name = (user.full_name or "").strip()
    if name:
        return name
    email = (user.email or "").strip()
    if "@" in email:
        local, domain = email.split("@", 1)
        return f"{local[:1]}***@{domain}"
    return "Tài khoản NanoBio"


def _uuid(value: object) -> UUID:
    try:
        return UUID(str(value))
    except (ValueError, TypeError, AttributeError) as exc:
        raise ApiError(422, "INVALID_IDENTIFIER", "Mã bản ghi chưa hợp lệ.") from exc


def _integer(value: object) -> int:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        try:
            return int(value)
        except ValueError:
            return 0
    return 0


def _decimal(value: object) -> Decimal:
    try:
        result = Decimal(str(value))
        return result if result.is_finite() else Decimal(0)
    except (InvalidOperation, ValueError, TypeError):
        return Decimal(0)


def _clean_text(value: object, max_length: int) -> str:
    text = str(value or "").strip()
    if not text or len(text) > max_length:
        raise ApiError(422, "INVALID_TEXT", "Thông tin nhập chưa hợp lệ.")
    return text


def _string_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    result = [str(item).strip() for item in value if str(item).strip()]
    return list(dict.fromkeys(result))[:20]


def _iso(value: datetime | date | None) -> str | None:
    return value.isoformat() if value is not None else None


def _future(value: datetime) -> bool:
    current = value if value.tzinfo else value.replace(tzinfo=UTC)
    return current > now_utc()


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=UTC)
