from typing import Literal

from pydantic import BaseModel, Field


DictionaryEntryType = Literal[
    "term",
    "replacement",
]

DictionaryScope = Literal[
    "personal",
    "shared",
]

DictionarySource = Literal[
    "manual",
    "suggested",
]


class CreateDictionaryEntryRequest(
    BaseModel
):
    type: DictionaryEntryType = "term"

    value: str = Field(
        min_length=1,
        max_length=150,
    )

    replacement: str | None = Field(
        default=None,
        max_length=300,
    )

    scope: DictionaryScope = "personal"


class UpdateDictionaryEntryRequest(
    BaseModel
):
    type: DictionaryEntryType | None = None

    value: str | None = Field(
        default=None,
        min_length=1,
        max_length=150,
    )

    replacement: str | None = Field(
        default=None,
        max_length=300,
    )

    scope: DictionaryScope | None = None


class DictionaryEntryResponse(
    BaseModel
):
    id: str

    type: DictionaryEntryType

    value: str

    replacement: str | None

    scope: DictionaryScope

    source: DictionarySource

    active: bool

    created_at: str

    updated_at: str


class DictionarySuggestionResponse(
    BaseModel
):
    id: str

    value: str

    created_at: str