from pydantic import BaseModel, Field


class CreateDictationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=10000)


class DictationResponse(BaseModel):
    id: str
    text: str
    word_count: int
    created_at: str