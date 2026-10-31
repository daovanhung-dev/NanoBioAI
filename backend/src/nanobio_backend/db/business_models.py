"""Self-hosted business tables ported from the former hosted contracts."""

from __future__ import annotations

from datetime import date, datetime, time
from decimal import Decimal
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from nanobio_backend.db.base import Base
from nanobio_backend.db.models import now_utc


class SaleProfile(Base):
    __tablename__ = "sale_profiles"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    status: Mapped[str] = mapped_column(String(24), default="pending", index=True)
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    suspended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    terms_version: Mapped[str | None] = mapped_column(String(80), nullable=True)
    terms_accepted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    participation_device_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class SalePayoutProfile(Base):
    __tablename__ = "sale_payout_profiles"

    sale_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("sale_profiles.user_id", ondelete="CASCADE"), primary_key=True
    )
    citizen_id: Mapped[str] = mapped_column(String(64))
    bank_bin: Mapped[str] = mapped_column(String(32))
    bank_name: Mapped[str] = mapped_column(String(160))
    bank_account_number: Mapped[str] = mapped_column(String(64))
    bank_account_name: Mapped[str] = mapped_column(String(160))
    updated_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class PaymentEvent(Base):
    __tablename__ = "payment_events"
    __table_args__ = (
        UniqueConstraint("provider", "provider_event_id", name="uq_payment_event_provider_event"),
        CheckConstraint("amount_cents >= 0", name="ck_payment_event_amount_nonnegative"),
        Index("ix_payment_event_status_created", "status", "created_at"),
        Index("ix_payment_event_payer_paid", "payer_user_id", "paid_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    payer_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), index=True
    )
    subscription_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("membership_subscriptions.id", ondelete="SET NULL"), nullable=True
    )
    plan_code: Mapped[str] = mapped_column(String(80))
    provider: Mapped[str] = mapped_column(String(40))
    provider_event_id: Mapped[str] = mapped_column(String(256))
    transfer_reference: Mapped[str | None] = mapped_column(String(64), nullable=True)
    transfer_memo: Mapped[str | None] = mapped_column(String(80), nullable=True)
    amount_cents: Mapped[int] = mapped_column(Integer)
    list_price_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    commission_base_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(32), index=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    review_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class CommissionRate(Base):
    __tablename__ = "commission_rates"

    code: Mapped[str] = mapped_column(String(80), primary_key=True)
    rate: Mapped[Decimal] = mapped_column(Numeric(5, 4))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class CommissionRecord(Base):
    __tablename__ = "commission_records"
    __table_args__ = (
        UniqueConstraint(
            "payment_event_id", "receiver_user_id", name="uq_commission_payment_receiver"
        ),
        CheckConstraint("rate >= 0 and rate <= 1", name="ck_commission_rate_range"),
        CheckConstraint("amount_cents >= 0", name="ck_commission_amount_nonnegative"),
        Index("ix_commission_receiver_status_created", "receiver_user_id", "status", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    payment_event_id: Mapped[UUID] = mapped_column(
        ForeignKey("payment_events.id", ondelete="CASCADE")
    )
    receiver_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), index=True
    )
    payer_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), index=True
    )
    source_referral_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("referral_relationships.id", ondelete="SET NULL"), nullable=True
    )
    rate: Mapped[Decimal] = mapped_column(Numeric(5, 4))
    amount_cents: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(24), default="pending")
    available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SalePointAdjustment(Base):
    __tablename__ = "sale_point_adjustments"
    __table_args__ = (UniqueConstraint("idempotency_key", name="uq_sale_adjustment_idempotency"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    sale_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), index=True
    )
    point_delta_cents: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(24), default="approved")
    reason: Mapped[str] = mapped_column(Text)
    reviewed_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class SalePointConversion(Base):
    __tablename__ = "sale_point_conversions"
    __table_args__ = (
        UniqueConstraint("sale_user_id", "idempotency_key", name="uq_sale_conversion_idempotency"),
        Index("ix_sale_conversion_status_created", "status", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    sale_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("sale_profiles.user_id", ondelete="CASCADE"), index=True
    )
    requested_point_cents: Mapped[int] = mapped_column(Integer)
    point_to_money_rate: Mapped[Decimal] = mapped_column(Numeric(12, 4))
    money_amount_cents: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="VND")
    status: Mapped[str] = mapped_column(String(24), default="requested", index=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    reviewed_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    review_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessRewardWallet(Base):
    __tablename__ = "wellness_reward_wallets"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    pending_points: Mapped[int] = mapped_column(Integer, default=0)
    available_points: Mapped[int] = mapped_column(Integer, default=0)
    lifetime_earned_points: Mapped[int] = mapped_column(Integer, default=0)
    lifetime_spent_points: Mapped[int] = mapped_column(Integer, default=0)
    lifetime_refunded_points: Mapped[int] = mapped_column(Integer, default=0)
    lock_version: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessPointLedger(Base):
    __tablename__ = "wellness_point_ledgers"
    __table_args__ = (
        UniqueConstraint("user_id", "idempotency_key", name="uq_wellness_ledger_idempotency"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("health_subjects.id", ondelete="CASCADE"))
    source_type: Mapped[str] = mapped_column(String(40))
    source_id: Mapped[UUID | None] = mapped_column(nullable=True)
    schedule_date: Mapped[date] = mapped_column(Date)
    points_delta: Mapped[int] = mapped_column(Integer)
    program_code: Mapped[str] = mapped_column(String(80))
    idempotency_key: Mapped[str] = mapped_column(String(160))
    event_type: Mapped[str] = mapped_column(String(40), default="legacy_history")
    status: Mapped[str] = mapped_column(String(24), default="history")
    title: Mapped[str] = mapped_column(String(200), default="Lịch sử điểm")
    is_redeemable: Mapped[bool] = mapped_column(Boolean, default=False)
    available_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    eligibility_id: Mapped[UUID | None] = mapped_column(nullable=True)
    redemption_id: Mapped[UUID | None] = mapped_column(nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class WellnessPointAllocation(Base):
    __tablename__ = "wellness_point_allocations"
    __table_args__ = (
        UniqueConstraint("source_type", "source_id", name="uq_wellness_allocation_source"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("health_subjects.id", ondelete="CASCADE"))
    ledger_id: Mapped[UUID] = mapped_column(
        ForeignKey("wellness_point_ledgers.id", ondelete="RESTRICT"), unique=True
    )
    eligibility_id: Mapped[UUID | None] = mapped_column(nullable=True)
    source_type: Mapped[str] = mapped_column(String(40))
    source_id: Mapped[UUID] = mapped_column()
    original_points: Mapped[int] = mapped_column(Integer)
    remaining_points: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(24))
    available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    program_config_id: Mapped[UUID | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessRewardOffer(Base):
    __tablename__ = "wellness_reward_offers"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    offer_code: Mapped[str] = mapped_column(String(80), unique=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)
    provider_name: Mapped[str] = mapped_column(String(160))
    cost_points: Mapped[int] = mapped_column(Integer)
    reward_type: Mapped[str] = mapped_column(String(24), default="voucher")
    stock_count: Mapped[int] = mapped_column(Integer, default=0)
    eligible_plan_codes: Mapped[list[str]] = mapped_column(
        JSON, default=lambda: ["free", "plus", "family_plus"]
    )
    available_from: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    available_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    voucher_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    updated_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessRewardCode(Base):
    __tablename__ = "wellness_reward_codes"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    offer_id: Mapped[UUID] = mapped_column(
        ForeignKey("wellness_reward_offers.id", ondelete="RESTRICT"), index=True
    )
    code_value: Mapped[str] = mapped_column(String(256))
    code_hash: Mapped[str] = mapped_column(String(64), unique=True)
    status: Mapped[str] = mapped_column(String(24), default="available", index=True)
    voucher_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    assigned_user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    assigned_redemption_id: Mapped[UUID | None] = mapped_column(nullable=True)
    issued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    retired_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    imported_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    import_batch_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class WellnessRewardRedemption(Base):
    __tablename__ = "wellness_reward_redemptions"
    __table_args__ = (
        UniqueConstraint("user_id", "idempotency_key", name="uq_wellness_redemption_idempotency"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    offer_id: Mapped[UUID] = mapped_column(
        ForeignKey("wellness_reward_offers.id", ondelete="RESTRICT")
    )
    reward_code_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("wellness_reward_codes.id", ondelete="RESTRICT"), nullable=True, unique=True
    )
    offer_title_snapshot: Mapped[str] = mapped_column(String(200))
    provider_name_snapshot: Mapped[str] = mapped_column(String(160))
    points_spent: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(24), default="issued")
    voucher_expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    reward_type_snapshot: Mapped[str] = mapped_column(String(24), default="voucher")
    idempotency_key: Mapped[str] = mapped_column(String(160))
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    received_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    received_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    cancellation_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    refund_allocation_id: Mapped[UUID | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessRedemptionAllocationUsage(Base):
    __tablename__ = "wellness_redemption_allocation_usages"
    __table_args__ = (
        UniqueConstraint("redemption_id", "allocation_id", name="uq_redemption_allocation_use"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    redemption_id: Mapped[UUID] = mapped_column(
        ForeignKey("wellness_reward_redemptions.id", ondelete="RESTRICT")
    )
    allocation_id: Mapped[UUID] = mapped_column(
        ForeignKey("wellness_point_allocations.id", ondelete="RESTRICT")
    )
    points_used: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class WellnessRankAccount(Base):
    __tablename__ = "wellness_rank_accounts"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    experience_points: Mapped[int] = mapped_column(Integer, default=0)
    first_exp_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    next_decay_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    decay_cycle: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class WellnessRankExperienceLedger(Base):
    __tablename__ = "wellness_rank_experience_ledger"
    __table_args__ = (UniqueConstraint("user_id", "event_key", name="uq_wellness_rank_event"),)

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    event_key: Mapped[str] = mapped_column(String(160))
    event_type: Mapped[str] = mapped_column(String(32))
    schedule_item_id: Mapped[UUID | None] = mapped_column(nullable=True)
    source_event_id: Mapped[UUID | None] = mapped_column(nullable=True)
    experience_delta: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class ScheduleRewardEligibility(Base):
    __tablename__ = "schedule_reward_eligibilities"
    __table_args__ = (
        UniqueConstraint("user_id", "schedule_item_id", name="uq_schedule_reward_item"),
        UniqueConstraint(
            "user_id", "registration_idempotency_key", name="uq_schedule_reward_registration"
        ),
        Index("ix_schedule_reward_user_window", "user_id", "window_start", "window_end"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("health_subjects.id", ondelete="CASCADE"))
    schedule_item_id: Mapped[UUID] = mapped_column()
    schedule_request_id: Mapped[str] = mapped_column(String(160))
    schedule_date: Mapped[date] = mapped_column(Date)
    start_time: Mapped[time] = mapped_column(Time)
    window_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    window_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    title_snapshot: Mapped[str] = mapped_column(String(240))
    category_snapshot: Mapped[str | None] = mapped_column(String(80), nullable=True)
    source_type_snapshot: Mapped[str] = mapped_column(String(80))
    source_id_snapshot: Mapped[str | None] = mapped_column(String(160), nullable=True)
    status: Mapped[str] = mapped_column(String(24), default="eligible", index=True)
    registration_idempotency_key: Mapped[str] = mapped_column(String(160))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class ScheduleRewardRegistration(Base):
    __tablename__ = "schedule_reward_registrations"
    __table_args__ = (
        UniqueConstraint("user_id", "schedule_request_id", name="uq_schedule_registration_request"),
        UniqueConstraint("user_id", "idempotency_key", name="uq_schedule_registration_idempotency"),
        UniqueConstraint("guest_user_id", name="uq_schedule_guest_registration_user"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    guest_user_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=True
    )
    schedule_request_id: Mapped[str] = mapped_column(String(160))
    actor_mode: Mapped[str] = mapped_column(String(32))
    plan_start_date: Mapped[date] = mapped_column(Date)
    plan_days: Mapped[int] = mapped_column(Integer)
    plan_item_count: Mapped[int] = mapped_column(Integer)
    manifest_hash: Mapped[str] = mapped_column(String(64))
    idempotency_key: Mapped[str] = mapped_column(String(160))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)


class ScheduleCompletionAttempt(Base):
    __tablename__ = "schedule_completion_attempts"
    __table_args__ = (
        UniqueConstraint("user_id", "begin_idempotency_key", name="uq_schedule_attempt_begin"),
        UniqueConstraint(
            "user_id", "finalize_idempotency_key", name="uq_schedule_attempt_finalize"
        ),
        UniqueConstraint("user_id", "undo_idempotency_key", name="uq_schedule_attempt_undo"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    eligibility_id: Mapped[UUID] = mapped_column(
        ForeignKey("schedule_reward_eligibilities.id", ondelete="CASCADE")
    )
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    begin_idempotency_key: Mapped[str] = mapped_column(String(160))
    finalize_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    undo_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    object_path: Mapped[str] = mapped_column(String(512), unique=True)
    status: Mapped[str] = mapped_column(String(24), default="begun", index=True)
    began_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    finalized_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    rejection_code: Mapped[str | None] = mapped_column(String(80), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class ScheduleCompletionProof(Base):
    __tablename__ = "schedule_completion_proofs"
    __table_args__ = (
        UniqueConstraint("user_id", "undo_idempotency_key", name="uq_schedule_proof_undo"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    eligibility_id: Mapped[UUID] = mapped_column(
        ForeignKey("schedule_reward_eligibilities.id", ondelete="CASCADE")
    )
    attempt_id: Mapped[UUID] = mapped_column(
        ForeignKey("schedule_completion_attempts.id", ondelete="CASCADE"), unique=True
    )
    file_id: Mapped[UUID] = mapped_column(
        ForeignKey("file_objects.id", ondelete="RESTRICT"), unique=True
    )
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    bucket_id: Mapped[str] = mapped_column(String(80), default="schedule-completion-proofs")
    object_path: Mapped[str] = mapped_column(String(512), unique=True)
    content_type: Mapped[str] = mapped_column(String(80), default="image/jpeg")
    byte_size: Mapped[int] = mapped_column(Integer)
    captured_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    status: Mapped[str] = mapped_column(String(24), default="active")
    reversed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    undo_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class ScheduleHealthCheckin(Base):
    __tablename__ = "schedule_health_checkins"
    __table_args__ = (
        UniqueConstraint("user_id", "idempotency_key", name="uq_schedule_checkin_idempotency"),
        UniqueConstraint("user_id", "undo_idempotency_key", name="uq_schedule_checkin_undo"),
        Index("ix_schedule_checkin_user_day_status", "user_id", "schedule_date", "status"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    eligibility_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("schedule_reward_eligibilities.id", ondelete="SET NULL"), nullable=True
    )
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    subject_id: Mapped[UUID] = mapped_column(ForeignKey("health_subjects.id", ondelete="CASCADE"))
    schedule_item_id: Mapped[UUID] = mapped_column()
    action_type: Mapped[str] = mapped_column(String(32))
    checkin_payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    reward_points: Mapped[int] = mapped_column(Integer)
    schedule_date: Mapped[date] = mapped_column(Date)
    start_time: Mapped[time] = mapped_column(Time)
    window_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    title_snapshot: Mapped[str] = mapped_column(String(240))
    category_snapshot: Mapped[str] = mapped_column(String(80))
    source_type_snapshot: Mapped[str] = mapped_column(String(80))
    source_id_snapshot: Mapped[str | None] = mapped_column(String(240), nullable=True)
    idempotency_key: Mapped[str] = mapped_column(String(160))
    status: Mapped[str] = mapped_column(String(24), default="active", index=True)
    undo_idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    reversed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )


class AdminReconciliationRun(Base):
    __tablename__ = "admin_reconciliation_runs"
    __table_args__ = (
        UniqueConstraint("idempotency_key", name="uq_reconciliation_run_idempotency"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    scope: Mapped[str] = mapped_column(String(80), default="payments")
    status: Mapped[str] = mapped_column(String(24), default="open", index=True)
    reason: Mapped[str] = mapped_column(Text)
    created_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AdminReconciliationDiscrepancy(Base):
    __tablename__ = "admin_reconciliation_discrepancies"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    run_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("admin_reconciliation_runs.id", ondelete="SET NULL"), nullable=True
    )
    target_type: Mapped[str] = mapped_column(String(80))
    target_id: Mapped[str] = mapped_column(String(160), index=True)
    severity: Mapped[str] = mapped_column(String(16), default="medium")
    status: Mapped[str] = mapped_column(String(24), default="open", index=True)
    summary: Mapped[str] = mapped_column(Text)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    reviewed_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    review_reason: Mapped[str | None] = mapped_column(Text, nullable=True)


class ReportExport(Base):
    __tablename__ = "report_exports"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    report_type: Mapped[str] = mapped_column(String(120))
    filters: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(24), default="requested", index=True)
    reason: Mapped[str] = mapped_column(Text)
    requested_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class SystemConfigVersion(Base):
    __tablename__ = "system_config_versions"
    __table_args__ = (
        Index("ix_system_config_key_status_created", "config_key", "status", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    config_key: Mapped[str] = mapped_column(String(120))
    config_value: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    version: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(24), default="draft", index=True)
    reason: Mapped[str] = mapped_column(Text)
    created_by: Mapped[UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    activated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
