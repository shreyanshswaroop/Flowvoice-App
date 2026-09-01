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
        "OPENROUTER_API_KEY is missing from the .env file"
    )


MODEL_NAME = (
    "google/gemma-4-26b-a4b-it:free"
)


client = OpenAI(
    api_key=OPENROUTER_API_KEY,
    base_url="https://openrouter.ai/api/v1",
)


def summarize_note(
    transcript: str,
) -> dict:

    cleaned_transcript = (
        transcript.strip()
    )

    if not cleaned_transcript:
        raise ValueError(
            "Transcript cannot be empty."
        )

    system_prompt = """
You are the meeting intelligence engine for FlowVoice.

Analyze the meeting transcript provided by the user.

Return ONLY valid JSON matching this structure:

{
  "summary": "A concise summary of the conversation.",
  "key_points": [
    "Important point 1",
    "Important point 2"
  ],
  "action_items": [
    "Action item 1",
    "Action item 2"
  ]
}

Rules:

- Do not invent information.
- Use only information present in the transcript.
- Keep the summary concise but useful.
- Key points should contain the most important facts or decisions.
- Action items should only contain actual or clearly implied tasks.
- If there are no action items, return an empty array.
- Do not include markdown.
- Do not include code fences.
- Return JSON only.
"""

    response = (
        client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": system_prompt,
                },
                {
                    "role": "user",
                    "content": (
                        "Meeting transcript:\n\n"
                        + cleaned_transcript
                    ),
                },
            ],
            temperature=0.2,
            response_format={
                "type": "json_schema",
                "json_schema": {
                    "name":
                        "flowvoice_note_summary",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "summary": {
                                "type": "string"
                            },
                            "key_points": {
                                "type": "array",
                                "items": {
                                    "type": "string"
                                }
                            },
                            "action_items": {
                                "type": "array",
                                "items": {
                                    "type": "string"
                                }
                            }
                        },
                        "required": [
                            "summary",
                            "key_points",
                            "action_items",
                        ],
                        "additionalProperties":
                            False,
                    },
                },
            },
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
            "The model returned an empty response."
        )

    result = json.loads(
        content
    )

    return {
        "summary":
            result.get(
                "summary",
                "",
            ),
        "key_points":
            result.get(
                "key_points",
                [],
            ),
        "action_items":
            result.get(
                "action_items",
                [],
            ),
    }