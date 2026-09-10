from datetime import datetime, timedelta, timezone

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
    dictations_collection,
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

        "usage":
            document.get(
                "usage",
                default_usage_metrics(),
            ),

        "notetaker":
            document.get(
                "notetaker",
                default_notetaker_metrics(),
            ),
    }


# MARK: - Empty Response


def default_usage_metrics() -> dict:

    return {
        "words_per_minute": 0,
        "time_saved_seconds": 0,
        "total_words_dictated": 0,
        "where_you_dictate": [],
        "usage_streak_days": 0,
        "activity_days": [],
    }


def default_notetaker_metrics() -> dict:

    return {
        "total_meetings": 0,
        "meeting_time_seconds": 0,
        "action_items": 0,
        "meeting_activity": [],
        "completed_tasks": 0,
        "open_tasks": 0,
        "overdue_tasks": 0,
        "meeting_intelligence":
            "Start capturing meetings to see useful patterns about follow-ups, tasks, and meeting quality.",
    }


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
        "usage": default_usage_metrics(),
        "notetaker": default_notetaker_metrics(),
    }


# MARK: - Real Metrics


def word_count(
    text: str | None,
) -> int:

    if not text:
        return 0

    return len(
        text.split()
    )


def note_word_count(
    note: dict,
) -> int:

    stored = note.get(
        "word_count"
    )

    if isinstance(stored, int):
        return max(
            stored,
            0,
        )

    return word_count(
        note.get(
            "transcript",
            ""
        )
    )


def positive_int(
    value,
) -> int:

    try:
        return max(
            int(
                value
                or 0
            ),
            0,
        )
    except (TypeError, ValueError):
        return 0


def coerce_datetime(
    value,
) -> datetime | None:

    if not isinstance(
        value,
        datetime,
    ):
        return None

    if value.tzinfo is None:
        return value.replace(
            tzinfo=timezone.utc
        )

    return value.astimezone(
        timezone.utc
    )


def date_key(
    value: datetime,
) -> str:

    return value.date().isoformat()


def build_daily_activity(
    documents: list[dict],
) -> list[dict]:

    counts: dict[str, int] = {}

    for document in documents:

        created_at = coerce_datetime(
            document.get(
                "created_at"
            )
        )

        if not created_at:
            continue

        key = date_key(
            created_at
        )

        counts[key] = (
            counts.get(
                key,
                0,
            )
            + 1
        )

    return [
        {
            "date": key,
            "count": counts[key],
        }
        for key in sorted(
            counts.keys()
        )
    ]


def calculate_streak_days(
    documents: list[dict],
) -> int:

    active_days = {
        date_key(created_at)
        for document in documents
        if (
            created_at :=
            coerce_datetime(
                document.get(
                    "created_at"
                )
            )
        )
    }

    if not active_days:
        return 0

    cursor = datetime.now(
        timezone.utc
    ).date()

    streak = 0

    while cursor.isoformat() in active_days:
        streak += 1
        cursor -= timedelta(
            days=1
        )

    return streak


def build_real_metrics(
    user_id,
    notes: list[dict] | None = None,
) -> dict:

    if notes is None:
        notes = list(
            notes_collection
            .find(
                {
                    "user_id": user_id
                }
            )
            .sort(
                "created_at",
                -1,
            )
        )

    dictations = list(
        dictations_collection
        .find(
            {
                "user_id": user_id
            }
        )
        .sort(
            "created_at",
            -1,
        )
    )

    dictation_words = sum(
        positive_int(
            item.get(
                "word_count"
            )
            or word_count(
                item.get(
                    "text",
                    ""
                )
            )
        )
        for item in dictations
    )

    note_words = sum(
        note_word_count(
            note
        )
        for note in notes
    )

    meeting_seconds = sum(
        positive_int(
            note.get(
                "duration_seconds"
            )
        )
        for note in notes
    )

    dictation_seconds = sum(
        positive_int(
            item.get(
                "duration_seconds"
            )
        )
        for item in dictations
    )

    total_spoken_words = (
        dictation_words
        + note_words
    )

    timed_words = sum(
        positive_int(
            item.get(
                "word_count"
            )
            or word_count(
                item.get(
                    "text",
                    ""
                )
            )
        )
        for item in dictations
        if positive_int(
            item.get(
                "duration_seconds"
            )
        )
        > 0
    ) + sum(
        note_word_count(
            note
        )
        for note in notes
        if positive_int(
            note.get(
                "duration_seconds"
            )
        )
        > 0
    )

    timed_seconds = (
        dictation_seconds
        + meeting_seconds
    )

    words_per_minute = (
        round(
            timed_words
            / (timed_seconds / 60),
        )
        if timed_seconds > 0
        and timed_words > 0
        else 0
    )

    typing_words_per_minute = 40

    time_saved_seconds = (
        round(
            max(
                0,
                (
                    timed_words
                    / typing_words_per_minute
                )
                * 60
                - timed_seconds,
            )
        )
        if timed_words > 0
        and timed_seconds > 0
        else 0
    )

    action_items = []

    for note in notes:

        for item in note.get(
            "action_items",
            [],
        ):

            cleaned = str(
                item
            ).strip()

            if cleaned:
                action_items.append(
                    cleaned
                )

    total_actions = len(
        action_items
    )

    completed_tasks = 0
    overdue_tasks = 0
    open_tasks = total_actions

    if total_actions == 0:
        intelligence = (
            "No action items have been found yet. Capture and summarize meetings to build meeting intelligence."
        )
    else:
        intelligence = (
            f"FlowVoice found {total_actions} action item"
            f"{'' if total_actions == 1 else 's'} across {len(notes)} meeting"
            f"{'' if len(notes) == 1 else 's'}."
        )

    where_you_dictate = []

    if total_spoken_words > 0:
        where_you_dictate.append(
            {
                "label": "Desktop",
                "words": total_spoken_words,
                "percentage": 100,
            }
        )

    return {
        "usage": {
            "words_per_minute": words_per_minute,
            "time_saved_seconds": time_saved_seconds,
            "total_words_dictated": total_spoken_words,
            "where_you_dictate": where_you_dictate,
            "usage_streak_days": calculate_streak_days(
                dictations
                + notes
            ),
            "activity_days": build_daily_activity(
                dictations
                + notes
            ),
        },
        "notetaker": {
            "total_meetings": len(
                notes
            ),
            "meeting_time_seconds": meeting_seconds,
            "action_items": total_actions,
            "meeting_activity": build_daily_activity(
                notes
            ),
            "completed_tasks": completed_tasks,
            "open_tasks": open_tasks,
            "overdue_tasks": overdue_tasks,
            "meeting_intelligence": intelligence,
        },
    }


# MARK: - Get Latest Insights


@router.get("")
async def get_insights(
    user=Depends(
        get_current_user
    ),
):

    metrics = build_real_metrics(
        user["_id"]
    )

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

        response = empty_insights()
        response.update(
            metrics
        )

        return response

    document.update(
        metrics
    )

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

            **build_real_metrics(
                user["_id"],
                notes,
            ),
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

        **build_real_metrics(
            user["_id"],
            notes,
        ),
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
