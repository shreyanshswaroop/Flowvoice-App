import SwiftUI

struct KeepNotePrompt: View {
    let wordCount: Int
    let onClose: () -> Void
    let onDiscard: () -> Void
    let onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(red: 0.96, green: 0.79, blue: 0.27))
                Text(wordCount < 8 ? "Started by mistake?" : "Keep this note?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 8)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                        .contentShape(Circle())
                }
                .keyboardShortcut(.cancelAction)
                .help("Close without discarding")
                .accessibilityLabel("Close without discarding")
            }

            Text(wordCount < 8
                 ? "Only a few words were captured. Keep this note or discard it?"
                 : "FlowVoice captured \(wordCount) words. Keep this note or discard it?")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.68))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Spacer()
                Button(action: onDiscard) {
                    Text("Discard")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: 8))
                }
                Button(action: onKeep) {
                    Text("Keep")
                        .foregroundStyle(Color(white: 0.15))
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(Color(white: 0.93), in: RoundedRectangle(cornerRadius: 8))
                }
                .keyboardShortcut(.defaultAction)
            }
            .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(NoteActionButtonStyle())
        .padding(20)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 6)
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
    }
}
