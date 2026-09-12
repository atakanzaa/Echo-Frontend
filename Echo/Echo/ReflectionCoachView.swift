import SwiftUI

struct ReflectionCoachView: View {
    let sessionId: String
    @ObservedObject var viewModel: CoachViewModel
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Colors.background(colorScheme).ignoresSafeArea()

            Circle()
                .fill(AppTheme.Colors.accent.opacity(0.07))
                .blur(radius: 60)
                .frame(width: 200, height: 200)
                .offset(x: -60, y: -80)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Button(action: { viewModel.closeSession(); dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(sessionTitle)
                            .font(AppTheme.Typography.heading3)
                            .foregroundColor(AppTheme.Colors.textPrimary(colorScheme))
                            .lineLimit(1)
                        if let session = currentSession, session.isActive {
                            HStack(spacing: 4) {
                                Circle().fill(AppTheme.Colors.success).frame(width: 6, height: 6)
                                Text(locManager.t("coach.active"))
                                    .font(AppTheme.Typography.micro).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.Colors.success)
                                    .tracking(0.5)
                            }
                        }
                    }
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)

                if viewModel.isLoadingChat {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.lg) {
                                Text(sessionTimestamp())
                                    .font(AppTheme.Typography.label).fontWeight(.medium)
                                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                    .padding(.horizontal, AppTheme.Spacing.sm).padding(.vertical, 4)
                                    .background(AppTheme.Colors.surface(colorScheme).opacity(0.6))
                                    .cornerRadius(AppTheme.Spacing.radiusFull)

                                ForEach(viewModel.messages) { message in
                                    if message.isUser {
                                        UserMessageBubble(message: message)
                                    } else {
                                        AIMessageBubble(message: message)
                                    }
                                }

                                if !viewModel.coachSuggestions.isEmpty {
                                    VStack(spacing: AppTheme.Spacing.sm) {
                                        ForEach(viewModel.coachSuggestions) { suggestion in
                                            GoalSuggestionCardView(
                                                suggestion: suggestion,
                                                isLoading: viewModel.isInFlight(goalId: suggestion.id) || viewModel.isInFlight(goalId: "reject-\(suggestion.id)"),
                                                onPrimary: { viewModel.acceptSuggestion(suggestion) },
                                                onSecondary: { viewModel.rejectSuggestion(suggestion) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .id("coach-suggestions")
                                }

                                if viewModel.isSending {
                                    HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                                        AIAvatarView()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(locManager.t("hamburger.ai_coach"))
                                                .font(AppTheme.Typography.label)
                                                .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                                            HStack(spacing: 5) {
                                                ForEach(0..<3, id: \.self) { _ in
                                                    Circle()
                                                        .fill(AppTheme.Colors.textPrimary(colorScheme).opacity(0.35))
                                                        .frame(width: 7, height: 7)
                                                }
                                            }
                                            .padding(.horizontal, 17).padding(.vertical, 14)
                                            .background(AppTheme.Colors.surface(colorScheme))
                                            .cornerRadius(AppTheme.Spacing.radiusXl)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .id("typing")
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.md)
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                        .onChange(of: viewModel.coachSuggestions.count) { _, _ in
                            withAnimation { proxy.scrollTo("coach-suggestions", anchor: .bottom) }
                        }
                        .onChange(of: viewModel.isSending) { _, sending in
                            if sending { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                        }
                    }
                }

                if let success = viewModel.coachSuccessMessage {
                    InlineBannerView(message: success, type: .info) {
                        viewModel.coachSuccessMessage = nil
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xs)
                }

                if let err = viewModel.chatError {
                    Text(err)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.destructive)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs + 2)
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: { }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                    .frame(width: 42, height: 42)

                    TextField(locManager.t("coach.write_thoughts"), text: $viewModel.inputText)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.85))
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm + 4)
                        .background(AppTheme.Colors.surface(colorScheme))
                        .cornerRadius(AppTheme.Spacing.radiusMd)
                        .onSubmit { viewModel.sendMessage() }

                    let hasText = !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Button(action: { viewModel.sendMessage() }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 42, height: 42)
                    .background(hasText ? AnyView(AppTheme.Gradients.accent) : AnyView(AppTheme.Colors.surface(colorScheme)))
                    .cornerRadius(AppTheme.Spacing.radiusFull)
                    .disabled(!hasText || viewModel.isSending)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.background(colorScheme))
            }
            .padding(.bottom, AppTheme.Layout.navAwareBottomInset)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.openSession(id: sessionId)
        }
    }

    private var currentSession: APICoachSession? {
        viewModel.sessions.first { $0.id == sessionId }
    }

    private var sessionTitle: String {
        localizedCoachSessionTitle(currentSession?.title, locManager: locManager)
    }

    private func sessionTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locManager.currentLanguage == "tr" ? "tr_TR" : "en_US")
        formatter.setLocalizedDateFormatFromTemplate("EEEE HH:mm")

        if let iso = currentSession?.updatedAt, let date = CoachDateParser.parse(iso) {
            return formatter.string(from: date)
        }
        return formatter.string(from: Date())
    }
}

struct AIAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.accentLight, AppTheme.Colors.accent],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct AIMessageBubble: View {
    let message: APICoachMessage
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
            AIAvatarView()
            VStack(alignment: .leading, spacing: 4) {
                Text(locManager.t("hamburger.ai_coach"))
                    .font(AppTheme.Typography.label)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                Text(message.content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary(colorScheme).opacity(0.95))
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusXl)
                            .fill(AppTheme.Colors.surface(colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Spacing.radiusXl)
                            .stroke(AppTheme.Colors.borderSubtle(colorScheme), lineWidth: 1)
                    )
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .id(message.id)
    }
}

struct UserMessageBubble: View {
    let message: APICoachMessage
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
                    .lineSpacing(3)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Gradients.accent)
                    .cornerRadius(AppTheme.Spacing.radiusXl)
                Text(message.formattedTime)
                    .font(AppTheme.Typography.micro)
                    .foregroundColor(AppTheme.Colors.textMuted(colorScheme))
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .id(message.id)
    }
}
