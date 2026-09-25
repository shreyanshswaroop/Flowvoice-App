import time


class UtteranceManager:
    def __init__(self):
        self.final_segments: list[str] = []
        self.final_segment_keys: set[str] = set()
        self.started_at: float | None = None

    def start(self):
        if self.started_at is None:
            self.started_at = time.perf_counter()

    def add_final_segment(
        self,
        text: str,
    ):
        cleaned = text.strip()

        if not cleaned:
            return

        key = " ".join(
            cleaned
            .lower()
            .split()
        )

        if key in self.final_segment_keys:
            return

        self.start()

        self.final_segment_keys.add(
            key
        )

        self.final_segments.append(
            cleaned
        )

    def build_utterance(
        self,
    ) -> dict | None:
        if not self.final_segments:
            return None

        text = " ".join(
            self.final_segments
        ).strip()

        duration_ms = None

        if self.started_at is not None:
            duration_ms = int(
                (
                    time.perf_counter()
                    - self.started_at
                )
                * 1000
            )

        result = {
            "text": text,
            "duration_ms": duration_ms,
        }

        self.reset()

        return result

    def reset(self):
        self.final_segments = []
        self.started_at = None