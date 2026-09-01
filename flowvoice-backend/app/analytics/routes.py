from datetime import (
    datetime,
    timedelta,
    timezone,
)

from fastapi import (
    APIRouter,
    Depends,
)

from app.auth.routes import (
    get_current_user,
)

from app.database import (
    dictations_collection,
    notes_collection,
)


router = APIRouter(
    prefix="/analytics",
    tags=["analytics"],
)


def start_of_utc_day(
    value: datetime,
) -> datetime:

    if value.tzinfo is None:
        value = value.replace(
            tzinfo=timezone.utc
        )

    return value.astimezone(
        timezone.utc
    ).replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )


def safe_word_count(
    text: str,
) -> int:

    return len(
        text
        .strip()
        .split()
    )


@router.get("")
async def get_analytics(
    user=Depends(
        get_current_user
    ),
):

    user_id = user["_id"]

    # ----------------------------------
    # Load Dictations
    # ----------------------------------

    dictations = list(
        dictations_collection.find(
            {
                "user_id":
                    user_id
            }
        )
    )

    # ----------------------------------
    # Load Notes
    # ----------------------------------

    notes = list(
        notes_collection.find(
            {
                "user_id":
                    user_id
            }
        )
    )

    # ----------------------------------
    # Totals
    # ----------------------------------

    total_dictations = len(
        dictations
    )

    total_notes = len(
        notes
    )

    dictation_words = sum(
        item.get(
            "word_count",
            safe_word_count(
                item.get(
                    "text",
                    ""
                )
            ),
        )
        for item in dictations
    )

    note_words = sum(
        safe_word_count(
            item.get(
                "transcript",
                ""
            )
        )
        for item in notes
    )

    total_words = (
        dictation_words
        +
        note_words
    )

    total_speaking_seconds = sum(
        item.get(
            "duration_seconds",
            0,
        )
        or 0
        for item in notes
    )

    average_note_seconds = (
        int(
            total_speaking_seconds
            /
            total_notes
        )
        if total_notes > 0
        else 0
    )

    average_words_per_note = (
        int(
            note_words
            /
            total_notes
        )
        if total_notes > 0
        else 0
    )

    average_words_per_dictation = (
        int(
            dictation_words
            /
            total_dictations
        )
        if total_dictations > 0
        else 0
    )

    # ----------------------------------
    # Usage Split
    # ----------------------------------

    if total_words > 0:

        dictation_percentage = round(
            (
                dictation_words
                /
                total_words
            )
            * 100
        )

        note_percentage = (
            100
            -
            dictation_percentage
        )

    else:

        dictation_percentage = 0
        note_percentage = 0

    # ----------------------------------
    # Last 7 Days
    # ----------------------------------

    now = datetime.now(
        timezone.utc
    )

    today = start_of_utc_day(
        now
    )

    daily_activity = []

    for offset in range(
        6,
        -1,
        -1,
    ):

        day_start = (
            today
            -
            timedelta(
                days=offset
            )
        )

        day_end = (
            day_start
            +
            timedelta(
                days=1
            )
        )

        day_dictations = [
            item
            for item in dictations
            if item.get(
                "created_at"
            )
            and
            day_start
            <= normalize_datetime(
                item[
                    "created_at"
                ]
            )
            < day_end
        ]

        day_notes = [
            item
            for item in notes
            if item.get(
                "created_at"
            )
            and
            day_start
            <= normalize_datetime(
                item[
                    "created_at"
                ]
            )
            < day_end
        ]

        day_dictation_words = sum(
            item.get(
                "word_count",
                safe_word_count(
                    item.get(
                        "text",
                        ""
                    )
                ),
            )
            for item
            in day_dictations
        )

        day_note_words = sum(
            safe_word_count(
                item.get(
                    "transcript",
                    ""
                )
            )
            for item
            in day_notes
        )

        daily_activity.append(
            {
                "date":
                    day_start
                    .date()
                    .isoformat(),

                "dictations":
                    len(
                        day_dictations
                    ),

                "notes":
                    len(
                        day_notes
                    ),

                "words":
                    (
                        day_dictation_words
                        +
                        day_note_words
                    ),
            }
        )

    # ----------------------------------
    # Current Week
    # ----------------------------------

    week_start = (
        today
        -
        timedelta(
            days=
                today.weekday()
        )
    )

    dictations_this_week = sum(
        1
        for item in dictations
        if item.get(
            "created_at"
        )
        and normalize_datetime(
            item[
                "created_at"
            ]
        )
        >= week_start
    )

    notes_this_week = sum(
        1
        for item in notes
        if item.get(
            "created_at"
        )
        and normalize_datetime(
            item[
                "created_at"
            ]
        )
        >= week_start
    )

    words_this_week = 0

    for item in dictations:

        created_at = item.get(
            "created_at"
        )

        if (
            created_at
            and normalize_datetime(
                created_at
            )
            >= week_start
        ):

            words_this_week += (
                item.get(
                    "word_count",
                    safe_word_count(
                        item.get(
                            "text",
                            ""
                        )
                    ),
                )
            )

    for item in notes:

        created_at = item.get(
            "created_at"
        )

        if (
            created_at
            and normalize_datetime(
                created_at
            )
            >= week_start
        ):

            words_this_week += (
                safe_word_count(
                    item.get(
                        "transcript",
                        ""
                    )
                )
            )

    return {
        "total_dictations":
            total_dictations,

        "total_notes":
            total_notes,

        "total_words":
            total_words,

        "total_speaking_seconds":
            total_speaking_seconds,

        "average_note_seconds":
            average_note_seconds,

        "average_words_per_note":
            average_words_per_note,

        "average_words_per_dictation":
            average_words_per_dictation,

        "dictation_words":
            dictation_words,

        "note_words":
            note_words,

        "dictation_percentage":
            dictation_percentage,

        "note_percentage":
            note_percentage,

        "dictations_this_week":
            dictations_this_week,

        "notes_this_week":
            notes_this_week,

        "words_this_week":
            words_this_week,

        "daily_activity":
            daily_activity,
    }


def normalize_datetime(
    value: datetime,
) -> datetime:

    if value.tzinfo is None:

        return value.replace(
            tzinfo=timezone.utc
        )

    return value.astimezone(
        timezone.utc
    )