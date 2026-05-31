import SwiftUI
import UIKit

struct NotificationsView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager
    @EnvironmentObject private var pushManager: PushNotificationManager

    @Environment(\.colorScheme) var colorScheme

    @StateObject private var prefsVM = NotificationPreferencesViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppScreenHeader(
                    title: locManager.t("nav.notifications"),
                    showBack: true,
                    onBack: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: .profile)
                    }
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        permissionCard
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, AppTheme.Spacing.xl)

                        if pushManager.permissionStatus.canDeliver, let prefs = prefsVM.preferences {
                            preferencesContent(prefs: prefs)
                        }

                        Text(locManager.t("notifications.system_note"))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.sm)
                    }
                }
            }
        }
        .task {
            await pushManager.refreshPermissionStatus()
            if pushManager.permissionStatus.canDeliver {
                await prefsVM.load()
                await prefsVM.syncCurrentTimezoneIfNeeded()
            }
        }
        .onChange(of: pushManager.permissionStatus.canDeliver) { _, canDeliver in
            if canDeliver {
                Task {
                    await prefsVM.load()
                    await prefsVM.syncCurrentTimezoneIfNeeded()
                }
            }
        }
    }

    @ViewBuilder
    private var permissionCard: some View {
        switch pushManager.permissionStatus {
        case .authorized, .provisional, .ephemeral:
            authorizedCard
        case .denied:
            deniedCard
        case .notDetermined:
            notDeterminedCard
        }
    }

    private var authorizedCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(locManager.t("notifications.permission_status_authorized"))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Spacer()
            }
            Text(locManager.t("notifications.permission_status_subtitle_authorized"))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }

    private var deniedCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
                Text(locManager.t("notifications.permission_denied_title"))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Spacer()
            }
            Text(locManager.t("notifications.permission_denied_subtitle"))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            Button(action: openIOSSettings) {
                Text(locManager.t("notifications.permission_denied_open_settings"))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.accent)
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }

    private var notDeterminedCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.accent)
                Text(locManager.t("notifications.permission_softprompt_title"))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                Spacer()
            }
            Text(locManager.t("notifications.permission_status_subtitle_not_determined"))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            Button(action: { Task { await pushManager.requestAuthorizationIfNeeded() } }) {
                Text(locManager.t("notifications.permission_softprompt_allow"))
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.accent)
                    .cornerRadius(AppTheme.Spacing.radiusMd)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }

    @ViewBuilder
    private func preferencesContent(prefs: APINotificationPreferences) -> some View {
        masterToggleSection(prefs: prefs)
            .padding(.horizontal, AppTheme.Spacing.md)

        categoriesSection(prefs: prefs)
            .padding(.horizontal, AppTheme.Spacing.md)

        timingSection(prefs: prefs)
            .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func masterToggleSection(prefs: APINotificationPreferences) -> some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "bell.fill",
                iconColor: AppTheme.Colors.accent,
                title: locManager.t("notifications.master_toggle"),
                subtitle: locManager.t("notifications.master_toggle_sub"),
                isOn: Binding(
                    get: { prefs.masterEnabled },
                    set: { newValue in Task { await prefsVM.setMaster(newValue) } }
                )
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated(colorScheme))
        .cornerRadius(AppTheme.Spacing.radiusLg)
    }

    private func categoriesSection(prefs: APINotificationPreferences) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(locManager.t("notifications.section.categories"))
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            VStack(spacing: 0) {
                ForEach(NotificationPreferencesViewModel.PreferenceCategory.allCases) { category in
                    toggleRow(
                        icon: category.iconName,
                        iconColor: AppTheme.Colors.accent,
                        title: locManager.t(category.titleKey),
                        subtitle: locManager.t(category.subtitleKey),
                        isOn: Binding(
                            get: { category.isEnabled(in: prefs) && prefs.masterEnabled },
                            set: { newValue in
                                Task { await prefsVM.setCategory(category, enabled: newValue) }
                            }
                        ),
                        disabled: !prefs.masterEnabled
                    )
                    if category != NotificationPreferencesViewModel.PreferenceCategory.allCases.last {
                        Divider().background(AppTheme.Colors.textMuted(colorScheme).opacity(0.15))
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusLg)
        }
    }

    private func timingSection(prefs: APINotificationPreferences) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(locManager.t("notifications.section.timing"))
                .font(AppTheme.Typography.label).fontWeight(.bold)
                .tracking(0.6)
                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(locManager.t("notifications.preferred_hour"))
                            .font(AppTheme.Typography.body).fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                        Text(locManager.t("notifications.preferred_hour_sub"))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    }
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.preferredLocalHour },
                        set: { newValue in Task { await prefsVM.setPreferredHour(newValue) } }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.Colors.accent)
                }

                Text(String(format: locManager.t("notifications.timezone_fmt"),
                            prefs.timezone ?? TimeZone.current.identifier))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated(colorScheme))
            .cornerRadius(AppTheme.Spacing.radiusLg)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    private func toggleRow(icon: String,
                           iconColor: Color,
                           title: String,
                           subtitle: String,
                           isOn: Binding<Bool>,
                           disabled: Bool = false) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(disabled ? AppTheme.Colors.textMuted(colorScheme) : iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(disabled ? 0.05 : 0.15))
                .cornerRadius(AppTheme.Spacing.radiusSm)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.body).fontWeight(.semibold)
                    .foregroundColor(disabled
                                     ? AppTheme.Colors.textMuted(colorScheme)
                                     : AppTheme.Colors.textPrimary(colorScheme))
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(AppTheme.Colors.accent)
                .disabled(disabled)
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.Layout.rowMinHeight)
        .padding(.vertical, 4)
    }

    private func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
