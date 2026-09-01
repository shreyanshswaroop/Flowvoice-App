from pydantic import BaseModel, Field


class NoteSpeakerSegment(BaseModel):
    speaker: int = Field(
        ge=0,
    )

    text: str = Field(
        min_length=1,
    )

    start: float | None = None

    end: float | None = None


class CreateNoteRequest(BaseModel):
    title: str = Field(
        min_length=1,
        max_length=200,
    )

    transcript: str = Field(
        min_length=1,
        max_length=100000,
    )

    duration_seconds: int | None = Field(
        default=None,
        ge=0,
    )

    segments: list[NoteSpeakerSegment] = Field(
        default_factory=list,
    )


class UpdateNoteRequest(BaseModel):
    title: str | None = Field(
        default=None,
        min_length=1,
        max_length=200,
    )

    transcript: str | None = Field(
        default=None,
        min_length=1,
        max_length=100000,
    )

    duration_seconds: int | None = Field(
        default=None,
        ge=0,
    )

    segments: list[NoteSpeakerSegment] | None = Field(
        default=None,
    )
