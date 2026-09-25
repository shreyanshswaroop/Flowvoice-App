import json
import os

from urllib.parse import (
    urlencode,
)

import websockets

from dotenv import (
    load_dotenv,
)


load_dotenv()


class DeepgramSTT:

    def __init__(self):

        api_key = os.getenv(
            "DEEPGRAM_API_KEY"
        )

        if not api_key:

            raise RuntimeError(
                "DEEPGRAM_API_KEY is missing from the .env file"
            )

        self.api_key = api_key

        self.connection = None

    async def connect(
        self,
        keyterms:
            list[str] | None = None,
        audio_mode:
            str = "dictation",
        diarize:
            bool | None = None,
    ):

        # Deepgram Nova-3 supports
        # Keyterm Prompting.
        #
        # Each term must be supplied as:
        #
        # keyterm=FlowVoice
        # keyterm=MongoDB
        #
        # NOT:
        #
        # keyterm=FlowVoice,MongoDB
        #
        # and no weights should be used.

        cleaned_keyterms = []

        seen = set()

        for term in (
            keyterms
            or []
        ):

            cleaned = (
                str(term)
                .strip()
            )

            if not cleaned:
                continue

            normalized = (
                cleaned.lower()
            )

            if normalized in seen:
                continue

            seen.add(
                normalized
            )

            cleaned_keyterms.append(
                cleaned
            )

        # Keep within Deepgram's
        # recommended Keyterm limit.

        cleaned_keyterms = (
            cleaned_keyterms[:100]
        )

        is_meeting_dual_channel = (
            audio_mode
            == "meeting_dual_channel"
        )

        channel_count = "1"

        should_diarize = (
            diarize
            if diarize is not None
            else not is_meeting_dual_channel
        )

        endpointing_ms = (
            "80"
            if is_meeting_dual_channel
            else "150"
        )

        query_items = [
            (
                "model",
                "nova-3",
            ),
            (
                "language",
                "en-US",
            ),
            (
                "encoding",
                "linear16",
            ),
            (
                "sample_rate",
                "16000",
            ),
            (
                "channels",
                channel_count,
            ),
            (
                "smart_format",
                "true",
            ),
            (
                "interim_results",
                "true",
            ),
            (
                "endpointing",
                endpointing_ms,
            ),
            (
                "diarize",
                "true" if should_diarize else "false",
            ),
        ]

        # IMPORTANT:
        # Repeat the keyterm query
        # parameter for every term.

        for term in cleaned_keyterms:

            query_items.append(
                (
                    "keyterm",
                    term,
                )
            )

        query = urlencode(
            query_items
        )

        self.connection = (
            await websockets.connect(
                (
                    "wss://api.deepgram.com/"
                    f"v1/listen?{query}"
                ),
                additional_headers={
                    "Authorization":
                        f"Token {self.api_key}",
                },
                max_size=None,
            )
        )

        print(
            "Connected to Deepgram STT"
        )

        if cleaned_keyterms:

            print(
                "Deepgram keyterms loaded:",
                len(
                    cleaned_keyterms
                ),
            )

    async def send_audio(
        self,
        audio: bytes,
    ):

        if not self.connection:
            return

        try:

            await self.connection.send(
                audio
            )

        except Exception as exc:

            print(
                "Deepgram audio send error:",
                exc,
            )

    async def finalize(self):

        """
        Ask Deepgram to flush any
        buffered audio and return the
        final transcription result.

        This does NOT close the WebSocket.
        """

        if not self.connection:
            return

        try:

            await self.connection.send(
                json.dumps(
                    {
                        "type":
                            "Finalize"
                    }
                )
            )

            print(
                "Deepgram Finalize sent"
            )

        except Exception as exc:

            print(
                "Deepgram Finalize error:",
                exc,
            )

    async def close_stream(self):

        """
        Tell Deepgram that this streaming
        session is completely finished.
        """

        if not self.connection:
            return

        try:

            await self.connection.send(
                json.dumps(
                    {
                        "type":
                            "CloseStream"
                    }
                )
            )

            print(
                "Deepgram CloseStream sent"
            )

        except Exception as exc:

            print(
                "Deepgram CloseStream error:",
                exc,
            )

    async def receive(self):

        if not self.connection:
            return

        try:

            async for message \
                in self.connection:

                yield json.loads(
                    message
                )

        except (
            websockets
            .ConnectionClosedOK
        ):

            print(
                "Deepgram connection closed normally"
            )

        except (
            websockets
            .ConnectionClosedError
        ) as exc:

            print(
                "Deepgram connection closed with error:",
                exc,
            )

    async def close(self):

        if not self.connection:
            return

        try:

            await self.connection.close()

        except Exception as exc:

            print(
                "Deepgram close error:",
                exc,
            )

        finally:

            self.connection = None

        print(
            "Deepgram STT connection closed"
        )
