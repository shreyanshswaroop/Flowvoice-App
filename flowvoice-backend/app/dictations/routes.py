from datetime import datetime, timezone

from bson import ObjectId
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from app.auth.routes import get_current_user
from app.database import dictations_collection
from app.dictations.models import (
    CreateDictationRequest,
)


router = APIRouter(
    prefix="/dictations",
    tags=["dictations"],
)


def serialize_datetime(
    value: datetime,
) -> str:
    """
    MongoDB stores datetimes in UTC.

    PyMongo can return them without tzinfo,
    so make UTC explicit before sending
    the timestamp to the macOS app.
    """

    if value.tzinfo is None:
        value = value.replace(
            tzinfo=timezone.utc
        )

    return value.isoformat(
        timespec="milliseconds"
    )


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
)
async def create_dictation(
    payload: CreateDictationRequest,
    user=Depends(get_current_user),
):
    cleaned_text = payload.text.strip()

    if not cleaned_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Dictation text cannot be empty.",
        )

    created_at = datetime.now(
        timezone.utc
    )

    document = {
        "user_id": user["_id"],
        "text": cleaned_text,
        "word_count": len(
            cleaned_text.split()
        ),
        "duration_seconds": payload.duration_seconds,
        "created_at": created_at,
    }

    result = dictations_collection.insert_one(
        document
    )

    return {
        "id": str(result.inserted_id),
        "text": cleaned_text,
        "word_count": document["word_count"],
        "duration_seconds": document["duration_seconds"],
        "created_at": serialize_datetime(
            created_at
        ),
    }


@router.get("")
async def get_dictations(
    user=Depends(get_current_user),
):
    cursor = (
        dictations_collection
        .find(
            {
                "user_id": user["_id"]
            }
        )
        .sort(
            "created_at",
            -1,
        )
    )

    results = []

    for item in cursor:

        created_at = item.get(
            "created_at"
        )

        results.append(
            {
                "id": str(
                    item["_id"]
                ),
                "text": item["text"],
                "word_count": item.get(
                    "word_count",
                    len(
                        item["text"].split()
                    ),
                ),
                "duration_seconds": item.get(
                    "duration_seconds"
                ),
                "created_at":
                    serialize_datetime(
                        created_at
                    )
                    if created_at
                    else None,
            }
        )

    return results


@router.delete(
    "/{dictation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_dictation(
    dictation_id: str,
    user=Depends(get_current_user),
):
    try:
        object_id = ObjectId(
            dictation_id
        )

    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid dictation ID.",
        )

    result = dictations_collection.delete_one(
        {
            "_id": object_id,
            "user_id": user["_id"],
        }
    )

    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dictation not found.",
        )

    return
