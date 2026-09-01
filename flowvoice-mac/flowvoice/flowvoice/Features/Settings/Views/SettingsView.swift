import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var controller: FlowVoiceController
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedSection: SettingsSection = .general

    var body: some View {

        ZStack {

            Color.black
                .opacity(0.42)
                .ignoresSafeArea()

            FlowVoiceTheme.pageBackground
            .ignoresSafeArea()

            SettingsModalView(
                selectedSection: $selectedSection
            )
            .environmentObject(controller)
            .environmentObject(authManager)
            .padding(
                .horizontal,
                46
            )
            .padding(
                .vertical,
                42
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}
