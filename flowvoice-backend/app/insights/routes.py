from datetime import datetime, timezone

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
    insights_collection,
    notes_collection,
)

from app.services.insights_ai import (
    generate_cross_note_insights,
)


router = APIRouter(
    prefix="/insights",
    tags=["insights"],
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


# MARK: - Serializer


def serialize_insights(
    document: dict,
) -> dict:

    return {
        "notes_count":
            document.get(
                "notes_count",
                0,
            ),

        "topics_count":
            document.get(
                "topics_count",
                0,
            ),

        "actions_count":
            document.get(
                "actions_count",
                0,
            ),

        "decisions_count":
            document.get(
                "decisions_count",
                0,
            ),

        "themes":
            document.get(
                "themes",
                [],
            ),

        "decisions":
            document.get(
                "decisions",
                [],
            ),

        "action_items":
            document.get(
                "action_items",
                [],
            ),

        "ai_insight":
            document.get(
                "ai_insight",
                "",
            ),

        "generated_at": (
            serialize_datetime(
                document[
                    "generated_at"
                ]
            )
            if document.get(
                "generated_at"
            )
            else None
        ),
    }


# MARK: - Empty Response


def empty_insights() -> dict:

    return {
        "notes_count": 0,
        "topics_count": 0,
        "actions_count": 0,
        "decisions_count": 0,
        "themes": [],
        "decisions": [],
        "action_items": [],
        "ai_insight":
            "Create a few notes to start discovering patterns.",
        "generated_at": None,
    }


# MARK: - Get Latest Insights


@router.get("")
async def get_insights(
    user=Depends(
        get_current_user
    ),
):

    document = (
        insights_collection
        .find_one(
            {
                "user_id":
                    user["_id"]
            }
        )
    )

    if not document:

        return empty_insights()

    return serialize_insights(
        document
    )


# MARK: - Generate Insights


@router.post(
    "/generate",
    status_code=
        status.HTTP_200_OK,
)
async def generate_insights(
    user=Depends(
        get_current_user
    ),
):

    notes = list(
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

    if not notes:

        now = datetime.now(
            timezone.utc
        )

        document = {
            "user_id":
                user["_id"],

            "notes_count":
                0,

            "topics_count":
                0,

            "actions_count":
                0,

            "decisions_count":
                0,

            "themes":
                [],

            "decisions":
                [],

            "action_items":
                [],

            "ai_insight":
                "Create a few notes to start discovering patterns.",

            "generated_at":
                now,
        }

        (
            insights_collection
            .update_one(
                {
                    "user_id":
                        user["_id"]
                },
                {
                    "$set":
                        document
                },
                upsert=True,
            )
        )

        return serialize_insights(
            document
        )

    # -------------------------
    # Real action items
    # -------------------------

    action_items = []

    for note in notes:

        items = note.get(
            "action_items",
            [],
        )

        for item in items:

            cleaned = (
                str(item)
                .strip()
            )

            if (
                cleaned
                and cleaned
                not in action_items
            ):

                action_items.append(
                    cleaned
                )

    # Limit UI size
    action_items = (
        action_items[:8]
    )

    # -------------------------
    # Cross-note AI
    # -------------------------

    try:

        ai_result = (
            generate_cross_note_insights(
                notes
            )
        )

    except Exception as exc:

        print(
            "Insights generation failed:",
            exc
        )

        raise HTTPException(
            status_code=
                status.HTTP_502_BAD_GATEWAY,
            detail=
                "Could not generate insights.",
        )

    themes = (
        ai_result.get(
            "themes",
            [],
        )
    )

    decisions = (
        ai_result.get(
            "decisions",
            [],
        )
    )

    ai_insight = (
        ai_result.get(
            "ai_insight",
            "",
        )
    )

    now = datetime.now(
        timezone.utc
    )

    document = {
        "user_id":
            user["_id"],

        "notes_count":
            len(notes),

        "topics_count":
            len(themes),

        "actions_count":
            len(action_items),

        "decisions_count":
            len(decisions),

        "themes":
            themes,

        "decisions":
            decisions,

        "action_items":
            action_items,

        "ai_insight":
            ai_insight,

        "generated_at":
            now,
    }

    # One insights document per user.
    (
        insights_collection
        .update_one(
            {
                "user_id":
                    user["_id"]
            },
            {
                "$set":
                    document
            },
            upsert=True,
        )
    )

    saved = (
        insights_collection
        .find_one(
            {
                "user_id":
                    user["_id"]
            }
        )
    )

    print(
        "Insights generated:",
        len(themes),
        "themes,",
        len(decisions),
        "decisions,",
        len(action_items),
        "actions",
    )

    return serialize_insights(
        saved
    )
