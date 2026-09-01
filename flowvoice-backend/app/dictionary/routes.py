from datetime import (
    datetime,
    timezone,
)

from bson import ObjectId

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from app.auth.routes import (
    get_current_user,
)

from app.database import (
    dictionary_collection,
    dictations_collection,
    notes_collection,
)

from app.dictionary.models import (
    CreateDictionaryEntryRequest,
    UpdateDictionaryEntryRequest,
)


router = APIRouter(
    prefix="/dictionary",
    tags=["dictionary"],
)


# MARK: - Datetime


def serialize_datetime(
    value: datetime,
) -> str:

    if value.tzinfo is None:

        value = value.replace(
            tzinfo=timezone.utc
        )

    return value.isoformat(
        timespec="milliseconds"
    )


# MARK: - Normalize


def normalize_value(
    value: str,
) -> str:

    return (
        value
        .strip()
        .lower()
    )


# MARK: - Backward Compatibility


def normalized_document(
    document: dict,
) -> dict:

    # Old dictionary documents used:
    #
    # {
    #   "term": "FlowVoice"
    # }
    #
    # Keep those working.

    value = (
        document.get(
            "value"
        )
        or document.get(
            "term"
        )
        or ""
    )

    entry_type = (
        document.get(
            "type"
        )
        or "term"
    )

    scope = (
        document.get(
            "scope"
        )
        or "personal"
    )

    source = (
        document.get(
            "source"
        )
        or "manual"
    )

    active = document.get(
        "active",
        True,
    )

    created_at = (
        document.get(
            "created_at"
        )
        or datetime.now(
            timezone.utc
        )
    )

    updated_at = (
        document.get(
            "updated_at"
        )
        or created_at
    )

    return {
        "id":
            str(
                document["_id"]
            ),

        "type":
            entry_type,

        "value":
            value,

        "replacement":
            document.get(
                "replacement"
            ),

        "scope":
            scope,

        "source":
            source,

        "active":
            active,

        "created_at":
            serialize_datetime(
                created_at
            ),

        "updated_at":
            serialize_datetime(
                updated_at
            ),
    }


# MARK: - Validate Entry


def validate_entry(
    entry_type: str,
    replacement: str | None,
):

    if entry_type == "replacement":

        if (
            replacement is None
            or
            not replacement.strip()
        ):

            raise HTTPException(
                status_code=
                    status.HTTP_400_BAD_REQUEST,
                detail=
                    "Replacement entries require replacement text.",
            )


# MARK: - Get Entries


@router.get("")
async def get_dictionary_entries(
    user=Depends(
        get_current_user
    ),
):

    cursor = (
        dictionary_collection
        .find(
            {
                "user_id":
                    user["_id"],

                "source":
                    {
                        "$ne":
                            "suggested"
                    },
            }
        )
        .sort(
            "created_at",
            -1,
        )
    )

    return [
        normalized_document(
            document
        )
        for document in cursor
    ]


# MARK: - Create Entry


@router.post(
    "",
    status_code=
        status.HTTP_201_CREATED,
)
async def create_dictionary_entry(
    payload:
        CreateDictionaryEntryRequest,

    user=Depends(
        get_current_user
    ),
):

    value = (
        payload.value
        .strip()
    )

    replacement = (
        payload.replacement
        .strip()
        if payload.replacement
        else None
    )

    validate_entry(
        payload.type,
        replacement,
    )

    normalized = (
        normalize_value(
            value
        )
    )

    existing = (
        dictionary_collection
        .find_one(
            {
                "user_id":
                    user["_id"],

                "$or": [
                    {
                        "value_normalized":
                            normalized
                    },
                    {
                        "term_normalized":
                            normalized
                    },
                ],

                "source":
                    {
                        "$ne":
                            "suggested"
                    },
            }
        )
    )

    if existing:

        raise HTTPException(
            status_code=
                status.HTTP_409_CONFLICT,
            detail=
                "This dictionary entry already exists.",
        )

    now = datetime.now(
        timezone.utc
    )

    document = {
        "user_id":
            user["_id"],

        "type":
            payload.type,

        "value":
            value,

        "value_normalized":
            normalized,

        "replacement":
            replacement,

        "scope":
            payload.scope,

        "source":
            "manual",

        "active":
            True,

        "created_at":
            now,

        "updated_at":
            now,
    }

    result = (
        dictionary_collection
        .insert_one(
            document
        )
    )

    document["_id"] = (
        result.inserted_id
    )

    return normalized_document(
        document
    )


# MARK: - Update Entry


@router.patch(
    "/{entry_id}"
)
async def update_dictionary_entry(
    entry_id: str,

    payload:
        UpdateDictionaryEntryRequest,

    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = ObjectId(
            entry_id
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid dictionary entry ID.",
        )

    existing = (
        dictionary_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    if not existing:

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Dictionary entry not found.",
        )

    current = normalized_document(
        existing
    )

    new_type = (
        payload.type
        or current["type"]
    )

    new_value = (
        payload.value.strip()
        if payload.value
        else current["value"]
    )

    new_replacement = (
        payload.replacement.strip()
        if payload.replacement is not None
        else current["replacement"]
    )

    new_scope = (
        payload.scope
        or current["scope"]
    )

    validate_entry(
        new_type,
        new_replacement,
    )

    updates = {
        "type":
            new_type,

        "value":
            new_value,

        "value_normalized":
            normalize_value(
                new_value
            ),

        "replacement":
            new_replacement,

        "scope":
            new_scope,

        "updated_at":
            datetime.now(
                timezone.utc
            ),
    }

    dictionary_collection.update_one(
        {
            "_id":
                object_id,

            "user_id":
                user["_id"],
        },
        {
            "$set":
                updates
        },
    )

    saved = (
        dictionary_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    return normalized_document(
        saved
    )


# MARK: - Delete Entry


@router.delete(
    "/{entry_id}",
    status_code=
        status.HTTP_204_NO_CONTENT,
)
async def delete_dictionary_entry(
    entry_id: str,

    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = ObjectId(
            entry_id
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid dictionary entry ID.",
        )

    result = (
        dictionary_collection
        .delete_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    if (
        result.deleted_count
        ==
        0
    ):

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Dictionary entry not found.",
        )

    return None


# MARK: - Suggestions


@router.get(
    "/suggestions"
)
async def get_dictionary_suggestions(
    user=Depends(
        get_current_user
    ),
):

    # For now suggestions are generated
    # using repeated uncommon-looking words
    # found in notes + dictations.

    existing_values = set()

    existing_cursor = (
        dictionary_collection
        .find(
            {
                "user_id":
                    user["_id"],
            }
        )
    )

    for item in existing_cursor:

        value = (
            item.get(
                "value"
            )
            or item.get(
                "term"
            )
            or ""
        )

        if value:

            existing_values.add(
                normalize_value(
                    value
                )
            )

    frequency = {}

    texts = []

    for item in (
        dictations_collection
        .find(
            {
                "user_id":
                    user["_id"]
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(100)
    ):

        text = (
            item.get(
                "text",
                ""
            )
        )

        if text:
            texts.append(
                text
            )

    for item in (
        notes_collection
        .find(
            {
                "user_id":
                    user["_id"]
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(50)
    ):

        text = (
            item.get(
                "transcript",
                ""
            )
        )

        if text:
            texts.append(
                text
            )

    for text in texts:

        words = (
            text
            .replace(
                "\n",
                " "
            )
            .split()
        )

        for raw_word in words:

            word = (
                raw_word
                .strip(
                    ".,!?;:\"'()[]{}"
                )
            )

            if len(word) < 4:
                continue

            # Keep candidates that look
            # like names, brands,
            # technologies, acronyms etc.

            looks_special = (
                word[:1].isupper()
                or not word.islower()
            )

            if not looks_special:
                continue

            normalized = (
                normalize_value(
                    word
                )
            )

            if (
                normalized
                in existing_values
            ):
                continue

            frequency[normalized] = (
                frequency.get(
                    normalized,
                    {
                        "value":
                            word,
                        "count":
                            0,
                    }
                )
            )

            frequency[
                normalized
            ]["count"] += 1

    candidates = sorted(
        frequency.values(),
        key=lambda item:
            item["count"],
        reverse=True,
    )

    candidates = [
        item
        for item in candidates
        if item["count"] >= 2
    ][:20]

    results = []

    for candidate in candidates:

        existing = (
            dictionary_collection
            .find_one(
                {
                    "user_id":
                        user["_id"],

                    "source":
                        "suggested",

                    "value_normalized":
                        normalize_value(
                            candidate[
                                "value"
                            ]
                        ),
                }
            )
        )

        if existing:

            results.append(
                normalized_document(
                    existing
                )
            )

            continue

        now = datetime.now(
            timezone.utc
        )

        document = {
            "user_id":
                user["_id"],

            "type":
                "term",

            "value":
                candidate[
                    "value"
                ],

            "value_normalized":
                normalize_value(
                    candidate[
                        "value"
                    ]
                ),

            "replacement":
                None,

            "scope":
                "personal",

            "source":
                "suggested",

            "active":
                False,

            "created_at":
                now,

            "updated_at":
                now,
        }

        result = (
            dictionary_collection
            .insert_one(
                document
            )
        )

        document["_id"] = (
            result.inserted_id
        )

        results.append(
            normalized_document(
                document
            )
        )

    return results


# MARK: - Accept Suggestion


@router.post(
    "/suggestions/{entry_id}/accept"
)
async def accept_dictionary_suggestion(
    entry_id: str,

    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = ObjectId(
            entry_id
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid suggestion ID.",
        )

    existing = (
        dictionary_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],

                "source":
                    "suggested",
            }
        )
    )

    if not existing:

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Suggestion not found.",
        )

    dictionary_collection.update_one(
        {
            "_id":
                object_id
        },
        {
            "$set":
                {
                    "source":
                        "manual",

                    "active":
                        True,

                    "updated_at":
                        datetime.now(
                            timezone.utc
                        ),
                }
        },
    )

    saved = (
        dictionary_collection
        .find_one(
            {
                "_id":
                    object_id
            }
        )
    )

    return normalized_document(
        saved
    )


# MARK: - Reject Suggestion


@router.delete(
    "/suggestions/{entry_id}",
    status_code=
        status.HTTP_204_NO_CONTENT,
)
async def reject_dictionary_suggestion(
    entry_id: str,

    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = ObjectId(
            entry_id
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid suggestion ID.",
        )

    dictionary_collection.delete_one(
        {
            "_id":
                object_id,

            "user_id":
                user["_id"],

            "source":
                "suggested",
        }
    )

    return None