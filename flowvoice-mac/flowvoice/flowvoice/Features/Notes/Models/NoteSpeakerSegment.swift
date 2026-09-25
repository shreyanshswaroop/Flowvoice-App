import Foundation

struct NoteSpeakerSegment:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID

    let speaker: Int
    let text: String

    let start: Double?
    let end: Double?

    var displaySpeakerName: String {

        speaker == 0
            ? "You"
            : "Them"
    }

    var displaySpeakerInitial: String {

        speaker == 0
            ? "Y"
            : "T"
    }

    init(
        id: UUID = UUID(),
        speaker: Int,
        text: String,
        start: Double?,
        end: Double?
    ) {

        self.id =
            id

        self.speaker =
            speaker

        self.text =
            text

        self.start =
            start

        self.end =
            end
    }

    enum CodingKeys:
        String,
        CodingKey {

        case speaker
        case text
        case start
        case end
    }

    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )

        id =
            UUID()

        speaker =
            try container.decode(
                Int.self,
                forKey:
                    .speaker
            )

        text =
            try container.decode(
                String.self,
                forKey:
                    .text
            )

        start =
            try container
                .decodeIfPresent(
                    Double.self,
                    forKey:
                        .start
                )

        end =
            try container
                .decodeIfPresent(
                    Double.self,
                    forKey:
                        .end
                )
    }
}
