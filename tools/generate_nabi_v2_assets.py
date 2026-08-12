#!/usr/bin/env python3
"""Build deterministic Nabi v2 derivative assets from one approved master PNG.

This is deliberately an *asset scaffolding* tool, not an image-generation
tool.  It never calls a model or network service.  It derives every image by
cropping, scaling, mirroring, rotating, and compositing the supplied approved
RGBA master.  Therefore it is useful for a complete, repeatable QA bundle and
runtime wiring, but it does not claim to create 84 artist-distinct poses from
one drawing.

Typical production invocation (all roots are explicit)::

    python tools/generate_nabi_v2_assets.py generate \
      --master assets/nabi_v2/00_master/nabi_v2_master.png \
      --anchors-root assets/nabi_v2/00_master \
      --static-root assets/images/nabi_v2 \
      --sprite-root assets/nabi_v2 \
      --catalog-root assets/config/nabi_v2

The command does not overwrite an existing planned output file unless
``--overwrite`` is passed.  Existing roots and unrelated files are left alone.
Validate a generated bundle with::

    python tools/generate_nabi_v2_assets.py validate \
      --static-root assets/images/nabi_v2 \
      --sprite-root assets/nabi_v2 \
      --catalog-root assets/config/nabi_v2

Dependency: Pillow (``python -m pip install pillow``).  The tool only writes
below the explicit static, sprite, and optional catalog roots.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

try:
    from PIL import Image, ImageOps
except ImportError as error:  # pragma: no cover - actionable CLI failure.
    raise SystemExit(
        "Pillow is required. Install it with: python -m pip install pillow"
    ) from error


TOOL_VERSION = "1.0.0"
STATIC_CANVAS = (512, 512)
EXPRESSION_CANVAS = (512, 512)
FRAME_CANVAS = (384, 384)
EFFECT_CANVAS = (256, 256)
FRAME_COUNT = 30
SPRITESHEET_COLUMNS = 10

RESAMPLING = getattr(Image, "Resampling", Image).LANCZOS
BICUBIC = getattr(Image, "Resampling", Image).BICUBIC
class ToolError(RuntimeError):
    """Raised for an actionable input, filesystem, or validation error."""


@dataclass(frozen=True)
class StaticSpec:
    number: int
    category: str
    filename: str
    pose: str
    expression: str

    @property
    def asset_id(self) -> str:
        return f"nabi_state_{self.number:03d}"

    @property
    def relative_path(self) -> Path:
        return Path(self.category) / self.filename


@dataclass(frozen=True)
class ExpressionSpec:
    legacy_id: str
    filename: str
    gentle_semantic: str
    pose: str
    expression: str

    @property
    def asset_id(self) -> str:
        return self.legacy_id.lower()

    @property
    def relative_path(self) -> Path:
        return Path("01_character") / "01_static_expressions" / self.filename


@dataclass(frozen=True)
class AnimationSpec:
    legacy_id: str
    module: str
    gentle_semantic: str
    motion_profile: str
    loop: bool = True

    @property
    def asset_id(self) -> str:
        return self.legacy_id.lower()

    @property
    def frames_relative_dir(self) -> Path:
        return (
            Path("01_character")
            / "02_30fps_frames"
            / self.module
            / self.asset_id
        )

    @property
    def spritesheet_relative_path(self) -> Path:
        return (
            Path("02_spritesheets")
            / self.module
            / f"{self.asset_id}_spritesheet_10x3.png"
        )


@dataclass(frozen=True)
class EffectSpec:
    legacy_id: str
    gentle_semantic: str
    motion_profile: str

    @property
    def asset_id(self) -> str:
        return self.legacy_id.lower()

    @property
    def frames_relative_dir(self) -> Path:
        return Path("03_effects") / "01_png_frames" / self.asset_id

    @property
    def spritesheet_relative_path(self) -> Path:
        return (
            Path("03_effects")
            / "02_spritesheets"
            / f"{self.asset_id}_spritesheet_10x3.png"
        )


# The static catalog intentionally mirrors every legacy category/basename
# contract.  Physical paths are lower case; runtime compatibility belongs in
# the generated metadata's ``legacy_id`` fields, not in filename casing.
STATIC_SPECS: tuple[StaticSpec, ...] = (
    StaticSpec(1, "core", "nabi_idle_neutral.png", "wave", "neutral"),
    StaticSpec(2, "core", "nabi_idle_happy.png", "celebrate", "happy"),
    StaticSpec(3, "core", "nabi_wave.png", "wave", "happy"),
    StaticSpec(4, "core", "nabi_point_guide.png", "guide", "helpful"),
    StaticSpec(5, "core", "nabi_listen.png", "listen", "attentive"),
    StaticSpec(6, "core", "nabi_think.png", "think", "thinking"),
    StaticSpec(7, "core", "nabi_analyze.png", "think", "thinking"),
    StaticSpec(8, "core", "nabi_speak.png", "guide", "helpful"),
    StaticSpec(9, "onboarding", "nabi_onboarding_intro.png", "wave", "happy"),
    StaticSpec(10, "onboarding", "nabi_onboarding_basic_info.png", "complete", "helpful"),
    StaticSpec(11, "onboarding", "nabi_onboarding_body_profile.png", "guide", "helpful"),
    StaticSpec(12, "onboarding", "nabi_onboarding_lifestyle.png", "listen", "attentive"),
    StaticSpec(13, "onboarding", "nabi_onboarding_goal.png", "guide", "helpful"),
    StaticSpec(14, "onboarding", "nabi_onboarding_health_check.png", "listen", "attentive"),
    StaticSpec(15, "onboarding", "nabi_onboarding_review.png", "complete", "helpful"),
    StaticSpec(16, "onboarding", "nabi_ai_generating_plan.png", "think", "thinking"),
    StaticSpec(17, "onboarding", "nabi_plan_ready.png", "complete", "happy"),
    StaticSpec(18, "chat", "nabi_chat_greet.png", "wave", "happy"),
    StaticSpec(19, "chat", "nabi_chat_listen.png", "listen", "attentive"),
    StaticSpec(20, "chat", "nabi_chat_typing.png", "complete", "thinking"),
    StaticSpec(21, "chat", "nabi_chat_reasoning.png", "think", "thinking"),
    StaticSpec(22, "chat", "nabi_chat_clarify.png", "listen", "curious"),
    StaticSpec(23, "chat", "nabi_chat_meal_tip.png", "food", "happy"),
    StaticSpec(24, "chat", "nabi_chat_exercise_tip.png", "run", "happy"),
    StaticSpec(25, "chat", "nabi_chat_rest_tip.png", "sleep", "calm"),
    StaticSpec(26, "chat", "nabi_chat_water_tip.png", "water", "happy"),
    StaticSpec(27, "chat", "nabi_chat_answer_ready.png", "guide", "helpful"),
    StaticSpec(28, "daily", "nabi_breakfast.png", "food", "happy"),
    StaticSpec(29, "daily", "nabi_lunch.png", "food", "happy"),
    StaticSpec(30, "daily", "nabi_dinner.png", "food", "calm"),
    StaticSpec(31, "daily", "nabi_healthy_snack.png", "food", "happy"),
    StaticSpec(32, "daily", "nabi_drink_water.png", "water", "happy"),
    StaticSpec(33, "daily", "nabi_exercise.png", "run", "happy"),
    StaticSpec(34, "daily", "nabi_walk.png", "run", "happy"),
    StaticSpec(35, "daily", "nabi_stretch.png", "encourage", "happy"),
    StaticSpec(36, "daily", "nabi_sleep.png", "sleep", "calm"),
    StaticSpec(37, "daily", "nabi_morning_checkin.png", "wave", "happy"),
    StaticSpec(38, "daily", "nabi_mood_checkin.png", "listen", "attentive"),
    StaticSpec(39, "daily", "nabi_body_measure.png", "guide", "helpful"),
    StaticSpec(40, "daily", "nabi_view_schedule.png", "complete", "helpful"),
    StaticSpec(41, "daily", "nabi_notification_reminder.png", "guide", "helpful"),
    StaticSpec(42, "progress", "nabi_task_complete.png", "complete", "happy"),
    StaticSpec(43, "progress", "nabi_task_skip_gentle.png", "apologize", "calm"),
    StaticSpec(44, "progress", "nabi_task_pending.png", "guide", "helpful"),
    StaticSpec(45, "progress", "nabi_day_complete.png", "celebrate", "happy"),
    StaticSpec(46, "progress", "nabi_streak_start.png", "encourage", "happy"),
    StaticSpec(47, "progress", "nabi_streak_7days.png", "celebrate", "happy"),
    StaticSpec(48, "progress", "nabi_milestone_badge.png", "encourage", "happy"),
    StaticSpec(49, "progress", "nabi_personal_best.png", "celebrate", "happy"),
    StaticSpec(50, "progress", "nabi_low_progress_encourage.png", "encourage", "encouraging"),
    StaticSpec(51, "progress", "nabi_missed_task_remind.png", "apologize", "calm"),
    StaticSpec(52, "progress", "nabi_thank_you.png", "apologize", "grateful"),
    StaticSpec(53, "progress", "nabi_proud_of_you.png", "encourage", "happy"),
    StaticSpec(54, "engagement", "nabi_new_user.png", "wave", "happy"),
    StaticSpec(55, "engagement", "nabi_occasional_user.png", "think", "curious"),
    StaticSpec(56, "engagement", "nabi_regular_user.png", "celebrate", "happy"),
    StaticSpec(57, "engagement", "nabi_daily_user.png", "complete", "helpful"),
    StaticSpec(58, "engagement", "nabi_away_1day.png", "wave", "calm"),
    StaticSpec(59, "engagement", "nabi_away_3days.png", "think", "calm"),
    StaticSpec(60, "engagement", "nabi_away_7days.png", "apologize", "calm"),
    StaticSpec(61, "engagement", "nabi_away_14days.png", "sleep", "calm"),
    StaticSpec(62, "engagement", "nabi_welcome_back.png", "wave", "happy"),
    StaticSpec(63, "engagement", "nabi_fresh_restart.png", "complete", "helpful"),
    StaticSpec(64, "system", "nabi_loading.png", "think", "thinking"),
    StaticSpec(65, "system", "nabi_empty_dashboard.png", "guide", "helpful"),
    StaticSpec(66, "system", "nabi_no_schedule.png", "complete", "helpful"),
    StaticSpec(67, "system", "nabi_offline.png", "listen", "calm"),
    StaticSpec(68, "system", "nabi_syncing.png", "think", "thinking"),
    StaticSpec(69, "system", "nabi_sync_success.png", "complete", "happy"),
    StaticSpec(70, "system", "nabi_sync_retry.png", "apologize", "calm"),
    StaticSpec(71, "system", "nabi_notification_permission.png", "guide", "helpful"),
    StaticSpec(72, "system", "nabi_login.png", "wave", "helpful"),
    StaticSpec(73, "system", "nabi_account_connected.png", "celebrate", "happy"),
    StaticSpec(74, "system", "nabi_access_locked.png", "listen", "calm"),
    StaticSpec(75, "future", "nabi_family_plan.png", "wave", "helpful"),
    StaticSpec(76, "future", "nabi_family_invite.png", "guide", "helpful"),
    StaticSpec(77, "future", "nabi_family_shared_progress.png", "celebrate", "happy"),
    StaticSpec(78, "future", "nabi_family_member_joined.png", "wave", "happy"),
    StaticSpec(79, "future", "nabi_premium_unlocked.png", "celebrate", "happy"),
    StaticSpec(80, "future", "nabi_referral_invite.png", "guide", "helpful"),
    StaticSpec(81, "future", "nabi_referral_success.png", "celebrate", "happy"),
    StaticSpec(82, "future", "nabi_sales_leaderboard.png", "guide", "helpful"),
    StaticSpec(83, "future", "nabi_sales_reward.png", "encourage", "happy"),
    StaticSpec(84, "future", "nabi_commission_success.png", "celebrate", "happy"),
)


# Legacy expression identifiers are kept as metadata.  Their v2 content is
# intentionally gentle: care, pause, empathy, rest, and calm boundaries.
EXPRESSION_SPECS: tuple[ExpressionSpec, ...] = (
    ExpressionSpec("NABI_EXP_001_happy", "nabi_exp_001_happy.png", "joyful_presence", "celebrate", "happy"),
    ExpressionSpec("NABI_EXP_002_happy_closed", "nabi_exp_002_happy_closed.png", "warm_reassurance", "complete", "happy"),
    ExpressionSpec("NABI_EXP_003_sad", "nabi_exp_003_sad.png", "caring_attention", "listen", "calm"),
    ExpressionSpec("NABI_EXP_004_pout", "nabi_exp_004_pout.png", "gentle_pause", "think", "calm"),
    ExpressionSpec("NABI_EXP_005_angry", "nabi_exp_005_angry.png", "calm_boundary", "guide", "helpful"),
    ExpressionSpec("NABI_EXP_006_cry", "nabi_exp_006_cry.png", "empathetic_presence", "listen", "attentive"),
    ExpressionSpec("NABI_EXP_007_sleepy", "nabi_exp_007_sleepy.png", "restful_reminder", "sleep", "calm"),
    ExpressionSpec("NABI_EXP_008_thinking", "nabi_exp_008_thinking.png", "thoughtful_support", "think", "thinking"),
    ExpressionSpec("NABI_EXP_009_surprised", "nabi_exp_009_surprised.png", "attentive_check_in", "listen", "curious"),
    ExpressionSpec("NABI_EXP_010_talking", "nabi_exp_010_talking.png", "soft_explanation", "guide", "helpful"),
)


# IDs and module grouping stay compatible with the legacy animation contract.
# ``gentle_semantic`` replaces the former emotional framing in v2 metadata.
ANIMATION_SPECS: tuple[AnimationSpec, ...] = (
    AnimationSpec("NABI_ANIM_001_happy_idle_breathing", "01_core", "calm_idle_breathing", "breathe"),
    AnimationSpec("NABI_ANIM_002_happy_wave_right", "01_core", "welcoming_wave", "wave"),
    AnimationSpec("NABI_ANIM_003_happy_jump_pop", "01_core", "light_upward_energy", "hop"),
    AnimationSpec("NABI_ANIM_004_happy_heart_send", "01_core", "care_send", "send"),
    AnimationSpec("NABI_ANIM_005_success_confetti_dance", "01_core", "quiet_celebration", "celebrate"),
    AnimationSpec("NABI_ANIM_006_sad_sigh_slow", "02_emotion", "care_pause", "care_breathe"),
    AnimationSpec("NABI_ANIM_007_sad_look_down", "02_emotion", "gentle_reflection", "care_lower"),
    AnimationSpec("NABI_ANIM_008_pout_cheek_turn", "02_emotion", "gentle_pause_turn", "gentle_turn"),
    AnimationSpec("NABI_ANIM_009_pout_cross_arm", "02_emotion", "calm_self_hold", "gentle_hold"),
    AnimationSpec("NABI_ANIM_010_angry_small_stomp", "02_emotion", "grounding_reset", "ground"),
    AnimationSpec("NABI_ANIM_011_angry_warning_shake", "02_emotion", "safety_reminder", "safety_sway"),
    AnimationSpec("NABI_ANIM_012_cry_big_tears", "02_emotion", "empathetic_stillness", "empathy"),
    AnimationSpec("NABI_ANIM_013_cry_rub_eye", "02_emotion", "self_care_touch", "self_care"),
    AnimationSpec("NABI_ANIM_014_sleepy_yawn", "02_emotion", "restful_pause", "rest"),
    AnimationSpec("NABI_ANIM_015_sleepy_reminder_nod", "03_daily", "gentle_reminder_nod", "reminder"),
    AnimationSpec("NABI_ANIM_016_thinking_bubble", "03_daily", "thoughtful_wait", "think"),
    AnimationSpec("NABI_ANIM_017_talking_soft", "03_daily", "soft_explanation", "talk"),
    AnimationSpec("NABI_ANIM_018_listening_ear_bounce", "03_daily", "active_listening", "listen"),
    AnimationSpec("NABI_ANIM_019_nod_yes", "03_daily", "affirming_nod", "nod"),
    AnimationSpec("NABI_ANIM_020_shake_no", "03_daily", "kind_boundary", "decline"),
    AnimationSpec("NABI_ANIM_021_loading_leaf_spin", "04_system", "patient_loading", "load"),
    AnimationSpec("NABI_ANIM_022_error_dizzy", "04_system", "calm_retry", "retry"),
    AnimationSpec("NABI_ANIM_023_meal_scan_food", "05_views", "meal_guidance", "meal"),
    AnimationSpec("NABI_ANIM_024_exercise_cheer", "05_views", "movement_encouragement", "cheer"),
    AnimationSpec("NABI_ANIM_025_profile_greeting", "05_views", "profile_greeting", "greet"),
    AnimationSpec("NABI_ANIM_026_membership_vip_sparkle", "05_views", "membership_welcome", "premium"),
    AnimationSpec("NABI_ANIM_027_critical_alert_guard", "05_views", "safety_guard", "guard"),
    AnimationSpec("NABI_ANIM_028_empty_state_peek", "05_views", "empty_state_invitation", "empty"),
    AnimationSpec("NABI_ANIM_029_onboarding_welcome", "05_views", "onboarding_welcome", "welcome"),
    AnimationSpec("NABI_ANIM_030_dashboard_morning", "05_views", "morning_check_in", "morning"),
)


EFFECT_SPECS: tuple[EffectSpec, ...] = (
    EffectSpec("NABI_EFFECT_heart_burst", "care_burst", "care_burst"),
    EffectSpec("NABI_EFFECT_sparkle_loop", "soft_sparkle", "sparkle"),
    EffectSpec("NABI_EFFECT_tear_drop", "care_drop", "care_drop"),
    EffectSpec("NABI_EFFECT_angry_steam", "calm_breath", "calm_breath"),
    EffectSpec("NABI_EFFECT_confetti", "leaf_celebration", "celebrate"),
    EffectSpec("NABI_EFFECT_warning_pulse", "safety_pulse", "safety"),
    EffectSpec("NABI_EFFECT_leaf_spinner", "leaf_orbit", "orbit"),
)


@dataclass(frozen=True)
class Transform:
    scale: float = 1.0
    rotation_degrees: float = 0.0
    offset_x: float = 0.0
    offset_y: float = 0.0
    flip: bool = False
    crop_zoom: float = 1.0


@dataclass(frozen=True)
class PlannedFile:
    root_name: str
    root: Path
    relative_path: Path

    @property
    def path(self) -> Path:
        return self.root / self.relative_path


@dataclass
class WriteSummary:
    created: list[str]
    overwritten: list[str]

    def record(self, label: str, overwrite: bool) -> None:
        (self.overwritten if overwrite else self.created).append(label)


def stable_unit(*parts: object) -> float:
    """Return a stable [0, 1) value independent of Python hash randomization."""

    payload = "|".join(str(part) for part in parts).encode("utf-8")
    return int.from_bytes(hashlib.sha256(payload).digest()[:8], "big") / 2**64


def ensure_lowercase(value: str, description: str) -> None:
    if value != value.lower():
        raise ToolError(f"{description} must be lowercase: {value}")


def validate_builtin_contract() -> None:
    if len(STATIC_SPECS) != 84:
        raise ToolError(f"Expected 84 static specs, found {len(STATIC_SPECS)}")
    if len(EXPRESSION_SPECS) != 10:
        raise ToolError(f"Expected 10 expression specs, found {len(EXPRESSION_SPECS)}")
    if len(ANIMATION_SPECS) != 30:
        raise ToolError(f"Expected 30 animation specs, found {len(ANIMATION_SPECS)}")
    if len(EFFECT_SPECS) != 7:
        raise ToolError(f"Expected 7 effect specs, found {len(EFFECT_SPECS)}")

    static_paths = [spec.relative_path.as_posix() for spec in STATIC_SPECS]
    expression_paths = [spec.relative_path.as_posix() for spec in EXPRESSION_SPECS]
    animation_ids = [spec.asset_id for spec in ANIMATION_SPECS]
    effect_ids = [spec.asset_id for spec in EFFECT_SPECS]
    for label, values in (
        ("static asset path", static_paths),
        ("expression path", expression_paths),
        ("animation id", animation_ids),
        ("effect id", effect_ids),
    ):
        if len(values) != len(set(values)):
            raise ToolError(f"Duplicate {label} in generator contract")
        for value in values:
            ensure_lowercase(value, label)
    if [spec.number for spec in STATIC_SPECS] != list(range(1, 85)):
        raise ToolError("Static state numbers must be exactly 1 through 84")


def resolved_path(value: Path) -> Path:
    return value.expanduser().resolve(strict=False)


def is_filesystem_root(path: Path) -> bool:
    return path == Path(path.anchor)


def require_output_root(path: Path, label: str) -> Path:
    resolved = resolved_path(path)
    if is_filesystem_root(resolved):
        raise ToolError(f"Refusing to use a filesystem root as --{label}: {resolved}")
    return resolved


def require_inside(root: Path, path: Path) -> None:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
    except ValueError as error:
        raise ToolError(f"Refusing write outside explicit output root: {path}") from error


def safe_relative(path: Path) -> str:
    return path.as_posix()


def image_alpha_summary(image: Image.Image) -> tuple[int, int, tuple[int, int, int, int] | None]:
    alpha = image.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    return alpha_min, alpha_max, alpha.getbbox()


def validate_master(
    master_path: Path,
    *,
    require_transparent_corners: bool = True,
) -> tuple[Image.Image, dict[str, object]]:
    if not master_path.exists() or not master_path.is_file():
        raise ToolError(f"Master PNG does not exist: {master_path}")
    try:
        with Image.open(master_path) as opened:
            if opened.format != "PNG":
                raise ToolError(f"Master must be a PNG, got {opened.format!r}: {master_path}")
            if opened.mode != "RGBA":
                raise ToolError(
                    f"Master must be RGBA with transparent pixels, got {opened.mode}: {master_path}"
                )
            image = opened.copy()
    except OSError as error:
        raise ToolError(f"Unable to read master PNG: {master_path}: {error}") from error

    alpha_min, alpha_max, bbox = image_alpha_summary(image)
    corners = (
        image.getchannel("A").getpixel((0, 0)),
        image.getchannel("A").getpixel((image.width - 1, 0)),
        image.getchannel("A").getpixel((0, image.height - 1)),
        image.getchannel("A").getpixel((image.width - 1, image.height - 1)),
    )
    if alpha_min != 0 or alpha_max != 255 or bbox is None:
        raise ToolError(
            "Master must contain both fully transparent and fully opaque pixels "
            f"(alpha range was {alpha_min}..{alpha_max})."
        )
    if require_transparent_corners and any(corner != 0 for corner in corners):
        raise ToolError(
            "Master must have transparent corners; remove the chroma-key background before generation."
        )

    digest = hashlib.sha256(master_path.read_bytes()).hexdigest()
    return image, {
        "filename": master_path.name,
        "sha256": digest,
        "source_size_px": {"width": image.width, "height": image.height},
        "alpha_range": {"min": alpha_min, "max": alpha_max},
        "content_bbox": {"left": bbox[0], "top": bbox[1], "right": bbox[2], "bottom": bbox[3]},
        "transparent_corners": all(corner == 0 for corner in corners),
    }


def subject_crop(master: Image.Image) -> Image.Image:
    bbox = master.getchannel("A").getbbox()
    if bbox is None:
        raise ToolError("Master has no visible subject after alpha validation")
    return master.crop(bbox)


def load_anchor_subjects(
    master_subject: Image.Image,
    anchors_root: Path | None,
) -> tuple[dict[str, Image.Image], list[dict[str, object]]]:
    """Load optional approved pose anchors without ever requiring them.

    The five known source names are intentionally small and explicit.  A
    caller can omit ``--anchors-root`` and still get the exact deterministic
    master-only bundle contract; passing an anchor directory improves semantic
    variety for thought, celebration, calm, and prompt-oriented variants.
    """

    subjects = {"master": master_subject}
    metadata: list[dict[str, object]] = []
    if anchors_root is None:
        return subjects, metadata
    if not anchors_root.exists() or not anchors_root.is_dir():
        raise ToolError(f"Anchors root does not exist or is not a directory: {anchors_root}")
    known_anchors = {
        "thinking": "nabi_v2_thinking.png",
        "celebrate": "nabi_v2_celebrate.png",
        "calm": "nabi_v2_calm.png",
        "prompt": "nabi_v2_prompt.png",
    }
    for semantic, filename in known_anchors.items():
        path = anchors_root / filename
        if not path.exists():
            continue
        image, image_metadata = validate_master(path, require_transparent_corners=False)
        subjects[semantic] = subject_crop(image)
        metadata.append({"semantic": semantic, **image_metadata})
    return subjects, metadata


def select_static_subject(
    spec: StaticSpec | ExpressionSpec,
    subjects: dict[str, Image.Image],
) -> Image.Image:
    if spec.pose == "think":
        semantic = "thinking"
    elif spec.pose in {"celebrate", "complete", "encourage", "run", "food", "water"}:
        semantic = "celebrate"
    elif spec.pose in {"listen", "sleep", "apologize"} or spec.expression == "calm":
        semantic = "calm"
    elif spec.pose == "guide":
        semantic = "prompt"
    else:
        semantic = "master"
    return subjects.get(semantic, subjects["master"])


def select_animation_subject(spec: AnimationSpec, subjects: dict[str, Image.Image]) -> Image.Image:
    profile = spec.motion_profile
    if profile in {"think", "care_breathe", "care_lower"}:
        semantic = "thinking"
    elif profile in {"hop", "cheer", "celebrate", "premium", "send", "meal"}:
        semantic = "celebrate"
    elif profile in {"gentle_turn", "gentle_hold", "ground", "safety_sway", "empathy", "self_care", "rest", "retry", "decline"}:
        semantic = "calm"
    elif profile in {"guard", "load", "reminder", "nod", "talk", "listen"}:
        semantic = "prompt"
    else:
        semantic = "master"
    return subjects.get(semantic, subjects["master"])


def select_effect_subject(spec: EffectSpec, subjects: dict[str, Image.Image]) -> Image.Image:
    if spec.motion_profile in {"care_burst", "celebrate", "sparkle"}:
        semantic = "celebrate"
    elif spec.motion_profile in {"calm_breath", "care_drop"}:
        semantic = "calm"
    elif spec.motion_profile == "safety":
        semantic = "prompt"
    else:
        semantic = "master"
    return subjects.get(semantic, subjects["master"])


def zoom_crop(image: Image.Image, zoom: float) -> Image.Image:
    """Create a subtle centered crop without ever returning a zero-size image."""

    if zoom <= 1.0:
        return image.copy()
    width = max(1, round(image.width / zoom))
    height = max(1, round(image.height / zoom))
    left = max(0, (image.width - width) // 2)
    top = max(0, (image.height - height) // 2)
    return image.crop((left, top, left + width, top + height))


def resize_contain(image: Image.Image, max_side: int) -> Image.Image:
    if max_side <= 0:
        raise ToolError(f"Invalid target max side: {max_side}")
    factor = min(max_side / image.width, max_side / image.height)
    size = (
        max(1, round(image.width * factor)),
        max(1, round(image.height * factor)),
    )
    return image.resize(size, RESAMPLING)


def render_character(subject: Image.Image, canvas_size: tuple[int, int], transform: Transform) -> Image.Image:
    """Render a trimmed master subject into a transparent, centered canvas."""

    canvas_width, canvas_height = canvas_size
    cropped = zoom_crop(subject, transform.crop_zoom)
    if transform.flip:
        cropped = ImageOps.mirror(cropped)
    target_side = max(1, round(min(canvas_size) * 0.76 * transform.scale))
    rendered = resize_contain(cropped, target_side)
    if abs(transform.rotation_degrees) > 0.001:
        rendered = rendered.rotate(
            transform.rotation_degrees,
            resample=BICUBIC,
            expand=True,
        )

    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    center_x = canvas_width / 2 + transform.offset_x
    # A slightly-low visual centre keeps a seed/leaf mascot visually grounded
    # while retaining generous transparent padding for Flutter layouts.
    center_y = canvas_height * 0.54 + transform.offset_y
    left = round(center_x - rendered.width / 2)
    top = round(center_y - rendered.height / 2)
    canvas.alpha_composite(rendered, (left, top))
    return canvas


POSE_BASES: dict[str, Transform] = {
    "wave": Transform(0.99, -1.3, 0.0, -1.0, False, 1.01),
    "celebrate": Transform(1.02, 0.0, 0.0, -4.0, False, 1.00),
    "guide": Transform(0.98, -1.8, 3.0, 0.0, False, 1.01),
    "listen": Transform(0.97, 2.2, -2.0, 1.0, False, 1.02),
    "think": Transform(0.96, -1.0, 0.0, 2.0, False, 1.03),
    "complete": Transform(1.00, 0.0, 0.0, -2.0, False, 1.00),
    "food": Transform(0.98, -1.0, 2.0, 0.0, False, 1.02),
    "run": Transform(1.00, -2.5, 1.0, -2.0, False, 1.02),
    "sleep": Transform(0.94, 1.8, -1.0, 3.0, False, 1.03),
    "water": Transform(0.98, 1.0, -2.0, 0.0, False, 1.02),
    "encourage": Transform(1.01, -0.8, 0.0, -2.0, False, 1.00),
    "apologize": Transform(0.95, 2.0, -1.0, 3.0, False, 1.03),
}


def static_transform(spec: StaticSpec | ExpressionSpec) -> Transform:
    base = POSE_BASES.get(spec.pose, Transform())
    identity = getattr(spec, "asset_id", getattr(spec, "filename", "nabi"))
    h0 = stable_unit(identity, "scale")
    h1 = stable_unit(identity, "rotation")
    h2 = stable_unit(identity, "offset-x")
    h3 = stable_unit(identity, "offset-y")
    h4 = stable_unit(identity, "flip")
    return Transform(
        scale=base.scale * (0.975 + h0 * 0.05),
        rotation_degrees=base.rotation_degrees + (h1 - 0.5) * 2.4,
        offset_x=base.offset_x + (h2 - 0.5) * 7.0,
        offset_y=base.offset_y + (h3 - 0.5) * 6.0,
        flip=base.flip ^ (h4 > 0.86),
        crop_zoom=base.crop_zoom + stable_unit(identity, "crop") * 0.022,
    )


def animation_phase(frame_index: int, loop: bool) -> float:
    if not 1 <= frame_index <= FRAME_COUNT:
        raise ToolError(f"Frame index must be 1..{FRAME_COUNT}, got {frame_index}")
    return (frame_index - 1) / (FRAME_COUNT if loop else FRAME_COUNT - 1)


def animation_transform(spec: AnimationSpec, frame_index: int) -> Transform:
    """Return a deterministic transform for a 30 fps frame.

    The profiles are intentionally restrained: reduced-motion renderers may use
    frame 1 without losing subject identity, and no profile produces aggressive
    shaking or punitive emotional motion.
    """

    phase = animation_phase(frame_index, spec.loop)
    wave = math.sin(math.tau * phase)
    cosine = math.cos(math.tau * phase)
    pulse = (wave + 1.0) / 2.0
    h = stable_unit(spec.asset_id, "animation")
    scale = 0.985
    rotation = (h - 0.5) * 1.2
    dx = 0.0
    dy = 0.0
    crop_zoom = 1.015
    profile = spec.motion_profile

    if profile in {"breathe", "care_breathe", "think", "load", "morning"}:
        scale += wave * 0.018
        dy = -wave * 3.0
    elif profile in {"wave", "welcome", "greet"}:
        rotation += wave * 4.0
        dx = wave * 4.0
        dy = -pulse * 2.0
    elif profile in {"hop", "cheer", "celebrate", "premium"}:
        arc = math.sin(math.pi * phase)
        scale += arc * 0.042
        dy = -arc * 18.0
        rotation += wave * 2.1
    elif profile in {"send", "meal"}:
        dx = (phase - 0.5) * 12.0
        rotation += wave * 2.4
        scale += pulse * 0.018
    elif profile in {"care_lower", "rest", "empathy", "self_care"}:
        dy = pulse * 7.0
        rotation += pulse * 2.4
        scale -= pulse * 0.025
    elif profile in {"gentle_turn", "gentle_hold"}:
        rotation += wave * 3.0
        dx = wave * 5.0
        scale -= pulse * 0.012
    elif profile in {"ground", "safety_sway", "guard", "retry"}:
        # Intentionally small, slow safety cue rather than a harsh shake.
        rotation += math.sin(math.tau * phase * 0.5) * 2.2
        dx = math.sin(math.tau * phase * 0.5) * 3.0
        dy = pulse * 1.5
    elif profile in {"reminder", "nod"}:
        dy = abs(math.sin(math.tau * phase)) * 7.0 - 3.5
        rotation += abs(math.sin(math.tau * phase)) * 1.3
    elif profile in {"listen", "talk", "decline"}:
        rotation += wave * (1.8 if profile != "decline" else 2.8)
        dx = wave * (2.5 if profile != "decline" else 4.0)
        scale += pulse * 0.01
    elif profile in {"empty"}:
        dx = (pulse - 0.5) * 7.0
        dy = pulse * 4.0
        scale -= (1.0 - pulse) * 0.02
    else:  # Defensive fallback if a future profile is added incorrectly.
        scale += wave * 0.01

    return Transform(
        scale=scale,
        rotation_degrees=rotation,
        offset_x=dx,
        offset_y=dy,
        flip=False,
        crop_zoom=crop_zoom + stable_unit(spec.asset_id, frame_index, "crop") * 0.012,
    )


def crop_effect_element(subject: Image.Image, variant: str) -> Image.Image:
    """Extract a visible, alpha-bearing detail from the master for effects."""

    width, height = subject.size
    # A plant character normally carries useful leaf detail in its upper half.
    # If a particular approved master does not, the alpha fallback below keeps
    # the effect visible while still deriving it entirely from the master.
    if variant == "upper":
        box = (round(width * 0.18), round(height * 0.02), round(width * 0.82), round(height * 0.48))
    elif variant == "lower":
        box = (round(width * 0.22), round(height * 0.38), round(width * 0.78), round(height * 0.94))
    else:
        box = (round(width * 0.14), round(height * 0.14), round(width * 0.86), round(height * 0.86))
    element = subject.crop(box)
    _, alpha_max, bbox = image_alpha_summary(element)
    if bbox is None or alpha_max < 255:
        return subject.copy()
    return element.crop(bbox)


def with_opacity(image: Image.Image, opacity: float) -> Image.Image:
    opacity = max(0.0, min(1.0, opacity))
    if opacity >= 0.999:
        return image.copy()
    result = image.copy()
    alpha = result.getchannel("A")
    alpha = alpha.point(lambda value: round(value * opacity))
    result.putalpha(alpha)
    return result


def paste_transformed(
    canvas: Image.Image,
    element: Image.Image,
    *,
    center_x: float,
    center_y: float,
    max_side: int,
    rotation_degrees: float = 0.0,
    opacity: float = 1.0,
) -> None:
    rendered = resize_contain(element, max(1, max_side))
    if abs(rotation_degrees) > 0.001:
        rendered = rendered.rotate(rotation_degrees, resample=BICUBIC, expand=True)
    rendered = with_opacity(rendered, opacity)
    canvas.alpha_composite(
        rendered,
        (round(center_x - rendered.width / 2), round(center_y - rendered.height / 2)),
    )


def render_effect(subject: Image.Image, spec: EffectSpec, frame_index: int) -> Image.Image:
    """Render a transparent effect made solely from transformed master crops."""

    phase = animation_phase(frame_index, True)
    canvas = Image.new("RGBA", EFFECT_CANVAS, (0, 0, 0, 0))
    upper = crop_effect_element(subject, "upper")
    lower = crop_effect_element(subject, "lower")
    pulse = (math.sin(math.tau * phase) + 1.0) / 2.0
    profile = spec.motion_profile

    if profile == "care_burst":
        for index, angle in enumerate((math.radians(-90), math.radians(30), math.radians(150))):
            radius = 20.0 + 46.0 * phase
            paste_transformed(
                canvas,
                upper,
                center_x=128 + math.cos(angle) * radius,
                center_y=128 + math.sin(angle) * radius,
                max_side=22 + round(12 * pulse),
                rotation_degrees=math.degrees(angle) + phase * 60 + index * 22,
                # Keep a fully opaque source detail in every frame so the
                # transparent-PNG contract remains objectively verifiable.
                opacity=1.0,
            )
    elif profile == "sparkle":
        for index in range(4):
            angle = math.tau * (phase + index / 4)
            paste_transformed(
                canvas,
                upper,
                center_x=128 + math.cos(angle) * 53,
                center_y=128 + math.sin(angle) * 53,
                max_side=15 + round(13 * pulse),
                rotation_degrees=phase * 360 + index * 90,
                opacity=1.0,
            )
    elif profile == "care_drop":
        y = 54 + phase * 142
        paste_transformed(
            canvas,
            lower,
            center_x=128 + math.sin(math.tau * phase) * 12,
            center_y=y,
            max_side=30 + round(10 * pulse),
            rotation_degrees=phase * 28,
            opacity=1.0,
        )
    elif profile == "calm_breath":
        for direction in (-1, 1):
            paste_transformed(
                canvas,
                upper,
                center_x=128 + direction * (18 + phase * 50),
                center_y=130 - math.sin(math.pi * phase) * 25,
                max_side=30 + round(9 * pulse),
                rotation_degrees=direction * (18 + phase * 32),
                opacity=1.0,
            )
    elif profile == "celebrate":
        for index in range(5):
            offset = stable_unit(spec.asset_id, index, "effect")
            x = 25 + ((phase * 170 + offset * 170) % 180)
            y = 24 + ((phase * 135 + index * 31) % 175)
            paste_transformed(
                canvas,
                upper if index % 2 == 0 else lower,
                center_x=x,
                center_y=y,
                max_side=16 + (index % 3) * 6,
                rotation_degrees=phase * 360 + index * 71,
                opacity=1.0,
            )
    elif profile == "safety":
        for index in range(3):
            radius = 26 + index * 23 + pulse * 8
            angle = math.tau * (phase * 0.35 + index / 3)
            paste_transformed(
                canvas,
                upper,
                center_x=128 + math.cos(angle) * radius,
                center_y=128 + math.sin(angle) * radius,
                max_side=21 + round(pulse * 8),
                rotation_degrees=math.degrees(angle),
                opacity=1.0,
            )
    elif profile == "orbit":
        angle = math.tau * phase
        paste_transformed(
            canvas,
            upper,
            center_x=128 + math.cos(angle) * 64,
            center_y=128 + math.sin(angle) * 48,
            max_side=38,
            rotation_degrees=phase * 360,
            opacity=1.0,
        )
    else:  # pragma: no cover - protected by the built-in contract.
        raise ToolError(f"Unknown effect profile: {profile}")

    return canvas


def frame_filename(frame_index: int) -> str:
    return f"frame_{frame_index:04d}.png"


def all_preview_paths() -> tuple[Path, ...]:
    preview_root = Path("07_previews")
    return (
        preview_root / "nabi_v2_static_contact_sheet.png",
        preview_root / "nabi_v2_expression_contact_sheet.png",
        preview_root / "nabi_v2_animation_keyframes_contact_sheet.png",
        preview_root / "nabi_v2_effect_keyframes_contact_sheet.png",
    )


def all_catalog_paths() -> tuple[Path, ...]:
    return (
        Path("nabi_v2_catalog.json"),
        Path("nabi_v2_asset_manifest.json"),
        Path("nabi_v2_state_matrix.json"),
        Path("nabi_v2_expression_map.json"),
        Path("nabi_v2_motion_map.json"),
        Path("nabi_v2_generation_report.json"),
    )


def plan_files(static_root: Path, sprite_root: Path, catalog_root: Path) -> list[PlannedFile]:
    plans: list[PlannedFile] = []
    plans.extend(
        PlannedFile("static", static_root, spec.relative_path) for spec in STATIC_SPECS
    )
    plans.extend(
        PlannedFile("sprite", sprite_root, spec.relative_path) for spec in EXPRESSION_SPECS
    )
    for spec in ANIMATION_SPECS:
        plans.extend(
            PlannedFile("sprite", sprite_root, spec.frames_relative_dir / frame_filename(index))
            for index in range(1, FRAME_COUNT + 1)
        )
        plans.append(PlannedFile("sprite", sprite_root, spec.spritesheet_relative_path))
    for spec in EFFECT_SPECS:
        plans.extend(
            PlannedFile("sprite", sprite_root, spec.frames_relative_dir / frame_filename(index))
            for index in range(1, FRAME_COUNT + 1)
        )
        plans.append(PlannedFile("sprite", sprite_root, spec.spritesheet_relative_path))
    plans.extend(PlannedFile("sprite", sprite_root, path) for path in all_preview_paths())
    plans.extend(PlannedFile("catalog", catalog_root, path) for path in all_catalog_paths())
    return plans


def assert_no_unintended_overwrite(plans: Sequence[PlannedFile], overwrite: bool) -> None:
    duplicate_paths: list[str] = []
    seen: set[Path] = set()
    existing: list[str] = []
    for plan in plans:
        require_inside(plan.root, plan.path)
        path = plan.path.resolve(strict=False)
        if path in seen:
            duplicate_paths.append(str(path))
        seen.add(path)
        if path.exists():
            existing.append(str(path))
    if duplicate_paths:
        raise ToolError("Generator contract has duplicate output paths: " + ", ".join(duplicate_paths[:3]))
    if existing and not overwrite:
        sample = "\n".join(f"  - {path}" for path in existing[:12])
        more = "" if len(existing) <= 12 else f"\n  ... and {len(existing) - 12} more"
        raise ToolError(
            "Refusing to overwrite existing Nabi v2 outputs. Re-run with --overwrite "
            "only after reviewing these planned targets:\n"
            f"{sample}{more}"
        )


def make_scaffold(sprite_root: Path) -> None:
    """Create empty conventional directories without touching files outside root."""

    directories = (
        Path("00_master"),
        Path("01_character") / "01_static_expressions",
        Path("01_character") / "02_30fps_frames",
        Path("02_spritesheets"),
        Path("03_effects") / "01_png_frames",
        Path("03_effects") / "02_spritesheets",
        Path("04_audio") / "sfx",
        Path("05_flutter_integration"),
        Path("06_manifest"),
        Path("07_previews"),
        Path("08_docs"),
    )
    for relative in directories:
        target = sprite_root / relative
        require_inside(sprite_root, target)
        target.mkdir(parents=True, exist_ok=True)


def atomic_save_png(image: Image.Image, root: Path, relative: Path, summary: WriteSummary) -> None:
    ensure_lowercase(relative.as_posix(), "output PNG path")
    target = root / relative
    require_inside(root, target)
    target.parent.mkdir(parents=True, exist_ok=True)
    existed = target.exists()
    with tempfile.NamedTemporaryFile(
        mode="wb", suffix=".png", prefix=f".{target.stem}.", dir=target.parent, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
    try:
        image.save(temporary_path, format="PNG", optimize=True)
        os.replace(temporary_path, target)
    finally:
        temporary_path.unlink(missing_ok=True)
    summary.record(f"{root.name}/{relative.as_posix()}", existed)


def atomic_save_json(payload: object, root: Path, relative: Path, summary: WriteSummary) -> None:
    ensure_lowercase(relative.as_posix(), "output JSON path")
    target = root / relative
    require_inside(root, target)
    target.parent.mkdir(parents=True, exist_ok=True)
    existed = target.exists()
    encoded = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", suffix=".json", prefix=f".{target.stem}.", dir=target.parent, delete=False
    ) as temporary:
        temporary.write(encoded)
        temporary_path = Path(temporary.name)
    try:
        os.replace(temporary_path, target)
    finally:
        temporary_path.unlink(missing_ok=True)
    summary.record(f"{root.name}/{relative.as_posix()}", existed)


def load_rgba(path: Path) -> Image.Image:
    try:
        with Image.open(path) as opened:
            if opened.format != "PNG" or opened.mode != "RGBA":
                raise ToolError(f"Expected RGBA PNG at {path}, got {opened.format}/{opened.mode}")
            return opened.copy()
    except OSError as error:
        raise ToolError(f"Unable to read generated PNG: {path}: {error}") from error


def build_spritesheet(
    frame_paths: Sequence[Path],
    frame_size: tuple[int, int],
    columns: int = SPRITESHEET_COLUMNS,
) -> Image.Image:
    if len(frame_paths) != FRAME_COUNT:
        raise ToolError(f"Spritesheet needs {FRAME_COUNT} frames, got {len(frame_paths)}")
    rows = math.ceil(len(frame_paths) / columns)
    sheet = Image.new(
        "RGBA",
        (frame_size[0] * columns, frame_size[1] * rows),
        (0, 0, 0, 0),
    )
    for index, path in enumerate(frame_paths):
        frame = load_rgba(path)
        if frame.size != frame_size:
            raise ToolError(f"Unexpected frame dimensions while building spritesheet: {path}: {frame.size}")
        sheet.alpha_composite(
            frame,
            ((index % columns) * frame_size[0], (index // columns) * frame_size[1]),
        )
    return sheet


def centered_thumbnail(image: Image.Image, cell_size: int) -> Image.Image:
    thumbnail = image.copy()
    thumbnail.thumbnail((cell_size, cell_size), RESAMPLING)
    cell = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
    cell.alpha_composite(
        thumbnail,
        ((cell_size - thumbnail.width) // 2, (cell_size - thumbnail.height) // 2),
    )
    return cell


def build_contact_sheet(paths: Sequence[Path], *, columns: int, cell_size: int) -> Image.Image:
    if not paths:
        raise ToolError("Cannot build an empty contact sheet")
    rows = math.ceil(len(paths) / columns)
    sheet = Image.new("RGBA", (columns * cell_size, rows * cell_size), (0, 0, 0, 0))
    for index, path in enumerate(paths):
        sheet.alpha_composite(
            centered_thumbnail(load_rgba(path), cell_size),
            ((index % columns) * cell_size, (index // columns) * cell_size),
        )
    return sheet


def static_manifest_entries() -> list[dict[str, object]]:
    return [
        {
            "id": spec.asset_id,
            "number": spec.number,
            "category": spec.category,
            "filename": spec.filename,
            "path": spec.relative_path.as_posix(),
            "pose": spec.pose,
            "expression": spec.expression,
            "size_px": {"width": STATIC_CANVAS[0], "height": STATIC_CANVAS[1]},
        }
        for spec in STATIC_SPECS
    ]


def expression_entries() -> list[dict[str, object]]:
    return [
        {
            "id": spec.asset_id,
            "legacy_id": spec.legacy_id,
            "path": spec.relative_path.as_posix(),
            "gentle_semantic": spec.gentle_semantic,
            "pose": spec.pose,
            "expression": spec.expression,
            "size_px": {"width": EXPRESSION_CANVAS[0], "height": EXPRESSION_CANVAS[1]},
        }
        for spec in EXPRESSION_SPECS
    ]


def animation_entries() -> list[dict[str, object]]:
    return [
        {
            "id": spec.asset_id,
            "legacy_id": spec.legacy_id,
            "module": spec.module,
            "gentle_semantic": spec.gentle_semantic,
            "motion_profile": spec.motion_profile,
            "loop": spec.loop,
            "fps": 30,
            "frame_count": FRAME_COUNT,
            "frame_size_px": {"width": FRAME_CANVAS[0], "height": FRAME_CANVAS[1]},
            "frames_path": spec.frames_relative_dir.as_posix(),
            "frame_pattern": "frame_%04d.png",
            "spritesheet": spec.spritesheet_relative_path.as_posix(),
            "spritesheet_columns": SPRITESHEET_COLUMNS,
        }
        for spec in ANIMATION_SPECS
    ]


def effect_entries() -> list[dict[str, object]]:
    return [
        {
            "id": spec.asset_id,
            "legacy_id": spec.legacy_id,
            "gentle_semantic": spec.gentle_semantic,
            "motion_profile": spec.motion_profile,
            "fps": 30,
            "frame_count": FRAME_COUNT,
            "frame_size_px": {"width": EFFECT_CANVAS[0], "height": EFFECT_CANVAS[1]},
            "frames_path": spec.frames_relative_dir.as_posix(),
            "frame_pattern": "frame_%04d.png",
            "spritesheet": spec.spritesheet_relative_path.as_posix(),
            "spritesheet_columns": SPRITESHEET_COLUMNS,
        }
        for spec in EFFECT_SPECS
    ]


def catalog_documents(master_metadata: dict[str, object]) -> dict[Path, object]:
    static_entries = static_manifest_entries()
    expressions = expression_entries()
    animations = animation_entries()
    effects = effect_entries()
    contract = {
        "schema_version": "nabi-v2-assets-1.0",
        "generator": {"name": "generate_nabi_v2_assets.py", "version": TOOL_VERSION},
        "character": {
            "id": "nabi_v2",
            "description": "gender-neutral botanical seed spirit; derived from an approved master",
        },
        "asset_contract": {
            "format": "png",
            "color_model": "rgba",
            "transparent_background": True,
            "static_canvas_px": STATIC_CANVAS[0],
            "expression_canvas_px": EXPRESSION_CANVAS[0],
            "character_frame_canvas_px": FRAME_CANVAS[0],
            "effect_frame_canvas_px": EFFECT_CANVAS[0],
            "fps": 30,
            "frames_per_sequence": FRAME_COUNT,
            "physical_paths_lowercase": True,
        },
        "master": master_metadata,
    }
    return {
        Path("nabi_v2_asset_manifest.json"): {
            **contract,
            "assets": static_entries,
        },
        Path("nabi_v2_state_matrix.json"): {
            **contract,
            "states": [
                {
                    "state_id": entry["id"],
                    "asset_path": entry["path"],
                    "category": entry["category"],
                    "pose": entry["pose"],
                    "expression": entry["expression"],
                    "fallback_expression_id": expressions[(entry["number"] - 1) % len(expressions)]["id"],
                }
                for entry in static_entries
            ],
        },
        Path("nabi_v2_expression_map.json"): {
            **contract,
            "expressions": expressions,
        },
        Path("nabi_v2_motion_map.json"): {
            **contract,
            "animations": animations,
            "effects": effects,
        },
        Path("nabi_v2_catalog.json"): {
            **contract,
            "static_asset_manifest": "nabi_v2_asset_manifest.json",
            "state_matrix": "nabi_v2_state_matrix.json",
            "expression_map": "nabi_v2_expression_map.json",
            "motion_map": "nabi_v2_motion_map.json",
            "counts": {
                "static_states": len(static_entries),
                "legacy_fallback_expressions": len(expressions),
                "animations": len(animations),
                "character_frames": len(animations) * FRAME_COUNT,
                "effects": len(effects),
                "effect_frames": len(effects) * FRAME_COUNT,
            },
        },
    }


def png_validation_error(path: Path, expected_size: tuple[int, int]) -> str | None:
    if not path.exists():
        return "missing"
    try:
        with Image.open(path) as opened:
            if opened.format != "PNG":
                return f"expected PNG, got {opened.format}"
            if opened.mode != "RGBA":
                return f"expected RGBA, got {opened.mode}"
            if opened.size != expected_size:
                return f"expected {expected_size[0]}x{expected_size[1]}, got {opened.size[0]}x{opened.size[1]}"
            alpha = opened.getchannel("A")
            alpha_min, alpha_max = alpha.getextrema()
            if alpha_min != 0 or alpha_max != 255:
                return f"expected alpha range 0..255, got {alpha_min}..{alpha_max}"
            if alpha.getbbox() is None:
                return "fully transparent"
    except OSError as error:
        return f"unreadable PNG: {error}"
    return None


def expected_spritesheet_size(frame_size: tuple[int, int]) -> tuple[int, int]:
    return (
        frame_size[0] * SPRITESHEET_COLUMNS,
        frame_size[1] * math.ceil(FRAME_COUNT / SPRITESHEET_COLUMNS),
    )


def validate_bundle(static_root: Path, sprite_root: Path, catalog_root: Path) -> list[str]:
    """Return every exact-contract validation failure without mutating files."""

    failures: list[str] = []
    for spec in STATIC_SPECS:
        path = static_root / spec.relative_path
        failure = png_validation_error(path, STATIC_CANVAS)
        if failure:
            failures.append(f"static {spec.relative_path.as_posix()}: {failure}")
    for spec in EXPRESSION_SPECS:
        path = sprite_root / spec.relative_path
        failure = png_validation_error(path, EXPRESSION_CANVAS)
        if failure:
            failures.append(f"expression {spec.relative_path.as_posix()}: {failure}")
    for spec in ANIMATION_SPECS:
        frame_dir = sprite_root / spec.frames_relative_dir
        expected = {frame_filename(index) for index in range(1, FRAME_COUNT + 1)}
        found = {path.name for path in frame_dir.glob("frame_*.png")} if frame_dir.exists() else set()
        if found != expected:
            failures.append(
                f"animation {spec.asset_id}: expected exactly {FRAME_COUNT} frame files, found {len(found)}"
            )
        for frame_name in sorted(expected):
            failure = png_validation_error(frame_dir / frame_name, FRAME_CANVAS)
            if failure:
                failures.append(f"animation {spec.asset_id}/{frame_name}: {failure}")
        failure = png_validation_error(
            sprite_root / spec.spritesheet_relative_path,
            expected_spritesheet_size(FRAME_CANVAS),
        )
        if failure:
            failures.append(f"spritesheet {spec.asset_id}: {failure}")
    for spec in EFFECT_SPECS:
        frame_dir = sprite_root / spec.frames_relative_dir
        expected = {frame_filename(index) for index in range(1, FRAME_COUNT + 1)}
        found = {path.name for path in frame_dir.glob("frame_*.png")} if frame_dir.exists() else set()
        if found != expected:
            failures.append(
                f"effect {spec.asset_id}: expected exactly {FRAME_COUNT} frame files, found {len(found)}"
            )
        for frame_name in sorted(expected):
            failure = png_validation_error(frame_dir / frame_name, EFFECT_CANVAS)
            if failure:
                failures.append(f"effect {spec.asset_id}/{frame_name}: {failure}")
        failure = png_validation_error(
            sprite_root / spec.spritesheet_relative_path,
            expected_spritesheet_size(EFFECT_CANVAS),
        )
        if failure:
            failures.append(f"effect spritesheet {spec.asset_id}: {failure}")
    for preview in all_preview_paths():
        failure = png_validation_error(sprite_root / preview, (1, 1))
        # Contact sheets intentionally have varying dimensions, so perform the
        # shared format/alpha validation above without imposing a fixed size.
        if failure and not failure.startswith("expected 1x1"):
            failures.append(f"preview {preview.as_posix()}: {failure}")
        elif (sprite_root / preview).exists():
            try:
                with Image.open(sprite_root / preview) as opened:
                    alpha_min, alpha_max = opened.getchannel("A").getextrema()
                    if opened.format != "PNG" or opened.mode != "RGBA" or alpha_min != 0 or alpha_max != 255:
                        failures.append(f"preview {preview.as_posix()}: invalid RGBA/alpha contract")
            except OSError as error:
                failures.append(f"preview {preview.as_posix()}: unreadable PNG: {error}")
    for catalog_path in all_catalog_paths():
        path = catalog_root / catalog_path
        if not path.exists():
            failures.append(f"catalog {catalog_path.as_posix()}: missing")
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            failures.append(f"catalog {catalog_path.as_posix()}: invalid JSON: {error}")
    return failures


def generate_bundle(
    *,
    master_path: Path,
    anchors_root: Path | None,
    static_root: Path,
    sprite_root: Path,
    catalog_root: Path,
    overwrite: bool,
) -> WriteSummary:
    validate_builtin_contract()
    master, master_metadata = validate_master(master_path)
    subjects, anchor_metadata = load_anchor_subjects(subject_crop(master), anchors_root)
    master_metadata["approved_pose_anchors"] = anchor_metadata
    plans = plan_files(static_root, sprite_root, catalog_root)
    assert_no_unintended_overwrite(plans, overwrite)

    # Create only directories beneath user-supplied roots.  Preflight happens
    # before this so a collision cannot leave an incomplete generated bundle.
    static_root.mkdir(parents=True, exist_ok=True)
    sprite_root.mkdir(parents=True, exist_ok=True)
    catalog_root.mkdir(parents=True, exist_ok=True)
    make_scaffold(sprite_root)
    summary = WriteSummary(created=[], overwritten=[])

    for spec in STATIC_SPECS:
        image = render_character(
            select_static_subject(spec, subjects),
            STATIC_CANVAS,
            static_transform(spec),
        )
        atomic_save_png(image, static_root, spec.relative_path, summary)
    for spec in EXPRESSION_SPECS:
        image = render_character(
            select_static_subject(spec, subjects),
            EXPRESSION_CANVAS,
            static_transform(spec),
        )
        atomic_save_png(image, sprite_root, spec.relative_path, summary)

    animation_frame_paths: dict[str, list[Path]] = {}
    for spec in ANIMATION_SPECS:
        paths: list[Path] = []
        for frame_index in range(1, FRAME_COUNT + 1):
            relative = spec.frames_relative_dir / frame_filename(frame_index)
            image = render_character(
                select_animation_subject(spec, subjects),
                FRAME_CANVAS,
                animation_transform(spec, frame_index),
            )
            atomic_save_png(image, sprite_root, relative, summary)
            paths.append(sprite_root / relative)
        animation_frame_paths[spec.asset_id] = paths
        atomic_save_png(
            build_spritesheet(paths, FRAME_CANVAS),
            sprite_root,
            spec.spritesheet_relative_path,
            summary,
        )

    effect_frame_paths: dict[str, list[Path]] = {}
    for spec in EFFECT_SPECS:
        paths = []
        for frame_index in range(1, FRAME_COUNT + 1):
            relative = spec.frames_relative_dir / frame_filename(frame_index)
            atomic_save_png(
                render_effect(select_effect_subject(spec, subjects), spec, frame_index),
                sprite_root,
                relative,
                summary,
            )
            paths.append(sprite_root / relative)
        effect_frame_paths[spec.asset_id] = paths
        atomic_save_png(
            build_spritesheet(paths, EFFECT_CANVAS),
            sprite_root,
            spec.spritesheet_relative_path,
            summary,
        )

    static_paths = [static_root / spec.relative_path for spec in STATIC_SPECS]
    expression_paths = [sprite_root / spec.relative_path for spec in EXPRESSION_SPECS]
    animation_keyframes = [
        animation_frame_paths[spec.asset_id][frame_index]
        for spec in ANIMATION_SPECS
        for frame_index in (0, FRAME_COUNT // 2, FRAME_COUNT - 1)
    ]
    effect_keyframes = [
        effect_frame_paths[spec.asset_id][frame_index]
        for spec in EFFECT_SPECS
        for frame_index in (0, 9, 19, FRAME_COUNT - 1)
    ]
    for relative, sheet in (
        (all_preview_paths()[0], build_contact_sheet(static_paths, columns=12, cell_size=128)),
        (all_preview_paths()[1], build_contact_sheet(expression_paths, columns=5, cell_size=192)),
        (all_preview_paths()[2], build_contact_sheet(animation_keyframes, columns=15, cell_size=96)),
        (all_preview_paths()[3], build_contact_sheet(effect_keyframes, columns=7, cell_size=128)),
    ):
        atomic_save_png(sheet, sprite_root, relative, summary)

    documents = catalog_documents(master_metadata)
    report = {
        "schema_version": "nabi-v2-assets-1.0",
        "generator": {"name": "generate_nabi_v2_assets.py", "version": TOOL_VERSION},
        "master": master_metadata,
        "derivation": {
            "deterministic": True,
            "operations": ["alpha_crop", "contain_resize", "mirror", "rotate", "translate", "compose"],
            "note": "Derivative scaffold assets; replace approved semantic poses individually when art direction requires it.",
        },
        "counts": {
            "static_states": len(STATIC_SPECS),
            "legacy_fallback_expressions": len(EXPRESSION_SPECS),
            "animation_sequences": len(ANIMATION_SPECS),
            "character_frames": len(ANIMATION_SPECS) * FRAME_COUNT,
            "effect_sequences": len(EFFECT_SPECS),
            "effect_frames": len(EFFECT_SPECS) * FRAME_COUNT,
            "character_spritesheets": len(ANIMATION_SPECS),
            "effect_spritesheets": len(EFFECT_SPECS),
            "contact_sheets": len(all_preview_paths()),
        },
        "roots": {
            "static_contract": "<static-root>",
            "sprite_contract": "<sprite-root>",
            "catalog_contract": "<catalog-root>",
        },
    }
    documents[Path("nabi_v2_generation_report.json")] = report
    for relative in all_catalog_paths():
        atomic_save_json(documents[relative], catalog_root, relative, summary)

    failures = validate_bundle(static_root, sprite_root, catalog_root)
    if failures:
        preview = "\n".join(f"  - {failure}" for failure in failures[:20])
        more = "" if len(failures) <= 20 else f"\n  ... and {len(failures) - 20} more"
        raise ToolError(f"Generated bundle failed validation:\n{preview}{more}")
    return summary


def parse_roots(args: argparse.Namespace) -> tuple[Path, Path, Path]:
    static_root = require_output_root(Path(args.static_root), "static-root")
    sprite_root = require_output_root(Path(args.sprite_root), "sprite-root")
    if static_root == sprite_root:
        raise ToolError("--static-root and --sprite-root must be different directories")
    if args.catalog_root:
        catalog_root = require_output_root(Path(args.catalog_root), "catalog-root")
    else:
        catalog_root = static_root / "catalog"
        require_inside(static_root, catalog_root)
    return static_root, sprite_root, catalog_root


def print_summary(summary: WriteSummary) -> None:
    print("Nabi v2 asset bundle generated and validated.")
    print(f"- Created files: {len(summary.created)}")
    print(f"- Overwritten files: {len(summary.overwritten)}")
    if summary.created:
        print("- First created paths:")
        for path in summary.created[:12]:
            print(f"  - {path}")
        if len(summary.created) > 12:
            print(f"  ... and {len(summary.created) - 12} more")


def command_generate(args: argparse.Namespace) -> int:
    static_root, sprite_root, catalog_root = parse_roots(args)
    summary = generate_bundle(
        master_path=resolved_path(Path(args.master)),
        anchors_root=resolved_path(Path(args.anchors_root)) if args.anchors_root else None,
        static_root=static_root,
        sprite_root=sprite_root,
        catalog_root=catalog_root,
        overwrite=args.overwrite,
    )
    print_summary(summary)
    return 0


def command_validate(args: argparse.Namespace) -> int:
    validate_builtin_contract()
    static_root, sprite_root, catalog_root = parse_roots(args)
    failures = validate_bundle(static_root, sprite_root, catalog_root)
    if failures:
        print("Nabi v2 asset validation: FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("Nabi v2 asset validation: PASS")
    print(f"- Static states: {len(STATIC_SPECS)}")
    print(f"- Expressions: {len(EXPRESSION_SPECS)}")
    print(f"- Character frames: {len(ANIMATION_SPECS) * FRAME_COUNT}")
    print(f"- Effect frames: {len(EFFECT_SPECS) * FRAME_COUNT}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate and validate deterministic transparent Nabi v2 assets.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    def add_roots(command: argparse.ArgumentParser) -> None:
        command.add_argument(
            "--static-root",
            required=True,
            help="Explicit root for 84 runtime static assets (for example assets/images/nabi_v2).",
        )
        command.add_argument(
            "--sprite-root",
            required=True,
            help="Explicit root for expressions, frames, spritesheets, effects, and previews (for example assets/nabi_v2).",
        )
        command.add_argument(
            "--catalog-root",
            help="Explicit root for generated v2 JSON catalogs; defaults to <static-root>/catalog.",
        )

    generate = subcommands.add_parser("generate", help="Generate a full v2 bundle from a validated master PNG.")
    generate.add_argument("--master", required=True, help="Approved transparent RGBA Nabi v2 master PNG.")
    generate.add_argument(
        "--anchors-root",
        help=(
            "Optional read-only directory containing approved nabi_v2_thinking.png, "
            "nabi_v2_celebrate.png, nabi_v2_calm.png, and nabi_v2_prompt.png pose anchors."
        ),
    )
    generate.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace only this tool's planned outputs; unrelated files are never removed.",
    )
    add_roots(generate)
    generate.set_defaults(handler=command_generate)

    validate = subcommands.add_parser("validate", help="Validate generated counts, PNG mode, alpha, dimensions, and JSON.")
    add_roots(validate)
    validate.set_defaults(handler=command_validate)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.handler(args)
    except ToolError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
