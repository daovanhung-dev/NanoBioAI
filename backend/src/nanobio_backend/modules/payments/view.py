import calendar
import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import (
    AdminAuditEvent,
    GooglePlayPurchase,
    ManualPaymentEvent,
    MembershipSubscription,
    User,
    now_utc,
)
from nanobio_backend.modules.payments import query
from nanobio_backend.modules.payments.validate import parse_payment_configuration
from nanobio_backend.services.google_play import PRODUCT_PLANS, parse_provider_time, purchase_state


def finalize_google_play_purchase(
    db: Session,
    *,
    user: User,
    package_name: str,
    product_id: str,
    purchase_token: str,
    snapshot: dict[str, str | None],
) -> dict[str, str | None]:
    purchase_token_hash = hashlib.sha256(purchase_token.encode()).hexdigest()
    state = purchase_state(snapshot["subscription_state"] or "")
    if snapshot["product_id"] != product_id:
        raise ApiError(409, "PRODUCT_MISMATCH", "Gói đăng ký không khớp với giao dịch.")
    starts_at = parse_provider_time(snapshot["start_time"])
    ends_at = parse_provider_time(snapshot["expiry_time"])
    with atomic(db):
        purchase = db.scalar(
            select(GooglePlayPurchase)
            .where(GooglePlayPurchase.purchase_token_hash == purchase_token_hash)
            .with_for_update()
        )
        if purchase is not None and purchase.user_id != user.id:
            raise ApiError(
                403, "PURCHASE_OWNERSHIP_MISMATCH", "Giao dịch không thuộc tài khoản này."
            )
        if purchase is None:
            purchase = GooglePlayPurchase(
                user_id=user.id,
                purchase_token_hash=purchase_token_hash,
                package_name=package_name,
                product_id=product_id,
                purchase_state=state,
            )
            db.add(purchase)
        purchase.order_id = snapshot["order_id"]
        purchase.purchase_state = state
        purchase.purchase_started_at = starts_at
        purchase.entitlement_ends_at = ends_at
        purchase.acknowledged = (
            snapshot["acknowledgement_state"] == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
        )
        plan_code = PRODUCT_PLANS[product_id]
        if state == "verified":
            subscription = db.scalar(
                select(MembershipSubscription)
                .where(
                    MembershipSubscription.user_id == user.id,
                    MembershipSubscription.source == "google_play",
                    MembershipSubscription.plan_code == plan_code,
                    MembershipSubscription.status.in_(["active", "past_due"]),
                )
                .order_by(MembershipSubscription.created_at.desc())
                .with_for_update()
            )
            if subscription is None:
                subscription = MembershipSubscription(
                    user_id=user.id,
                    plan_code=plan_code,
                    status="active",
                    source="google_play",
                    starts_at=starts_at or datetime.now(UTC),
                    ends_at=ends_at,
                )
                db.add(subscription)
            else:
                subscription.ends_at = ends_at
                subscription.status = "active"
            user.membership_tier = plan_code
        elif state in {"expired", "revoked", "refunded"}:
            for subscription in db.scalars(
                select(MembershipSubscription)
                .where(
                    MembershipSubscription.user_id == user.id,
                    MembershipSubscription.source == "google_play",
                    MembershipSubscription.plan_code == plan_code,
                    MembershipSubscription.status.in_(["active", "past_due"]),
                )
                .with_for_update()
            ):
                subscription.status = state
            if not db.scalar(
                select(MembershipSubscription.id)
                .where(
                    MembershipSubscription.user_id == user.id,
                    MembershipSubscription.status.in_(["active", "trialing", "past_due"]),
                    (
                        MembershipSubscription.ends_at.is_(None)
                        | (MembershipSubscription.ends_at > datetime.now(UTC))
                    ),
                )
                .limit(1)
            ):
                user.membership_tier = "free"
    return {
        "status": state,
        "plan_code": PRODUCT_PLANS[product_id] if state == "verified" else None,
        "expires_at": ends_at.isoformat() if ends_at else None,
    }


def create_manual_membership_payment(
    db: Session,
    user: User,
    settings: object,
    *,
    plan_code: str,
    billing_cycle: str,
    idempotency_key: str,
    payer_full_name: str,
) -> dict[str, object]:
    from nanobio_backend.modules.membership.validate import validate_paid_plan

    plan = validate_paid_plan(plan_code)
    cycle = billing_cycle.strip().casefold()
    if cycle not in {"monthly", "yearly"}:
        raise ApiError(422, "INVALID_BILLING_CYCLE", "Chu kỳ thanh toán chưa hợp lệ.")
    if not idempotency_key.strip() or not payer_full_name.strip():
        raise ApiError(422, "PAYMENT_REQUEST_INVALID", "Thiếu thông tin tạo yêu cầu thanh toán.")
    prices, bank = parse_payment_configuration(settings)
    try:
        amount = int(prices["prices"][plan][cycle])
        currency = str(prices.get("currency", "")).upper()
    except (KeyError, TypeError, ValueError) as exc:
        raise ApiError(
            503, "MEMBERSHIP_PAYMENT_NOT_CONFIGURED", "Giá gói thành viên chưa được cấu hình."
        ) from exc
    if amount <= 0 or currency != "VND":
        raise ApiError(
            503, "MEMBERSHIP_PAYMENT_NOT_CONFIGURED", "Giá gói thành viên chưa được cấu hình."
        )
    with atomic(db):
        db.scalar(select(User).where(User.id == user.id).with_for_update())
        existing = query.by_idempotency_key(db, user.id, idempotency_key)
        if existing is not None:
            if (
                existing.plan_code != plan
                or existing.billing_cycle != cycle
                or existing.payer_full_name != payer_full_name.strip()
            ):
                raise ApiError(
                    409, "IDEMPOTENCY_KEY_REUSED", "Mã yêu cầu đã dùng cho giao dịch khác."
                )
            event = existing
        else:
            open_event = db.scalar(
                select(ManualPaymentEvent)
                .where(
                    ManualPaymentEvent.user_id == user.id,
                    ManualPaymentEvent.status.in_(
                        ["awaiting_transfer", "pending_review", "pending"]
                    ),
                )
                .with_for_update()
            )
            if open_event is not None:
                raise ApiError(
                    409,
                    "MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN",
                    "Bạn đã có một yêu cầu thanh toán đang mở.",
                    meta={"payment_event_id": str(open_event.id)},
                )
            event = ManualPaymentEvent(
                user_id=user.id,
                plan_code=plan,
                billing_cycle=cycle,
                payer_full_name=payer_full_name.strip(),
                amount_cents=amount,
                currency=currency,
                status="awaiting_transfer",
                transfer_reference=f"NB{secrets.token_hex(6).upper()}",
                idempotency_key=idempotency_key.strip(),
                bank_snapshot=bank,
                metadata_json={
                    "manual_approval_required": True,
                    "grants_access_before_approval": False,
                    "transfer_memo_contract": "reference_only_v2",
                },
            )
            db.add(event)
            db.flush()
    return manual_payment_view(event)


def get_manual_membership_payment(db: Session, user: User) -> dict[str, object] | None:
    event = query.current_payment(db, user.id)
    return manual_payment_view(event) if event else None


def confirm_manual_membership_payment(
    db: Session, user: User, payment_id: UUID
) -> dict[str, object]:
    with atomic(db):
        event = query.get_owned_for_update(db, user.id, payment_id)
        if event is None:
            raise ApiError(404, "PAYMENT_NOT_FOUND", "Không tìm thấy yêu cầu thanh toán.")
        if event.status == "awaiting_transfer":
            event.status = "pending_review"
            event.transfer_confirmed_at = now_utc()
        elif event.status != "pending_review":
            raise ApiError(
                409,
                "PAYMENT_TRANSFER_NOT_AWAITING_CONFIRMATION",
                "Yêu cầu này không thể xác nhận chuyển khoản.",
            )
    return manual_payment_view(event)


def cancel_manual_membership_payment(
    db: Session, user: User, payment_id: UUID
) -> dict[str, object]:
    with atomic(db):
        event = query.get_owned_for_update(db, user.id, payment_id)
        if event is None:
            raise ApiError(404, "PAYMENT_NOT_FOUND", "Không tìm thấy yêu cầu thanh toán.")
        if event.status == "awaiting_transfer":
            event.status = "canceled"
        elif event.status != "canceled":
            raise ApiError(409, "PAYMENT_CANCELLATION_NOT_ALLOWED", "Yêu cầu này không thể hủy.")
    return manual_payment_view(event)


def manual_payment_view(event: ManualPaymentEvent) -> dict[str, object]:
    bank = event.bank_snapshot
    return {
        "payment_event_id": str(event.id),
        "plan_code": event.plan_code,
        "billing_cycle": event.billing_cycle,
        "payer_full_name": event.payer_full_name,
        "status": event.status,
        "can_cancel": event.status == "awaiting_transfer",
        "amount_cents": event.amount_cents,
        "currency": event.currency,
        "transfer_reference": event.transfer_reference,
        "transfer_memo": event.transfer_reference,
        "bank_code": bank.get("bank_code"),
        "bank_name": bank.get("bank_name"),
        "bank_bin": bank.get("bank_bin"),
        "bank_account_number": bank.get("bank_account_number"),
        "bank_account_name": bank.get("bank_account_name"),
        "bank_account_display_name": bank.get("bank_account_display_name"),
        "transfer_confirmed_at": (_payment_datetime_iso(event.transfer_confirmed_at)),
        "review_reason": event.review_reason,
        "created_at": _payment_datetime_iso(event.created_at),
        "grants_access_before_approval": False,
    }


def list_manual_payments_for_admin(
    db: Session, *, term: str, limit: int
) -> list[dict[str, object]]:
    rows = query.list_manual_payments(db, term, limit)
    result: list[dict[str, object]] = []
    for event in rows:
        payer = db.get(User, event.user_id)
        payer_name = event.payer_full_name or (payer.full_name if payer else str(event.user_id))
        result.append(
            {
                "id": str(event.id),
                "title": f"{event.plan_code} - {event.amount_cents} {event.currency}",
                "subtitle": (
                    f"{payer_name} · manual_membership_request · {event.transfer_reference}"
                ),
                "status": event.status,
                "section": "payments",
                "created_at": _payment_datetime_iso(event.created_at),
                "transfer_reference": event.transfer_reference,
                "transfer_memo": event.transfer_reference,
                "payer_full_name": payer_name,
                "plan_code": event.plan_code,
                "billing_cycle": event.billing_cycle,
                "amount_cents": event.amount_cents,
                "currency": event.currency,
                "transfer_confirmed_at": _payment_datetime_iso(event.transfer_confirmed_at),
                "review_reason": event.review_reason,
            }
        )
    return result


def review_manual_membership_payment(
    db: Session,
    actor: User,
    payment_id: UUID,
    *,
    decision: str,
    reason: str,
    idempotency_key: str,
    transfer_verified: bool,
) -> dict[str, object]:
    normalized_decision = decision.strip().casefold()
    if normalized_decision not in {"approve", "reject"}:
        raise ApiError(422, "INVALID_PAYMENT_DECISION", "Quyết định duyệt thanh toán chưa hợp lệ.")
    with atomic(db):
        payment_hint = query.get_manual_payment(db, payment_id)
        if payment_hint is None:
            raise ApiError(404, "PAYMENT_NOT_FOUND", "Không tìm thấy giao dịch.")
        payer = query.lock_user(db, payment_hint.user_id)
        if payer is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản thanh toán.")
        event = query.lock_manual_payment(db, payment_id)
        if event is None:
            raise ApiError(404, "PAYMENT_NOT_FOUND", "Không tìm thấy giao dịch.")
        if actor.id == event.user_id:
            raise ApiError(
                403, "PAYMENT_SELF_REVIEW_FORBIDDEN", "Bạn không thể tự duyệt giao dịch của mình."
            )
        if event.status in {"succeeded", "failed"}:
            if event.metadata_json.get("admin_decision") == normalized_decision:
                return {
                    "success": True,
                    "payment_event_id": str(event.id),
                    "status": event.status,
                    "subscription_id": str(event.subscription_id)
                    if event.subscription_id
                    else None,
                    "idempotent_replay": True,
                }
            raise ApiError(409, "PAYMENT_ALREADY_REVIEWED", "Giao dịch đã được xử lý trước đó.")
        if not reason.strip() or not idempotency_key.strip():
            raise ApiError(422, "PAYMENT_REVIEW_CONTEXT_REQUIRED", "Cần có lý do và mã thao tác.")
        if normalized_decision == "approve" and transfer_verified is not True:
            raise ApiError(
                422,
                "PAYMENT_TRANSFER_RECONCILIATION_REQUIRED",
                "Cần xác nhận đã đối soát chuyển khoản trước khi duyệt.",
            )
        if event.status not in {"pending_review", "pending"}:
            raise ApiError(409, "PAYMENT_NOT_READY_FOR_REVIEW", "Giao dịch chưa sẵn sàng để duyệt.")
        now = now_utc()
        subscription: MembershipSubscription | None = None
        transition = "rejected"
        if normalized_decision == "approve":
            if event.billing_cycle not in {"monthly", "yearly"}:
                raise ApiError(409, "PAYMENT_BILLING_CYCLE_MISSING", "Thiếu chu kỳ thanh toán.")
            active_paid = list(
                db.scalars(
                    select(MembershipSubscription)
                    .where(
                        MembershipSubscription.user_id == event.user_id,
                        MembershipSubscription.plan_code.in_(["plus", "family_plus"]),
                        MembershipSubscription.status.in_(["trialing", "active"]),
                        MembershipSubscription.starts_at <= now,
                        (
                            MembershipSubscription.ends_at.is_(None)
                            | (MembershipSubscription.ends_at > now)
                        ),
                    )
                    .order_by(
                        MembershipSubscription.ends_at.desc(),
                        MembershipSubscription.starts_at.desc(),
                    )
                    .with_for_update()
                ).all()
            )
            if any(row.ends_at is None for row in active_paid):
                raise ApiError(
                    409,
                    "LEGACY_PAID_SUBSCRIPTION_MISSING_ENDS_AT",
                    "Cần kiểm tra gói hiện tại trước khi duyệt giao dịch mới.",
                )
            for row in active_paid:
                if row.plan_code != event.plan_code:
                    row.status = "canceled"
                    safe_end = max(now, _as_utc(row.starts_at) + timedelta(microseconds=1))
                    row.ends_at = safe_end
                    row.current_period_end = safe_end
                    row.metadata_json = {
                        **row.metadata_json,
                        "superseded_at": now.isoformat(),
                        "superseded_by_payment_event_id": str(event.id),
                        "superseded_by_plan_code": event.plan_code,
                    }
            same_plan = next((row for row in active_paid if row.plan_code == event.plan_code), None)
            period_start = _as_utc(same_plan.ends_at) if same_plan and same_plan.ends_at else now
            period_end = _add_billing_cycle(period_start, event.billing_cycle)
            if same_plan is not None:
                subscription = same_plan
                subscription.ends_at = period_end
                subscription.current_period_start = period_start
                subscription.current_period_end = period_end
                transition = "same_plan_renewal"
                subscription.metadata_json = {
                    **subscription.metadata_json,
                    "last_membership_payment_event_id": str(event.id),
                    "last_billing_cycle": event.billing_cycle,
                    "last_renewed_at": now.isoformat(),
                }
            else:
                transition = (
                    "plan_switch"
                    if any(row.status == "canceled" for row in active_paid)
                    else "new_subscription"
                )
                subscription = MembershipSubscription(
                    user_id=event.user_id,
                    plan_code=event.plan_code,
                    status="active",
                    source="payment_provider",
                    starts_at=period_start,
                    ends_at=period_end,
                    current_period_start=period_start,
                    current_period_end=period_end,
                    provider="manual_membership_request",
                    provider_subscription_id=event.transfer_reference,
                    metadata_json={
                        "payment_event_id": str(event.id),
                        "billing_cycle": event.billing_cycle,
                        "approved_at": now.isoformat(),
                        "subscription_transition": transition,
                    },
                )
                db.add(subscription)
            payer.membership_tier = event.plan_code
            db.flush()
            for row in active_paid:
                if row.status == "canceled":
                    row.metadata_json = {
                        **row.metadata_json,
                        "superseded_by_subscription_id": str(subscription.id),
                    }
        event.status = "succeeded" if normalized_decision == "approve" else "failed"
        event.paid_at = now if normalized_decision == "approve" else event.paid_at
        event.reviewed_by = actor.id
        event.reviewed_at = now
        event.review_reason = reason.strip()
        if subscription is not None:
            event.subscription_id = subscription.id
        event.metadata_json = {
            **event.metadata_json,
            "admin_decision": normalized_decision,
            "admin_review_idempotency_key": idempotency_key.strip(),
            "manual_approval_required": True,
            "transfer_reconciliation_confirmed": transfer_verified,
            "billing_cycle": event.billing_cycle,
            "subscription_transition": transition,
            "subscription_id": str(subscription.id) if subscription else None,
        }
        db.add(
            AdminAuditEvent(
                actor_id=actor.id,
                action="admin_review_payment",
                target_user_id=event.user_id,
                reason=reason.strip(),
                idempotency_key=idempotency_key.strip(),
                metadata_json={
                    "payment_event_id": str(event.id),
                    "decision": normalized_decision,
                    "transfer_reconciliation_confirmed": transfer_verified,
                    "subscription_id": str(subscription.id) if subscription else None,
                    "subscription_transition": transition,
                },
            )
        )
    return {
        "success": True,
        "payment_event_id": str(event.id),
        "status": event.status,
        "subscription_id": str(event.subscription_id) if event.subscription_id else None,
        "idempotent_replay": False,
    }


def _as_utc(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def _add_billing_cycle(period_start: datetime, cycle: str) -> datetime:
    vietnam = ZoneInfo("Asia/Ho_Chi_Minh")
    local = _as_utc(period_start).astimezone(vietnam)
    if cycle == "monthly":
        year = local.year + (1 if local.month == 12 else 0)
        month = 1 if local.month == 12 else local.month + 1
    else:
        year = local.year + 1
        month = local.month
    day = min(local.day, calendar.monthrange(year, month)[1])
    return local.replace(year=year, month=month, day=day).astimezone(UTC)


def _payment_datetime_iso(value: datetime | None) -> str | None:
    if value is None:
        return None
    return _as_utc(value).isoformat()
