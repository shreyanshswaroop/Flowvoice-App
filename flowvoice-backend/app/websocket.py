import asyncio
import json

from fastapi import (
    APIRouter,
    WebSocket,
    WebSocketDisconnect,
)

from app.services.deepgram_stt import (
    DeepgramSTT,
)

from app.services.utterance_manager import (
    UtteranceManager,
)


router = APIRouter()


# MARK: - Speaker Segments


def build_speaker_segments(
    words: list[dict],
) -> list[dict]:

    if not words:
        return []

    segments = []

    current_speaker = None
    current_words = []

    start_time = None
    end_time = None

    for word in words:

        speaker = word.get(
            "speaker",
            0,
        )

        word_text = (
            word.get(
                "punctuated_word"
            )
            or word.get(
                "word"
            )
            or ""
        ).strip()

        if not word_text:
            continue

        word_start = word.get(
            "start"
        )

        word_end = word.get(
            "end"
        )

        # First word

        if current_speaker is None:

            current_speaker = (
                speaker
            )

            start_time = (
                word_start
            )

        # Speaker changed

        if speaker != current_speaker:

            if current_words:

                segments.append(
                    {
                        "speaker":
                            current_speaker,

                        "text":
                            " ".join(
                                current_words
                            ).strip(),

                        "start":
                            start_time,

                        "end":
                            end_time,
                    }
                )

            current_speaker = (
                speaker
            )

            current_words = []

            start_time = (
                word_start
            )

        current_words.append(
            word_text
        )

        end_time = (
            word_end
        )

    # Final pending segment

    if current_words:

        segments.append(
            {
                "speaker":
                    current_speaker,

                "text":
                    " ".join(
                        current_words
                    ).strip(),

                "start":
                    start_time,

                "end":
                    end_time,
            }
        )

    return segments


# MARK: - Clean Keyterms


def clean_keyterms(
    values,
) -> list[str]:

    if not isinstance(
        values,
        list,
    ):
        return []

    cleaned = []

    seen = set()

    for value in values:

        if not isinstance(
            value,
            str,
        ):
            continue

        term = value.strip()

        if not term:
            continue

        normalized = (
            term.lower()
        )

        if normalized in seen:
            continue

        seen.add(
            normalized
        )

        cleaned.append(
            term
        )

        # Nova-3 keyterm prompting
        # supports up to 100 terms.
        if len(cleaned) >= 100:
            break

    return cleaned


# MARK: - WebSocket


@router.websocket(
    "/ws/voice"
)
async def voice_websocket(
    websocket: WebSocket,
):

    await websocket.accept()

    print(
        "FlowVoice client connected"
    )

    await websocket.send_json(
        {
            "type":
                "connection",

            "status":
                "connected",

            "message":
                "Connected to FlowVoice",
        }
    )

    stt: DeepgramSTT | None = (
        None
    )

    transcript_task: (
        asyncio.Task | None
    ) = None

    utterance_manager = (
        UtteranceManager()
    )

    waiting_for_finalize = (
        False
    )

    finalize_timeout_task: (
        asyncio.Task | None
    ) = None

    # MARK: - Safe Send

    async def safely_send_json(
        payload: dict,
    ):

        try:

            await websocket.send_json(
                payload
            )

            return True

        except Exception as exc:

            print(
                "WebSocket send error:",
                exc,
            )

            return False

    # MARK: - Finish Session

    async def finish_dictation():

        nonlocal waiting_for_finalize
        nonlocal finalize_timeout_task
        nonlocal stt

        if not waiting_for_finalize:
            return

        current_stt = stt

        waiting_for_finalize = (
            False
        )

        if (
            finalize_timeout_task
            is not None
        ):

            finalize_timeout_task.cancel()

            finalize_timeout_task = (
                None
            )

        await safely_send_json(
            {
                "type":
                    "dictation_complete",
            }
        )

        print(
            "FlowVoice dictation complete"
        )

        await stop_stt(
            close_stream=False,
            stt_to_close=current_stt,
        )

    # MARK: - Finalize Timeout

    async def finalize_timeout():

        try:

            await asyncio.sleep(
                2.5
            )

            if not waiting_for_finalize:
                return

            print(
                "Finalize timeout reached. "
                "Finishing with available transcript."
            )

            utterance = (
                utterance_manager
                .build_utterance()
            )

            if utterance is not None:

                print(
                    "Utterance from timeout:",
                    utterance["text"],
                )

                await safely_send_json(
                    {
                        "type":
                            "utterance_final",

                        "text":
                            utterance[
                                "text"
                            ],

                        "duration_ms":
                            utterance[
                                "duration_ms"
                            ],
                    }
                )

            await finish_dictation()

        except asyncio.CancelledError:

            pass

    # MARK: - Receive Deepgram

    async def receive_transcripts():

        nonlocal stt
        nonlocal waiting_for_finalize

        if stt is None:
            return

        try:

            async for result in (
                stt.receive()
            ):

                if not isinstance(
                    result,
                    dict,
                ):
                    continue

                if (
                    result.get(
                        "type"
                    )
                    != "Results"
                ):
                    continue

                channel = result.get(
                    "channel",
                    {},
                )

                alternatives = (
                    channel.get(
                        "alternatives",
                        [],
                    )
                )

                if not alternatives:
                    continue

                alternative = (
                    alternatives[0]
                )

                transcript = (
                    alternative.get(
                        "transcript",
                        "",
                    )
                )

                words = (
                    alternative.get(
                        "words",
                        [],
                    )
                )

                is_final = (
                    result.get(
                        "is_final",
                        False,
                    )
                )

                speech_final = (
                    result.get(
                        "speech_final",
                        False,
                    )
                )

                from_finalize = (
                    result.get(
                        "from_finalize",
                        False,
                    )
                )

                print(
                    f"Transcript: {transcript} "
                    f"| final: {is_final} "
                    f"| speech_final: {speech_final} "
                    f"| from_finalize: {from_finalize} "
                    f"| words: {len(words)}"
                )

                # MARK: Transcript Events

                if transcript:

                    if is_final:

                        utterance_manager.add_final_segment(
                            transcript
                        )

                    sent = (
                        await safely_send_json(
                            {
                                "type":
                                    (
                                        "transcript_final"
                                        if is_final
                                        else
                                        "transcript_partial"
                                    ),

                                "text":
                                    transcript,

                                "is_final":
                                    is_final,

                                "speech_final":
                                    speech_final,

                                "from_finalize":
                                    from_finalize,
                            }
                        )
                    )

                    if not sent:
                        break

                # MARK: Speaker Diarization

                if (
                    is_final
                    and words
                ):

                    speaker_segments = (
                        build_speaker_segments(
                            words
                        )
                    )

                    if speaker_segments:

                        print(
                            "Speaker segments:",
                            speaker_segments,
                        )

                        sent = (
                            await safely_send_json(
                                {
                                    "type":
                                        "speaker_segments",

                                    "segments":
                                        speaker_segments,
                                }
                            )
                        )

                        if not sent:
                            break

                # MARK: Finish Utterance

                should_finish_utterance = (
                    speech_final
                    or from_finalize
                )

                if (
                    not should_finish_utterance
                ):
                    continue

                utterance = (
                    utterance_manager
                    .build_utterance()
                )

                if utterance is not None:

                    print(
                        "Utterance:",
                        utterance[
                            "text"
                        ],
                    )

                    sent = (
                        await safely_send_json(
                            {
                                "type":
                                    "utterance_final",

                                "text":
                                    utterance[
                                        "text"
                                    ],

                                "duration_ms":
                                    utterance[
                                        "duration_ms"
                                    ],
                            }
                        )
                    )

                    if not sent:
                        break

                # MARK: Finalize Completed

                if waiting_for_finalize:

                    await finish_dictation()

                    break

        except asyncio.CancelledError:

            pass

        except Exception as exc:

            print(
                "Transcript receiver error:",
                exc,
            )

    # MARK: - Start STT

    async def start_stt(
        keyterms: list[str] | None = None,
    ):

        nonlocal stt
        nonlocal transcript_task
        nonlocal waiting_for_finalize
        nonlocal finalize_timeout_task

        if stt is not None:
            return

        utterance_manager.reset()

        waiting_for_finalize = (
            False
        )

        if (
            finalize_timeout_task
            is not None
        ):

            finalize_timeout_task.cancel()

            finalize_timeout_task = (
                None
            )

        cleaned_keyterms = (
            clean_keyterms(
                keyterms
            )
        )

        stt = DeepgramSTT()

        try:

            await stt.connect(
                keyterms=
                    cleaned_keyterms
            )

            transcript_task = (
                asyncio.create_task(
                    receive_transcripts()
                )
            )

            await safely_send_json(
                {
                    "type":
                        "listening_started",

                    "keyterm_count":
                        len(
                            cleaned_keyterms
                        ),
                }
            )

            print(
                "FlowVoice STT started"
            )

            if cleaned_keyterms:

                print(
                    "Dictionary keyterms active:",
                    len(
                        cleaned_keyterms
                    ),
                )

                print(
                    "Keyterms:",
                    cleaned_keyterms,
                )

            else:

                print(
                    "No dictionary keyterms "
                    "for this session"
                )

        except Exception as exc:

            print(
                "Deepgram connection failed:",
                exc,
            )

            stt = None

            await safely_send_json(
                {
                    "type":
                        "error",

                    "message":
                        "Could not connect to STT service.",
                }
            )

    # MARK: - Stop STT

    async def stop_stt(
        close_stream: bool = True,
        stt_to_close:
            DeepgramSTT | None = None,
    ):

        nonlocal stt
        nonlocal transcript_task
        nonlocal waiting_for_finalize
        nonlocal finalize_timeout_task

        waiting_for_finalize = (
            False
        )

        if (
            finalize_timeout_task
            is not None
        ):

            finalize_timeout_task.cancel()

            finalize_timeout_task = (
                None
            )

        current_task = (
            asyncio.current_task()
        )

        if (
            transcript_task
            is not None
            and transcript_task
            is not current_task
        ):

            transcript_task.cancel()

            try:

                await transcript_task

            except asyncio.CancelledError:

                pass

            except Exception as exc:

                print(
                    "Transcript task cleanup error:",
                    exc,
                )

        transcript_task = None

        target_stt = (
            stt_to_close
            or stt
        )

        if (
            target_stt is not None
            and target_stt is stt
        ):

            stt = None

        if target_stt is not None:

            if close_stream:

                try:

                    await target_stt.close_stream()

                except Exception as exc:

                    print(
                        "Deepgram CloseStream cleanup error:",
                        exc,
                    )

            try:

                await target_stt.close()

            except Exception as exc:

                print(
                    "Deepgram cleanup error:",
                    exc,
                )

        utterance_manager.reset()

        await safely_send_json(
            {
                "type":
                    "listening_stopped",
            }
        )

        print(
            "FlowVoice STT stopped"
        )

    # MARK: - Finalize

    async def request_finalize():

        nonlocal waiting_for_finalize
        nonlocal finalize_timeout_task

        if stt is None:

            await safely_send_json(
                {
                    "type":
                        "dictation_complete",
                }
            )

            return

        if waiting_for_finalize:
            return

        waiting_for_finalize = (
            True
        )

        print(
            "Finalizing dictation..."
        )

        try:

            await stt.finalize()

        except Exception as exc:

            print(
                "Deepgram finalize failed:",
                exc,
            )

            utterance = (
                utterance_manager
                .build_utterance()
            )

            if utterance is not None:

                await safely_send_json(
                    {
                        "type":
                            "utterance_final",

                        "text":
                            utterance[
                                "text"
                            ],

                        "duration_ms":
                            utterance[
                                "duration_ms"
                            ],
                    }
                )

            await finish_dictation()

            return

        finalize_timeout_task = (
            asyncio.create_task(
                finalize_timeout()
            )
        )

    # MARK: - Main Receive Loop

    try:

        while True:

            message = (
                await websocket.receive()
            )

            if (
                message.get(
                    "type"
                )
                == "websocket.disconnect"
            ):
                break

            text = (
                message.get(
                    "text"
                )
            )

            if text is not None:

                print(
                    "Control message:",
                    text,
                )

                # --------------------------------
                # New JSON control format
                #
                # {
                #   "type": "start_listening",
                #   "keyterms": [
                #       "FlowVoice",
                #       "MongoDB"
                #   ]
                # }
                # --------------------------------

                try:

                    payload = json.loads(
                        text
                    )

                except json.JSONDecodeError:

                    payload = None

                if isinstance(
                    payload,
                    dict,
                ):

                    message_type = (
                        payload.get(
                            "type"
                        )
                    )

                    if (
                        message_type
                        == "start_listening"
                    ):

                        keyterms = (
                            clean_keyterms(
                                payload.get(
                                    "keyterms",
                                    [],
                                )
                            )
                        )

                        await start_stt(
                            keyterms=
                                keyterms
                        )

                        continue

                    if (
                        message_type
                        == "stop_listening"
                    ):

                        await request_finalize()

                        continue

                # --------------------------------
                # Backward compatibility
                #
                # Existing macOS client can still
                # send plain strings while you
                # update FlowVoiceSocket.swift.
                # --------------------------------

                if (
                    text
                    == "start_listening"
                ):

                    await start_stt(
                        keyterms=[]
                    )

                    continue

                if (
                    text
                    == "stop_listening"
                ):

                    await request_finalize()

                    continue

            audio = (
                message.get(
                    "bytes"
                )
            )

            if (
                audio is not None
                and stt is not None
                and not waiting_for_finalize
            ):

                await stt.send_audio(
                    audio
                )

    except WebSocketDisconnect:

        pass

    except Exception as exc:

        print(
            "WebSocket error:",
            exc,
        )

    finally:

        print(
            "FlowVoice client disconnected"
        )

        await stop_stt()

        print(
            "FlowVoice session closed"
        )