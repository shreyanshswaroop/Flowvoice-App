from datetime import datetime, timezone

from bson import ObjectId

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from app.auth.routes import get_current_user

from app.database import notes_collection

from app.notes.models import (
    CreateNoteRequest,
    UpdateNoteRequest,
)

from app.services.note_ai import summarize_note


router = APIRouter(
    prefix="/notes",
    tags=["notes"],
)


# MARK: - Serialization


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


def serialize_note(
    note: dict,
) -> dict:

    return {
        "id": str(
            note["_id"]
        ),

        "title": note.get(
            "title",
            "Untitled Note",
        ),

        "transcript": note.get(
            "transcript",
            "",
        ),

        "duration_seconds": note.get(
            "duration_seconds"
        ),

        # Speaker diarization
        "segments": note.get(
            "segments",
            [],
        ),

        # AI fields
        "summary": note.get(
            "summary"
        ),

        "key_points": note.get(
            "key_points",
            [],
        ),

        "action_items": note.get(
            "action_items",
            [],
        ),

        "created_at": (
            serialize_datetime(
                note["created_at"]
            )
            if note.get("created_at")
            else None
        ),

        "updated_at": (
            serialize_datetime(
                note["updated_at"]
            )
            if note.get("updated_at")
            else None
        ),
    }


# MARK: - Speaker Summary Input


def build_summary_input(
    note: dict,
) -> str:

    segments = note.get(
        "segments",
        [],
    )

    if segments:

        lines = []

        for segment in segments:

            speaker = segment.get(
                "speaker",
                0,
            )

            text = (
                segment.get(
                    "text",
                    ""
                )
                .strip()
            )

            if not text:
                continue

            lines.append(
                f"Speaker {speaker + 1}: {text}"
            )

        if lines:

            return "\n".join(
                lines
            )

    return (
        note.get(
            "transcript",
            ""
        )
        .strip()
    )


# MARK: - Create Note


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
)
async def create_note(
    payload: CreateNoteRequest,
    user=Depends(
        get_current_user
    ),
):

    title = (
        payload.title
        .strip()
    )

    transcript = (
        payload.transcript
        .strip()
    )

    if not title:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Note title cannot be empty.",
        )

    if not transcript:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Note transcript cannot be empty.",
        )

    now = datetime.now(
        timezone.utc
    )

    segments = [
        segment.model_dump()
        for segment in payload.segments
    ]

    document = {
        "user_id":
            user["_id"],

        "title":
            title,

        "transcript":
            transcript,

        "duration_seconds":
            payload.duration_seconds,

        # Speaker diarization
        "segments":
            segments,

        # AI fields start empty
        "summary":
            None,

        "key_points":
            [],

        "action_items":
            [],

        "created_at":
            now,

        "updated_at":
            now,
    }

    result = (
        notes_collection
        .insert_one(
            document
        )
    )

    document["_id"] = (
        result.inserted_id
    )

    print(
        "Note created with",
        len(segments),
        "speaker segments",
    )

    return serialize_note(
        document
    )


# MARK: - Get All Notes


@router.get("")
async def get_notes(
    user=Depends(
        get_current_user
    ),
):

    cursor = (
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
    )

    notes = []

    for note in cursor:

        notes.append(
            serialize_note(
                note
            )
        )

    return notes


# MARK: - Get Single Note


@router.get(
    "/{note_id}"
)
async def get_note(
    note_id: str,
    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = (
            ObjectId(
                note_id
            )
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid note ID.",
        )

    note = (
        notes_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    if not note:

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Note not found.",
        )

    return serialize_note(
        note
    )


# MARK: - Update Note


@router.patch(
    "/{note_id}"
)
async def update_note(
    note_id: str,
    payload: UpdateNoteRequest,
    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = (
            ObjectId(
                note_id
            )
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid note ID.",
        )

    updates = {}

    transcript_changed = False
    segments_changed = False

    # MARK: Title

    if payload.title is not None:

        title = (
            payload.title
            .strip()
        )

        if not title:

            raise HTTPException(
                status_code=
                    status.HTTP_400_BAD_REQUEST,
                detail=
                    "Note title cannot be empty.",
            )

        updates[
            "title"
        ] = title

    # MARK: Transcript

    if payload.transcript is not None:

        transcript = (
            payload.transcript
            .strip()
        )

        if not transcript:

            raise HTTPException(
                status_code=
                    status.HTTP_400_BAD_REQUEST,
                detail=
                    "Note transcript cannot be empty.",
            )

        updates[
            "transcript"
        ] = transcript

        transcript_changed = True

    # MARK: Duration

    if (
        payload.duration_seconds
        is not None
    ):

        updates[
            "duration_seconds"
        ] = payload.duration_seconds

    # MARK: Speaker Segments

    if payload.segments is not None:

        updates[
            "segments"
        ] = [
            segment.model_dump()
            for segment
            in payload.segments
        ]

        segments_changed = True

    # MARK: Invalidate AI

    if (
        transcript_changed
        or segments_changed
    ):

        updates[
            "summary"
        ] = None

        updates[
            "key_points"
        ] = []

        updates[
            "action_items"
        ] = []

    if not updates:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "No fields to update.",
        )

    updates[
        "updated_at"
    ] = datetime.now(
        timezone.utc
    )

    result = (
        notes_collection
        .update_one(
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
    )

    if (
        result.matched_count
        == 0
    ):

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Note not found.",
        )

    note = (
        notes_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    return serialize_note(
        note
    )


# MARK: - Summarize Note


@router.post(
    "/{note_id}/summarize"
)
async def summarize_saved_note(
    note_id: str,
    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = (
            ObjectId(
                note_id
            )
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid note ID.",
        )

    note = (
        notes_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    if not note:

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Note not found.",
        )

    summary_input = (
        build_summary_input(
            note
        )
    )

    if not summary_input:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Note has no transcript to summarize.",
        )

    try:

        print(
            "Generating summary using",
            len(
                note.get(
                    "segments",
                    []
                )
            ),
            "speaker segments",
        )

        result = summarize_note(
            summary_input
        )

    except Exception as exc:

        print(
            "Note summarization failed:",
            exc
        )

        raise HTTPException(
            status_code=
                status.HTTP_502_BAD_GATEWAY,
            detail=
                "Could not generate note summary.",
        )

    now = datetime.now(
        timezone.utc
    )

    notes_collection.update_one(
        {
            "_id":
                object_id,

            "user_id":
                user["_id"],
        },
        {
            "$set": {

                "summary":
                    result[
                        "summary"
                    ],

                "key_points":
                    result[
                        "key_points"
                    ],

                "action_items":
                    result[
                        "action_items"
                    ],

                "updated_at":
                    now,
            }
        },
    )

    updated_note = (
        notes_collection
        .find_one(
            {
                "_id":
                    object_id,

                "user_id":
                    user["_id"],
            }
        )
    )

    return serialize_note(
        updated_note
    )


# MARK: - Delete Note


@router.delete(
    "/{note_id}",
    status_code=
        status.HTTP_204_NO_CONTENT,
)
async def delete_note(
    note_id: str,
    user=Depends(
        get_current_user
    ),
):

    try:

        object_id = (
            ObjectId(
                note_id
            )
        )

    except Exception:

        raise HTTPException(
            status_code=
                status.HTTP_400_BAD_REQUEST,
            detail=
                "Invalid note ID.",
        )

    result = (
        notes_collection
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
        == 0
    ):

        raise HTTPException(
            status_code=
                status.HTTP_404_NOT_FOUND,
            detail=
                "Note not found.",
        )

    return