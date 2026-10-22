from pydantic import BaseModel, ConfigDict


class DeleteAccountRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    confirm: bool
