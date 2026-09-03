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
