from pydantic import BaseModel, Field


class CreateDictationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=10000)
    duration_seconds: int | None = Field(
        default=None,
        ge=0,
    )
