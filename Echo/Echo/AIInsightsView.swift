import SwiftUI

struct AIInsightsView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = AIInsightsViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { selectedTab = .insights }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 8) {
                        Text("AI Insights")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                    .cornerRadius(20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Period Selector
                Menu {
                    ForEach(viewModel.periodOptions, id: \.days) { opt in
                        Button(opt.label) { viewModel.selectPeriod(opt.days) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.periodOptions.first(where: { $0.days == viewModel.selectedPeriod })?.label ?? "Last 7 Days")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.884, green: 0.910, blue: 0.941))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Color(red: 0.884, green: 0.910, blue: 0.941))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.white.opacity(0.1)).cornerRadius(9999)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Mood Score
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.498, green: 0.075, blue: 0.929),
                                                    Color(red: 0.596, green: 0.283, blue: 0.941)
                                                ]),
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 12
                                        )
                                        .frame(height: 192)
                                    VStack(spacing: 4) {
                                        Text(viewModel.moodPercentText)
                                            .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                                        Text("POSITIVE")
                                            .font(.system(size: 12, weight: .medium)).tracking(0.6)
                                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                                    }
                                }
                                VStack(spacing: 8) {
                                    Text("Overall Mood")
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    if let insights = viewModel.insights {
                                        Text("Your emotional baseline is \(insights.moodTrend.lowercased()). Keep reflecting daily.")
                                            .font(.system(size: 14)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color(red: 0.149, green: 0.098, blue: 0.200))
                            .cornerRadius(24).padding(.horizontal, 16)

                            // Emotional Trends
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Emotional Trends")
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: viewModel.isTrendPositive ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(viewModel.trendText)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(viewModel.isTrendPositive
                                        ? Color(red: 0.157, green: 0.631, blue: 0.569)
                                        : Color(red: 0.937, green: 0.267, blue: 0.267))
                                }
                            }
                            .padding(24)
                            .background(Color(red: 0.149, green: 0.098, blue: 0.200))
                            .cornerRadius(24).padding(.horizontal, 16)

                            // Repeated Themes
                            if let insights = viewModel.insights, !insights.themes.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Repeated Themes")
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                        ForEach(insights.themes, id: \.tag) { theme in
                                            ThemeTag("#\(theme.tag)")
                                        }
                                    }
                                }
                                .padding(24)
                                .background(Color(red: 0.149, green: 0.098, blue: 0.200))
                                .cornerRadius(24).padding(.horizontal, 16)
                            }

                            // AI Suggestions
                            if let insights = viewModel.insights, !insights.suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("AI SUGGESTIONS")
                                        .font(.system(size: 12, weight: .bold)).tracking(0.5)
                                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                    ForEach(insights.suggestions, id: \.title) { suggestion in
                                        SuggestionCardView(
                                            icon: suggestion.icon ?? "lightbulb.fill",
                                            title: suggestion.title,
                                            description: suggestion.body
                                        )
                                    }
                                }
                                .padding(24)
                                .background(Color(red: 0.149, green: 0.098, blue: 0.200))
                                .cornerRadius(24).padding(.horizontal, 16).padding(.bottom, 40)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }

            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear { viewModel.loadInsights() }
    }
}


struct ThemeTag: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color(red: 0.596, green: 0.283, blue: 0.941).opacity(0.1))
            .cornerRadius(12)
    }
}

struct SuggestionCardView: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.596, green: 0.283, blue: 0.941).opacity(0.1))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(description).font(.system(size: 13)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            Spacer()
        }
    }
}
