from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FamilyGroupUpsertRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    display_name: str = Field(min_length=1, max_length=120)
    idempotency_key: str = Field(min_length=8, max_length=160)


class FamilyMemberUpsertRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    subject_id: UUID
    display_name: str = Field(min_length=1, max_length=120)
    role: Literal["adult", "member", "child", "viewer"] = "member"
    can_view: bool = True
    can_edit: bool = False
    idempotency_key: str = Field(min_length=8, max_length=160)


class FamilyMemberRemoveRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    idempotency_key: str = Field(min_length=8, max_length=160)
