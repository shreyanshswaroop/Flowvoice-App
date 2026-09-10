import SwiftUI

struct SidebarRow: View {

    let tab: SidebarTab
    let isSelected: Bool
    let isCollapsed: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {

        Button(
            action: action
        ) {

            if isCollapsed {
                collapsedRow
            } else {
                expandedRow
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in

            withAnimation(
                .easeOut(
                    duration: 0.12
                )
            ) {
                isHovering = hovering
            }
        }
        .help(
            isCollapsed
                ? tab.rawValue
                : ""
        )
    }

    // MARK: - Expanded

    private var expandedRow: some View {

        HStack(
            spacing: 10
        ) {

            Image(
                systemName: tab.icon
            )
            .font(
                .system(
                    size: 15,
                    weight: .medium
                )
            )
            .symbolRenderingMode(
                .hierarchical
            )
            .frame(
                width: 20
            )

            Text(
                tab.rawValue
            )
            .font(
                .system(
                    size: 14,
                    weight: .regular
                )
            )

            Spacer()
        }
        .foregroundStyle(
            FlowVoiceTheme.primaryText
        )
        .opacity(
            isSelected
                ? 1.0
                : isHovering
                    ? 0.82
                    : 0.46
        )
        .padding(
            .horizontal,
            11
        )
        .frame(
            height: 38
        )
        .background {
            expandedBackground
        }
        .contentShape(
            Rectangle()
        )
    }

    // MARK: - Collapsed

    private var collapsedRow: some View {

        HStack {

            Spacer(
                minLength: 0
            )

            Image(
                systemName: tab.icon
            )
            .font(
                .system(
                    size: 17,
                    weight: .medium
                )
            )
            .symbolRenderingMode(
                .hierarchical
            )
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .opacity(
                isSelected
                    ? 1.0
                    : isHovering
                        ? 0.82
                        : 0.46
            )
            .frame(
                width: 42,
                height: 42
            )

            Spacer(
                minLength: 0
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .background {
            collapsedBackground
        }
        .contentShape(
            Rectangle()
        )
    }

    // MARK: - Expanded Background

    @ViewBuilder
    private var expandedBackground: some View {

        if isHovering && !isSelected {

            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.hoverSurface
            )
        }
    }

    // MARK: - Collapsed Background

    @ViewBuilder
    private var collapsedBackground: some View {

        if isHovering && !isSelected {

            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.hoverSurface
            )
            .frame(
                width: 42,
                height: 42
            )
        }
    }
}
