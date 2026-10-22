from uuid import UUID

from sqlalchemy import case, select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import ManualPaymentEvent, User


def by_idempotency_key(db: Session, user_id: UUID, key: str) -> ManualPaymentEvent | None:
    return db.scalar(
        select(ManualPaymentEvent)
        .where(
            ManualPaymentEvent.user_id == user_id,
            ManualPaymentEvent.idempotency_key == key,
        )
        .with_for_update()
    )


def current_payment(db: Session, user_id: UUID) -> ManualPaymentEvent | None:
    return db.scalar(
        select(ManualPaymentEvent)
        .where(ManualPaymentEvent.user_id == user_id)
        .order_by(
            ManualPaymentEvent.status.in_(["awaiting_transfer", "pending_review"]).desc(),
            ManualPaymentEvent.created_at.desc(),
        )
        .limit(1)
    )


def get_owned_for_update(db: Session, user_id: UUID, payment_id: UUID) -> ManualPaymentEvent | None:
    return db.scalar(
        select(ManualPaymentEvent)
        .where(ManualPaymentEvent.id == payment_id, ManualPaymentEvent.user_id == user_id)
        .with_for_update()
    )


def get_manual_payment(db: Session, payment_id: UUID) -> ManualPaymentEvent | None:
    return db.get(ManualPaymentEvent, payment_id)


def lock_user(db: Session, user_id: UUID) -> User | None:
    return db.scalar(select(User).where(User.id == user_id).with_for_update())


def lock_manual_payment(db: Session, payment_id: UUID) -> ManualPaymentEvent | None:
    return db.scalar(
        select(ManualPaymentEvent).where(ManualPaymentEvent.id == payment_id).with_for_update()
    )


def list_manual_payments(db: Session, term: str, limit: int) -> list[ManualPaymentEvent]:
    statement = select(ManualPaymentEvent).join(User, User.id == ManualPaymentEvent.user_id)
    if term.strip():
        pattern = f"%{term.strip()}%"
        statement = statement.where(
            User.full_name.ilike(pattern)
            | User.email.ilike(pattern)
            | ManualPaymentEvent.transfer_reference.ilike(pattern)
            | ManualPaymentEvent.payer_full_name.ilike(pattern)
        )
    return list(
        db.scalars(
            statement.order_by(
                case(
                    (ManualPaymentEvent.status == "pending_review", 0),
                    (ManualPaymentEvent.status == "pending", 1),
                    else_=2,
                ),
                ManualPaymentEvent.created_at.desc(),
            ).limit(min(max(limit, 1), 100))
        ).all()
    )
