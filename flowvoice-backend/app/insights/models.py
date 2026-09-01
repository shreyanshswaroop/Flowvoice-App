from pydantic import BaseModel, Field


class InsightResponse(BaseModel):
    source_count: int = 0
    topics_count: int = 0
    actions_count: int = 0
    decisions_count: int = 0

    themes: list[str] = Field(
        default_factory=list
    )

    decisions: list[str] = Field(
        default_factory=list
    )

    action_items: list[str] = Field(
        default_factory=list
    )

    ai_insight: str = ""

    generated_at: str | None = None
