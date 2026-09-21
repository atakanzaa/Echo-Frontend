import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @State private var showsSignOut = false
    @State private var showsDeleteFirst = false
    @State private var showsDeleteFinal = false
    @State private var isDeleting = false
    @State private var error: AppError?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.layout.sectionGap) {
                if let error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error))
                }
                appearanceSection
                languageSection
                privacySection
                legalSection
                accountSection
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("settings.signOutTitle", isPresented: $showsSignOut) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.signOut", role: .destructive) { Task { await environment.session.signOut() } }
        }
        .alert("settings.deleteFirstTitle", isPresented: $showsDeleteFirst) {
            Button("common.cancel", role: .cancel) {}
            Button("common.continue", role: .destructive) {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    showsDeleteFinal = true
                }
            }
        } message: { Text("settings.deleteFirstMessage") }
        .alert("settings.deleteFinalTitle", isPresented: $showsDeleteFinal) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.deleteAccount", role: .destructive) { Task { await deleteAccount() } }
        } message: { Text("settings.deleteFinalMessage") }
    }

    private var appearanceSection: some View {
        section("settings.appearance") {
            Picker("settings.theme", selection: appearanceBinding) {
                Text("settings.theme.system").tag(AppAppearance.system)
                Text("settings.theme.light").tag(AppAppearance.light)
                Text("settings.theme.dark").tag(AppAppearance.dark)
            }
            .pickerStyle(.segmented)
            .padding(AppTheme.space.sm)
        }
    }

    private var languageSection: some View {
        section("settings.language") {
            Picker("settings.language", selection: languageBinding) {
                Text("settings.language.tr").tag(AppLanguage.turkish)
                Text("settings.language.en").tag(AppLanguage.english)
            }
            .pickerStyle(.segmented)
            .padding(AppTheme.space.sm)
        }
    }

    private var privacySection: some View {
        section("settings.privacy") {
            row("settings.notifications", icon: "bell") { router.push(.notificationSettings) }
            EchoDivider(insetLeading: 60)
            row("settings.blockedAuthors", icon: "hand.raised") { router.push(.blockedAuthors) }
            EchoDivider(insetLeading: 60)
            row("settings.consent", icon: "checkmark.shield") { router.push(.privacyConsent) }
            EchoDivider(insetLeading: 60)
            Toggle(isOn: faceIDBinding) {
                EchoListRow("settings.faceID", leading: { EchoListRowIcon(systemImage: "faceid") })
            }
            .tint(AppTheme.color.accent.primary)
            .padding(.trailing, AppTheme.space.sm)
        }
    }

    @ViewBuilder private var legalSection: some View {
        if let config = environment.remoteConfig.config {
            section("settings.legal") {
                if let url = config.privacyPolicyURL {
                    Link(destination: url) { EchoListRow("settings.privacyPolicy") { EchoListRowIcon(systemImage: "hand.raised.square") } trailing: { EchoDisclosureIndicator() } }
                }
                if config.privacyPolicyURL != nil, config.termsURL != nil { EchoDivider(insetLeading: 60) }
                if let url = config.termsURL {
                    Link(destination: url) { EchoListRow("settings.terms") { EchoListRowIcon(systemImage: "doc.text") } trailing: { EchoDisclosureIndicator() } }
                }
                if let url = config.communityGuidelinesURL {
                    EchoDivider(insetLeading: 60)
                    Link(destination: url) { EchoListRow("settings.communityGuidelines") { EchoListRowIcon(systemImage: "person.2") } trailing: { EchoDisclosureIndicator() } }
                }
            }
        }
    }

    private var accountSection: some View {
        section("settings.account") {
            EchoListRow("settings.signOut", leading: {
                EchoListRowIcon(systemImage: "rectangle.portrait.and.arrow.right")
            })
                .echoRowButton { showsSignOut = true }
            EchoDivider(insetLeading: 60)
            EchoListRow("settings.deleteAccount", leading: {
                EchoListRowIcon(systemImage: "trash", tint: AppTheme.color.feedback.danger)
            })
                .echoRowButton { showsDeleteFirst = true }
                .disabled(isDeleting)
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space.xxs) {
            EchoSectionHeader(title)
            EchoCard(style: .flat, padding: 0) { VStack(spacing: 0) { content() } }
        }
    }

    private func row(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        EchoListRow(title) { EchoListRowIcon(systemImage: icon) } trailing: { EchoDisclosureIndicator() }
            .echoRowButton(action: action)
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { environment.language.language }, set: { language in
            Task { await environment.changeLanguage(to: language) }
        })
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(get: { environment.theme.appearance }, set: { environment.theme.appearance = $0 })
    }

    private var faceIDBinding: Binding<Bool> {
        Binding(get: { environment.appLock.isEnabled }, set: { enabled in
            Task {
                if enabled { await environment.appLock.enable() }
                else { environment.appLock.disable() }
            }
        })
    }

    private func deleteAccount() async {
        isDeleting = true
        error = nil
        do {
            try await environment.user.requestAccountDeletion(appleAuthorizationCode: nil)
            await environment.session.signOut()
        } catch {
            self.error = AppError.from(error)
        }
        isDeleting = false
    }
}
