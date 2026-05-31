import SwiftUI

struct PremiumView: View {
    @Binding var selectedTab: AppTab
    @State private var selectedPlan: String = "yearly"
    @State private var activeWebDestination: WebDestination?
    @State private var activeLegalSheet: NativeLegalDestination?
    @State private var showMailFallback = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject private var tabNavigation: TabNavigationManager

    var body: some View {
        ZStack {
            // Gold-tinted dark background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.220, green: 0.160, blue: 0.040).opacity(0.7), location: 0),
                    .init(color: Color(red: 0.133, green: 0.114, blue: 0.063), location: 0.5),
                    .init(color: Color(red: 0.078, green: 0.039, blue: 0.114), location: 1.0)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button(action: {
                        selectedTab = tabNavigation.goBack(from: selectedTab, fallback: .home)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(AppTheme.Spacing.radiusFull)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)

                // Hero
                VStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .blur(radius: 20).frame(width: 100, height: 100)
                        Circle()
                            .fill(LinearGradient(colors: [AppTheme.Colors.gold.opacity(0.25), AppTheme.Colors.gold.opacity(0.05)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(Circle().strokeBorder(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
                            .frame(width: 72, height: 72)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.2), radius: 20)
                        Image(systemName: "sparkles").font(.system(size: 24, weight: .semibold)).foregroundColor(AppTheme.Colors.gold)
                    }
                    Text(locManager.t("premium.unlock_full")).font(AppTheme.Typography.heading1).foregroundColor(.white)
                    Text(locManager.t("premium.hero_subtitle"))
                        .font(AppTheme.Typography.bodyEm).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            FeatureItemView(icon: "mic.fill",           title: locManager.t("premium.feature.unlimited_recordings"), subtitle: locManager.t("premium.feature.unlimited_recordings_sub"))
                            FeatureItemView(icon: "brain.head.profile", title: locManager.t("premium.feature.deep_ai"), subtitle: locManager.t("premium.feature.deep_ai_sub"))
                            FeatureItemView(icon: "square.grid.2x2",   title: locManager.t("premium.feature.heatmaps"), subtitle: locManager.t("premium.feature.heatmaps_sub"))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 150), spacing: AppTheme.Spacing.sm)],
                            spacing: AppTheme.Spacing.sm
                        ) {
                            planCard("monthly", title: locManager.t("premium.monthly"), desc: locManager.t("premium.flexible_plan"), price: "₹99", period: locManager.t("premium.period_month"), badge: nil)
                            planCard("yearly",  title: locManager.t("premium.yearly"),  desc: locManager.t("premium.save_20"),      price: "₹999", period: locManager.t("premium.period_year"), badge: locManager.t("premium.best_value"))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        Button(action: {}) {
                            Text(locManager.t("premium.start_trial")).font(AppTheme.Typography.bodyEm)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(AppTheme.Colors.gold).foregroundColor(.black)
                                .cornerRadius(AppTheme.Spacing.radiusFull)
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)

                        Text(String(format: locManager.t("premium.trial_footer_fmt"),
                                    selectedPlan == "yearly" ? "₹999/year" : "₹99/month"))
                            .font(AppTheme.Typography.label).foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center).padding(.horizontal, AppTheme.Spacing.md)

                        ViewThatFits(in: .horizontal) {
                            legalActions
                            legalActionsStack
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }
            }
        }
        .sheet(item: $activeWebDestination) { destination in
            LegalWebViewSheet(destination: destination)
        }
        .sheet(item: $activeLegalSheet) { destination in
            NativeLegalSheet(destination: destination)
                .environmentObject(locManager)
        }
        .confirmationDialog(
            locManager.t("support.mail_unavailable_title"),
            isPresented: $showMailFallback,
            titleVisibility: .visible
        ) {
            Button(locManager.t("support.copy_email")) {
                ExternalNavigator.copySupportEmail()
            }
            Button(locManager.t("about.website")) {
                activeWebDestination = .website
            }
            Button(locManager.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(locManager.t("support.mail_unavailable_message", AppConstants.Links.supportEmail))
        }
    }

    @ViewBuilder
    private var legalActions: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button(action: {
                if !ExternalNavigator.openSupportAction(.contactSupport, localization: locManager) {
                    showMailFallback = true
                }
            }) {
                Text(locManager.t("premium.restore_purchase"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(.white.opacity(0.3))
            }
            Text("•").foregroundColor(.white.opacity(0.2))
            Button(action: { activeLegalSheet = .terms }) {
                Text(locManager.t("auth.terms"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(.white.opacity(0.3))
            }
            Text("•").foregroundColor(.white.opacity(0.2))
            Button(action: { activeLegalSheet = .privacy }) {
                Text(locManager.t("auth.privacy"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private var legalActionsStack: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button(action: {
                if !ExternalNavigator.openSupportAction(.contactSupport, localization: locManager) {
                    showMailFallback = true
                }
            }) {
                Text(locManager.t("premium.restore_purchase"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(.white.opacity(0.3))
            }
            HStack(spacing: AppTheme.Spacing.sm) {
                Button(action: { activeLegalSheet = .terms }) {
                    Text(locManager.t("auth.terms"))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(.white.opacity(0.3))
                }
                Text("•").foregroundColor(.white.opacity(0.2))
                Button(action: { activeLegalSheet = .privacy }) {
                    Text(locManager.t("auth.privacy"))
                        .font(AppTheme.Typography.label)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    @ViewBuilder
    private func planCard(_ plan: String, title: String, desc: String, price: String, period: String, badge: String?) -> some View {
        let isActive = selectedPlan == plan
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                if isActive {
                    Circle().fill(AppTheme.Colors.gold).frame(width: 20, height: 20)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.black))
                } else {
                    Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5).frame(width: 20, height: 20)
                }
                Text(title).font(AppTheme.Typography.caption).fontWeight(.semibold).foregroundColor(.white)
                Spacer()
                if let badge = badge {
                    Text(badge).font(AppTheme.Typography.micro).fontWeight(.bold).tracking(0.5)
                        .foregroundColor(.black).padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 3)
                        .background(AppTheme.Colors.gold).cornerRadius(4)
                }
            }
            Text(desc).font(AppTheme.Typography.label).foregroundColor(isActive ? AppTheme.Colors.gold : .white.opacity(0.4))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(price).font(AppTheme.Typography.heading3).foregroundColor(isActive ? AppTheme.Colors.gold : .white)
                Text(period).font(AppTheme.Typography.label).foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(Color(red: 0.100, green: 0.080, blue: 0.050).opacity(0.8))
        .cornerRadius(AppTheme.Spacing.radiusMd)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd)
            .strokeBorder(isActive ? AppTheme.Colors.gold.opacity(0.5) : .white.opacity(0.1), lineWidth: 1))
        .onTapGesture { selectedPlan = plan }
    }
}

struct FeatureItemView: View {
    let icon: String; let title: String; let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.Colors.gold).frame(width: 40, height: 40)
                .background(AppTheme.Colors.gold.opacity(0.12)).cornerRadius(AppTheme.Spacing.radiusSm)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTheme.Typography.caption).fontWeight(.semibold).foregroundColor(.white)
                Text(subtitle).font(AppTheme.Typography.label).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundColor(AppTheme.Colors.gold)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(AppTheme.Spacing.radiusMd)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusMd).strokeBorder(.white.opacity(0.05), lineWidth: 1))
    }
}
