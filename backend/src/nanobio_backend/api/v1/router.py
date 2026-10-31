from fastapi import APIRouter

from nanobio_backend.modules.account.router import router as account_router
from nanobio_backend.modules.admin.router import router as admin_router
from nanobio_backend.modules.auth.router import router as auth_router
from nanobio_backend.modules.business.router import router as business_router
from nanobio_backend.modules.cloud_sync.router import router as cloud_sync_router
from nanobio_backend.modules.edge_api.router import router as edge_router
from nanobio_backend.modules.family_plus.router import router as family_plus_router
from nanobio_backend.modules.membership.router import router as membership_router
from nanobio_backend.modules.payments.router import router as payments_router
from nanobio_backend.modules.profile.router import router as profile_router
from nanobio_backend.modules.schedule_rewards.router import router as schedule_rewards_router
from nanobio_backend.modules.sleep_safety.router import router as sleep_safety_router
from nanobio_backend.modules.storage.router import router as storage_router
from nanobio_backend.modules.usage_quota.router import router as usage_quota_router

router = APIRouter()
router.include_router(auth_router, prefix="/auth", tags=["auth"])
router.include_router(account_router, tags=["account"])
router.include_router(admin_router, prefix="/admin", tags=["admin"])
router.include_router(edge_router, tags=["integrations"])
router.include_router(storage_router, prefix="/files", tags=["files"])
router.include_router(sleep_safety_router, tags=["sleep-safety"])
router.include_router(profile_router, prefix="/profile", tags=["profile"])
router.include_router(membership_router, prefix="/membership", tags=["membership"])
router.include_router(cloud_sync_router, prefix="/cloud-sync", tags=["cloud-sync"])
router.include_router(payments_router, prefix="/payments", tags=["payments"])
router.include_router(family_plus_router, prefix="/family-plus", tags=["family-plus"])
router.include_router(usage_quota_router, prefix="/usage-quota", tags=["usage-quota"])
router.include_router(business_router, tags=["business"])
router.include_router(
    schedule_rewards_router, prefix="/schedule-rewards", tags=["schedule-rewards"]
)
