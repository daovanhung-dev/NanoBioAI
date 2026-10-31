"""Idempotent server maintenance for time-based entitlements and rewards."""

from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.database import create_session_factory
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.business_models import (
    CommissionRecord,
    WellnessPointAllocation,
    WellnessPointLedger,
    WellnessRewardWallet,
)
from nanobio_backend.db.models import MembershipSubscription, User


def run_maintenance(db: Session, *, now: datetime | None = None) -> dict[str, int]:
    """Mature/expire reward balances and mark ended memberships, once per hour."""
    instant = _as_utc(now or datetime.now(UTC))
    counts = {
        "memberships_expired": 0,
        "allocations_matured": 0,
        "allocations_expired": 0,
        "commissions_released": 0,
    }
    with atomic(db):
        expired = list(
            db.scalars(
                select(MembershipSubscription)
                .where(
                    MembershipSubscription.status.in_(("trialing", "active", "past_due")),
                    MembershipSubscription.ends_at.is_not(None),
                    MembershipSubscription.ends_at <= instant,
                )
                .order_by(MembershipSubscription.ends_at, MembershipSubscription.id)
                .limit(1000)
                .with_for_update(skip_locked=True)
            )
        )
        affected_users: set[UUID] = set()
        for subscription in expired:
            subscription.status = "expired"
            affected_users.add(subscription.user_id)
            counts["memberships_expired"] += 1
        for user_id in affected_users:
            user = db.scalar(select(User).where(User.id == user_id).with_for_update())
            if user is None:
                continue
            active = db.scalar(
                select(MembershipSubscription)
                .where(
                    MembershipSubscription.user_id == user_id,
                    MembershipSubscription.status.in_(("trialing", "active", "past_due")),
                    MembershipSubscription.starts_at <= instant,
                    (
                        MembershipSubscription.ends_at.is_(None)
                        | (MembershipSubscription.ends_at > instant)
                    ),
                )
                .order_by(MembershipSubscription.created_at.desc())
                .limit(1)
            )
            user.membership_tier = active.plan_code if active else "free"

        due_allocations = list(
            db.scalars(
                select(WellnessPointAllocation)
                .where(
                    WellnessPointAllocation.status.in_(("pending", "available")),
                    WellnessPointAllocation.remaining_points > 0,
                    (
                        (WellnessPointAllocation.status == "pending")
                        & (
                            (WellnessPointAllocation.available_at <= instant)
                            | (WellnessPointAllocation.expires_at <= instant)
                        )
                    )
                    | (
                        (WellnessPointAllocation.status == "available")
                        & (WellnessPointAllocation.expires_at <= instant)
                    ),
                )
                .order_by(WellnessPointAllocation.expires_at, WellnessPointAllocation.id)
                .limit(5000)
                .with_for_update(skip_locked=True)
            )
        )
        for allocation in due_allocations:
            previous_status = allocation.status
            wallet = db.scalar(
                select(WellnessRewardWallet)
                .where(WellnessRewardWallet.user_id == allocation.user_id)
                .with_for_update()
            )
            if wallet is None:
                raise RuntimeError("wellness allocation is missing its wallet")
            ledger = db.get(WellnessPointLedger, allocation.ledger_id)
            points = allocation.remaining_points
            if allocation.expires_at <= instant:
                allocation.status = "expired"
                allocation.remaining_points = 0
                if ledger is not None:
                    ledger.status = "expired"
                    ledger.is_redeemable = False
                if previous_status == "pending":
                    wallet.pending_points = max(0, wallet.pending_points - points)
                else:
                    wallet.available_points = max(0, wallet.available_points - points)
                counts["allocations_expired"] += 1
            elif allocation.status == "pending" and allocation.available_at <= instant:
                allocation.status = "available"
                wallet.pending_points = max(0, wallet.pending_points - points)
                wallet.available_points += points
                if ledger is not None:
                    ledger.status = "available"
                    ledger.is_redeemable = True
                counts["allocations_matured"] += 1
            wallet.lock_version += 1
            wallet.updated_at = instant

        released = list(
            db.scalars(
                select(CommissionRecord)
                .where(
                    CommissionRecord.status == "pending",
                    CommissionRecord.available_at <= instant,
                )
                .order_by(CommissionRecord.available_at, CommissionRecord.id)
                .limit(5000)
                .with_for_update(skip_locked=True)
            )
        )
        for commission in released:
            commission.status = "approved"
            counts["commissions_released"] += 1
    return counts


def main() -> None:
    from nanobio_backend.core.config import get_settings

    settings = get_settings()
    engine, factory = create_session_factory(settings)
    try:
        with factory() as db:
            result = run_maintenance(db)
        summary: dict[str, Any] = result
        print(
            "NanoBio maintenance completed: "
            + ", ".join(f"{name}={count}" for name, count in summary.items())
        )
    finally:
        engine.dispose()


def _as_utc(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


if __name__ == "__main__":
    main()
