import SwiftUI
import UserNotifications

@Observable
@MainActor
private final class NotificationSettingsViewModel {
    var preferences: NotificationPreferences?
    private(set) var isLoading = false
    private(set) var error: AppError?
    @ObservationIgnored private let notifications: any NotificationServicing

    init(notifications: any NotificationServicing) { self.notifications = notifications }

    func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { preferences = try await notifications.preferences() }
        catch { self.error = AppError.from(error) }
    }

    func save() async {
        guard let preferences else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do { self.preferences = try await notifications.updatePreferences(preferences) }
        catch { self.error = AppError.from(error) }
    }
}

struct NotificationSettingsView: View {
    @State private var model: NotificationSettingsViewModel

    init(notifications: any NotificationServicing) {
        _model = State(initialValue: NotificationSettingsViewModel(notifications: notifications))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.md) {
                if let error = model.error {
                    EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error))
                }
                if model.preferences != nil {
                    toggle("notifications.master", keyPath: \.masterEnabled)
                        .onChange(of: model.preferences?.masterEnabled) { old, new in
                            if old == false, new == true {
                                Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
                            }
                        }
                    toggle("notifications.daily", keyPath: \.dailyRemindersEnabled)
                    toggle("notifications.community", keyPath: \.communityEnabled)
                    toggle("notifications.achievements", keyPath: \.achievementsEnabled)
                    toggle("notifications.insights", keyPath: \.insightsEnabled)
                    toggle("notifications.mood", keyPath: \.moodAlertsEnabled)
                    toggle("notifications.capsules", keyPath: \.capsulesEnabled)
                    toggle("notifications.coach", keyPath: \.coachEnabled)
                    toggle("notifications.system", keyPath: \.systemEnabled)
                    if let hour = model.preferences?.preferredLocalHour {
                        Stepper(value: hourBinding, in: 0...23) {
                            Text(String(format: String(localized: "notifications.hour"), hour))
                                .echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                        }
                        .padding(AppTheme.space.sm)
                        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md).fill(AppTheme.color.bg.surface))
                    }
                    EchoButton("common.save", fullWidth: true, isLoading: model.isLoading) { Task { await model.save() } }
                } else if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("notifications.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }

    private func toggle(_ title: LocalizedStringKey,
                        keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> some View {
        Toggle(title, isOn: Binding(
            get: { model.preferences?[keyPath: keyPath] ?? false },
            set: { model.preferences?[keyPath: keyPath] = $0 }
        ))
        .tint(AppTheme.color.accent.primary)
        .padding(AppTheme.space.sm)
        .background(RoundedRectangle(cornerRadius: AppTheme.radius.md).fill(AppTheme.color.bg.surface))
    }

    private var hourBinding: Binding<Int> {
        Binding(get: { model.preferences?.preferredLocalHour ?? 9 },
                set: { model.preferences?.preferredLocalHour = $0 })
    }
}
