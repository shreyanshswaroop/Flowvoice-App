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


# MARK: - Transcript De-duplication

def normalize_transcript_text(
    value: str,
) -> str:

    return " ".join(
        value
        .strip()
        .lower()
        .split()
    )


def normalized_transcript_words(
    value: str,
) -> list[str]:

    normalized = []
    current = []

    for character in value.lower():

        if character.isalnum():
            current.append(
                character
            )
            continue

        if current:
            normalized.append(
                "".join(
                    current
                )
            )
            current = []

    if current:
        normalized.append(
            "".join(
                current
            )
        )

    return normalized


def word_overlap_count(
    first: list[str],
    second: list[str],
) -> int:

    maximum = min(
        len(first),
        len(second),
    )

    for count in range(
        maximum,
        0,
        -1,
    ):

        if first[-count:] == second[:count]:
            return count

    return 0


def word_similarity(
    first: list[str],
    second: list[str],
) -> float:

    if not first or not second:
        return 0.0

    first_set = set(
        first
    )

    second_set = set(
        second
    )

    shared = len(
        first_set
        & second_set
    )

    smaller = min(
        len(first_set),
        len(second_set),
    )

    if smaller == 0:
        return 0.0

    return shared / smaller


def looks_like_same_audio(
    first: list[str],
    second: list[str],
) -> bool:

    if min(len(first), len(second)) < 4:
        return False

    if word_similarity(first, second) >= 0.58:
        return True

    overlap = max(
        word_overlap_count(
            first,
            second,
        ),
        word_overlap_count(
            second,
            first,
        ),
    )

    return overlap >= min(
        5,
        min(len(first), len(second)),
    )


def is_redundant_audio_segment(
    previous: list[str],
    incoming: list[str],
) -> bool:

    if not previous or not incoming:
        return False

    if previous == incoming:
        return True

    if len(incoming) <= len(previous):

        for index in range(
            0,
            len(previous) - len(incoming) + 1,
        ):

            if previous[index:index + len(incoming)] == incoming:
                return True

    return (
        len(incoming) <= 8
        and word_similarity(previous, incoming) >= 0.7
    )


def split_interleaved_stereo_i16(
    audio: bytes,
) -> tuple[bytes, bytes]:

    frame_size = 4

    usable_length = (
        len(audio)
        - (len(audio) % frame_size)
    )

    microphone = bytearray(
        usable_length // 2
    )

    system = bytearray(
        usable_length // 2
    )

    mic_offset = 0
    system_offset = 0

    for offset in range(
        0,
        usable_length,
        frame_size,
    ):

        microphone[mic_offset:mic_offset + 2] = (
            audio[offset:offset + 2]
        )

        system[system_offset:system_offset + 2] = (
            audio[offset + 2:offset + 4]
        )

        mic_offset += 2
        system_offset += 2

    return (
        bytes(microphone),
        bytes(system),
    )


def has_voice_energy(
    audio: bytes,
) -> bool:

    usable_length = (
        len(audio)
        - (len(audio) % 2)
    )

    if usable_length <= 0:
        return False

    sample_count = 0
    square_sum = 0
    peak = 0

    for offset in range(
        0,
        usable_length,
        2,
    ):

        sample = int.from_bytes(
            audio[offset:offset + 2],
            byteorder="little",
            signed=True,
        )

        magnitude = abs(
            sample
        )

        peak = max(
            peak,
            magnitude,
        )

        square_sum += (
            sample
            * sample
        )

        sample_count += 1

    if sample_count == 0:
        return False

    rms = (
        square_sum
        / sample_count
    ) ** 0.5

    return (
        rms >= 90
        or peak >= 650
    )


def audio_rms(
    audio: bytes,
) -> float:

    usable_length = (
        len(audio)
        - (len(audio) % 2)
    )

    if usable_length <= 0:
        return 0.0

    sample_count = 0
    square_sum = 0

    for offset in range(
        0,
        usable_length,
        2,
    ):

        sample = int.from_bytes(
            audio[offset:offset + 2],
            byteorder="little",
            signed=True,
        )

        square_sum += (
            sample
            * sample
        )

        sample_count += 1

    if sample_count == 0:
        return 0.0

    return (
        square_sum
        / sample_count
    ) ** 0.5


def system_audio_is_primary(
    microphone_audio: bytes,
    system_audio: bytes,
) -> bool:

    system_level = audio_rms(
        system_audio
    )

    if system_level < 90:
        return False

    microphone_level = audio_rms(
        microphone_audio
    )

    return (
        system_level >= microphone_level * 0.55
        or system_level >= 180
    )


def word_window_key(
    words: list[dict],
) -> tuple | None:

    if not words:
        return None

    cleaned_words = []

    for word in words:

        value = (
            word.get(
                "word"
            )
            or word.get(
                "punctuated_word"
            )
            or ""
        )

        value = normalize_transcript_text(
            str(value)
        )

        if value:
            cleaned_words.append(
                value
            )

    if not cleaned_words:
        return None

    start = words[0].get(
        "start"
    )

    end = words[-1].get(
        "end"
    )

    rounded_start = (
        round(float(start), 2)
        if isinstance(start, (int, float))
        else None
    )

    rounded_end = (
        round(float(end), 2)
        if isinstance(end, (int, float))
        else None
    )

    return (
        rounded_start,
        rounded_end,
        tuple(cleaned_words),
    )


# MARK: - Speaker Segments


def build_speaker_segments(
    words: list[dict],
    speaker_offset: int = 0,
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
                            current_speaker + speaker_offset,

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
                    current_speaker + speaker_offset,

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

    speaker_stt: DeepgramSTT | None = (
        None
    )

    live_system_stt: DeepgramSTT | None = (
        None
    )

    active_audio_mode = "dictation"

    transcript_tasks: (
        list[asyncio.Task]
    ) = []

    utterance_manager = (
        UtteranceManager()
    )

    waiting_for_finalize = (
        False
    )

    finalize_timeout_task: (
        asyncio.Task | None
    ) = None


    sent_final_transcript_keys = (
        set()
    )

    sent_speaker_window_keys = (
        set()
    )

    visible_speaker_by_channel = {}

    recent_channel_segments = []

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

    async def receive_transcripts(
        stt_source: DeepgramSTT,
        fixed_speaker: int | None = None,
        emit_transcript_events: bool = True,
        emit_partial_events: bool = True,
        emit_speaker_segments: bool = True,
        speaker_offset: int = 0,
    ):

        nonlocal waiting_for_finalize

        if stt_source is None:
            return

        try:

            async for result in (
                stt_source.receive()
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

                if is_final or speech_final or from_finalize:

                    print(
                        f"Transcript event "
                        f"| final: {is_final} "
                        f"| speech_final: {speech_final} "
                        f"| from_finalize: {from_finalize} "
                        f"| words: {len(words)}"
                    )

                # MARK: Transcript Events

                if transcript:

                    transcript_key = (
                        normalize_transcript_text(
                            transcript
                        )
                        if is_final
                        else None
                    )

                    should_send_transcript = (
                        (
                            emit_partial_events
                            and not is_final
                        )
                        or (
                            emit_transcript_events
                            and is_final
                            and transcript_key
                            and transcript_key
                            not in sent_final_transcript_keys
                        )
                    )

                    if emit_transcript_events and is_final and transcript_key:

                        sent_final_transcript_keys.add(
                            transcript_key
                        )

                        utterance_manager.add_final_segment(
                            transcript
                        )

                    if should_send_transcript:

                        sent = (
                            await safely_send_json(
                                {
                                    "type":
                                        (
                                            "transcript_final"
                                            if is_final
                                            else "transcript_partial"
                                        ),

                                    "text":
                                        transcript,

                                    "is_final":
                                        is_final,

                                    "speech_final":
                                        speech_final,

                                    "from_finalize":
                                        from_finalize,

                                    "speaker":
                                        (
                                            fixed_speaker
                                            if fixed_speaker is not None
                                            else speaker_offset
                                        ),
                                }
                            )
                        )

                        if not sent:
                            break

                # MARK: Channel-owned Speaker Segment

                if (
                    emit_speaker_segments
                    and fixed_speaker is not None
                    and is_final
                    and transcript
                ):

                    transcript_words = (
                        normalized_transcript_words(
                            transcript
                        )
                    )

                    matched_segment = None

                    for recent_segment in reversed(
                        recent_channel_segments
                    ):

                        if (
                            recent_segment["channel"]
                            == fixed_speaker
                        ):
                            continue

                        if looks_like_same_audio(
                            recent_segment["words"],
                            transcript_words,
                        ):

                            matched_segment = recent_segment
                            break

                    if matched_segment is not None:

                        visible_speaker = matched_segment[
                            "speaker"
                        ]

                        if is_redundant_audio_segment(
                            matched_segment["words"],
                            transcript_words,
                        ):
                            continue

                    else:

                        visible_speaker = (
                            visible_speaker_by_channel
                            .setdefault(
                                fixed_speaker,
                                len(
                                    visible_speaker_by_channel
                                ),
                            )
                        )

                    segment_key = (
                        visible_speaker,
                        normalize_transcript_text(
                            transcript
                        ),
                    )

                    if segment_key not in sent_speaker_window_keys:

                        sent_speaker_window_keys.add(
                            segment_key
                        )

                        recent_channel_segments.append(
                            {
                                "channel":
                                    fixed_speaker,

                                "speaker":
                                    visible_speaker,

                                "words":
                                    transcript_words,
                            }
                        )

                        del recent_channel_segments[:-24]

                        start = result.get(
                            "start"
                        )

                        duration = result.get(
                            "duration"
                        )

                        end = None

                        if isinstance(start, (int, float)):
                            end = start

                            if isinstance(duration, (int, float)):
                                end = start + duration

                        sent = (
                            await safely_send_json(
                                {
                                    "type":
                                        "speaker_segments",

                                    "segments":
                                        [
                                            {
                                                "speaker":
                                                    visible_speaker,

                                                "text":
                                                    transcript,

                                                "start":
                                                    start,

                                                "end":
                                                    end,
                                            }
                                        ],
                                }
                            )
                        )

                        if not sent:
                            break

                # MARK: Speaker Diarization

                if (
                    emit_speaker_segments
                    and fixed_speaker is None
                    and is_final
                    and words
                ):

                    speaker_window_key = (
                        word_window_key(
                            words
                        )
                    )

                    should_send_speaker_segments = (
                        speaker_window_key is None
                        or speaker_window_key
                        not in sent_speaker_window_keys
                    )

                    if should_send_speaker_segments:

                        speaker_segments = (
                            build_speaker_segments(
                                words,
                                speaker_offset=speaker_offset,
                            )
                        )

                        if speaker_segments:

                            if speaker_window_key is not None:

                                sent_speaker_window_keys.add(
                                    speaker_window_key
                                )

                            print(
                                "Speaker segment batch:",
                                len(speaker_segments),
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
                        "Utterance finalized"
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

                if (
                    waiting_for_finalize
                    and fixed_speaker is None
                ):

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
        audio_mode: str = "dictation",
    ):

        nonlocal stt
        nonlocal speaker_stt
        nonlocal live_system_stt
        nonlocal active_audio_mode
        nonlocal transcript_tasks
        nonlocal waiting_for_finalize
        nonlocal finalize_timeout_task
        nonlocal sent_final_transcript_keys
        nonlocal sent_speaker_window_keys

        if stt is not None:
            return

        utterance_manager.reset()

        sent_final_transcript_keys.clear()
        sent_speaker_window_keys.clear()
        visible_speaker_by_channel.clear()
        recent_channel_segments.clear()

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

        if audio_mode not in {
            "dictation",
            "meeting_dual_channel",
        }:

            audio_mode = "dictation"

        active_audio_mode = audio_mode
        stt = DeepgramSTT()

        if audio_mode == "meeting_dual_channel":
            speaker_stt = DeepgramSTT()
            live_system_stt = DeepgramSTT()
        else:
            speaker_stt = None
            live_system_stt = None

        try:

            await stt.connect(
                keyterms=
                    cleaned_keyterms,
                audio_mode=
                    audio_mode,
                diarize=(
                    audio_mode != "meeting_dual_channel"
                ),
            )

            if speaker_stt is not None:

                await speaker_stt.connect(
                    keyterms=
                        cleaned_keyterms,
                    audio_mode=
                        audio_mode,
                    diarize=True,
                )

            if live_system_stt is not None:

                await live_system_stt.connect(
                    keyterms=
                        cleaned_keyterms,
                    audio_mode=
                        audio_mode,
                    diarize=False,
                )

            transcript_tasks = []

            if audio_mode == "meeting_dual_channel":

                transcript_tasks.append(
                    asyncio.create_task(
                        receive_transcripts(
                            stt,
                            fixed_speaker=0,
                            emit_transcript_events=False,
                            emit_partial_events=True,
                        )
                    )
                )

                if live_system_stt is not None:

                    transcript_tasks.append(
                        asyncio.create_task(
                            receive_transcripts(
                                live_system_stt,
                                fixed_speaker=1,
                                emit_transcript_events=False,
                                emit_partial_events=True,
                                emit_speaker_segments=False,
                            )
                        )
                    )

                if speaker_stt is not None:

                    transcript_tasks.append(
                        asyncio.create_task(
                            receive_transcripts(
                                speaker_stt,
                                fixed_speaker=None,
                                emit_transcript_events=False,
                                emit_partial_events=False,
                                speaker_offset=1,
                            )
                        )
                    )

            else:

                transcript_tasks.append(
                    asyncio.create_task(
                        receive_transcripts(
                            stt
                        )
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
            speaker_stt = None
            live_system_stt = None
            transcript_tasks = []

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
        nonlocal speaker_stt
        nonlocal live_system_stt
        nonlocal active_audio_mode
        nonlocal transcript_tasks
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

        tasks_to_cancel = list(
            transcript_tasks
        )

        for task in tasks_to_cancel:

            if task is current_task:
                continue

            task.cancel()

        for task in tasks_to_cancel:

            if task is current_task:
                continue

            try:

                await task

            except asyncio.CancelledError:

                pass

            except Exception as exc:

                print(
                    "Transcript task cleanup error:",
                    exc,
                )

        transcript_tasks = []

        targets = (
            [stt_to_close]
            if stt_to_close is not None
            else [stt, speaker_stt, live_system_stt]
        )

        if stt_to_close is None:
            stt = None
            speaker_stt = None
            live_system_stt = None
            active_audio_mode = "dictation"
        elif stt_to_close is stt:
            stt = None

        for target_stt in targets:

            if target_stt is None:
                continue

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

            if speaker_stt is not None:
                await speaker_stt.finalize()

            if live_system_stt is not None:
                await live_system_stt.finalize()

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

                        audio_mode = (
                            payload.get(
                                "audio_mode",
                                "dictation",
                            )
                        )

                        if not isinstance(
                            audio_mode,
                            str,
                        ):

                            audio_mode = "dictation"

                        await start_stt(
                            keyterms=
                                keyterms,
                            audio_mode=
                                audio_mode
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

                if (
                    active_audio_mode == "meeting_dual_channel"
                    and speaker_stt is not None
                ):

                    microphone_audio, system_audio = (
                        split_interleaved_stereo_i16(
                            audio
                        )
                    )

                    system_has_voice = has_voice_energy(
                        system_audio
                    )

                    microphone_has_voice = has_voice_energy(
                        microphone_audio
                    )

                    system_level = audio_rms(
                        system_audio
                    )

                    microphone_level = audio_rms(
                        microphone_audio
                    )

                    if system_has_voice:

                        if live_system_stt is not None:
                            await live_system_stt.send_audio(
                                system_audio
                            )

                        await speaker_stt.send_audio(
                            system_audio
                        )

                    if (
                        microphone_has_voice
                        and (
                            not system_has_voice
                            or microphone_level >= system_level * 1.85
                        )
                    ):

                        await stt.send_audio(
                            microphone_audio
                        )

                else:

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
