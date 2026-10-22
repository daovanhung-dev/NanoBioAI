from pydantic import BaseModel, ConfigDict, Field


class SnapshotPutRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    snapshot: dict[str, object]
    expected_revision: int | None = Field(default=None, ge=0)
