import json
import os

from dotenv import load_dotenv
from openai import OpenAI


load_dotenv()


OPENROUTER_API_KEY = os.getenv(
    "OPENROUTER_API_KEY"
)

if not OPENROUTER_API_KEY:
    raise RuntimeError(
        "OPENROUTER_API_KEY is missing."
    )


MODEL_NAME = (
    "google/gemma-4-26b-a4b-it:free"
)


client = OpenAI(
    api_key=OPENROUTER_API_KEY,
    base_url=
        "https://openrouter.ai/api/v1",
)


def generate_cross_note_insights(
    notes: list[dict],
) -> dict:

    if not notes:
        return {
            "themes": [],
            "decisions": [],
            "ai_insight":
                "Create a few notes to start discovering patterns.",
        }

    note_blocks = []

    for index, note in enumerate(
        notes,
        start=1,
    ):

        title = note.get(
            "title",
            "Untitled Note",
        )

        transcript = (
            note.get(
                "transcript",
                ""
            )
            .strip()
        )

        summary = (
            note.get(
                "summary",
                ""
            )
            or ""
        ).strip()

        key_points = note.get(
            "key_points",
            [],
        )

        action_items = note.get(
            "action_items",
            [],
        )

        block = f"""
NOTE {index}
Title: {title}

Summary:
{summary}

Key points:
{json.dumps(key_points)}

Action items:
{json.dumps(action_items)}

Transcript:
{transcript}
"""

        note_blocks.append(
            block.strip()
        )

    source_text = "\n\n".join(
        note_blocks
    )

    system_prompt = """
You are the cross-conversation intelligence engine for FlowVoice.

You will receive several saved meeting notes from one user.

Identify patterns across the notes.

Return ONLY valid JSON with exactly this structure:

{
  "themes": [
    "Theme 1",
    "Theme 2"
  ],
  "decisions": [
    "Decision 1",
    "Decision 2"
  ],
  "ai_insight": "One useful cross-note observation."
}

Rules:
- Use only information found in the supplied notes.
- Do not invent facts.
- Themes should be concise recurring subjects.
- Return at most 5 themes.
- Decisions must be actual decisions or clear conclusions found in the notes.
- Return at most 6 decisions.
- If no decisions exist, return an empty array.
- ai_insight should describe one useful recurring pattern across the notes.
- Keep ai_insight to 1-2 sentences.
- Do not include markdown.
- Do not use code fences.
- Return JSON only.
"""

    response = (
        client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role":
                        "system",
                    "content":
                        system_prompt,
                },
                {
                    "role":
                        "user",
                    "content":
                        source_text,
                },
            ],
            temperature=0.2,
        )
    )

    content = (
        response
        .choices[0]
        .message
        .content
    )

    if not content:
        raise RuntimeError(
            "Insights model returned no content."
        )

    cleaned = (
        content
        .strip()
    )

    if cleaned.startswith(
        "```json"
    ):
        cleaned = cleaned[7:]

    elif cleaned.startswith(
        "```"
    ):
        cleaned = cleaned[3:]

    if cleaned.endswith(
        "```"
    ):
        cleaned = cleaned[:-3]

    cleaned = cleaned.strip()

    result = json.loads(
        cleaned
    )

    return {
        "themes":
            result.get(
                "themes",
                [],
            ),

        "decisions":
            result.get(
                "decisions",
                [],
            ),

        "ai_insight":
            result.get(
                "ai_insight",
                "",
            ),
    }