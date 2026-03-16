import SwiftUI

struct AchievementsView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    Spacer()
                    Text("Achievements")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196)).cornerRadius(20)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Streak Circle
                            VStack(spacing: 16) {
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
                                            lineWidth: 8
                                        )
                                        .frame(height: 180)

                                    VStack(spacing: 8) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                                        Text("\(viewModel.currentStreak) Days")
                                            .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                                        Text("Current Streak")
                                            .font(.system(size: 13)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                        if !viewModel.level.isEmpty {
                                            Text(viewModel.level)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color(red: 0.157, green: 0.631, blue: 0.569))
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(Color(red: 0.157, green: 0.631, blue: 0.569).opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }

                                VStack(spacing: 12) {
                                    Text(viewModel.streakMessage)
                                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    if !viewModel.levelMessage.isEmpty {
                                        Text(viewModel.levelMessage)
                                            .font(.system(size: 14)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                            .multilineTextAlignment(.center).lineLimit(3)
                                    }
                                }
                            }
                            .padding(24)

                            // Stats Row
                            HStack(spacing: 12) {
                                AchievementStatCardView(icon: "mic.fill",      value: "\(viewModel.totalEntries)", label: "Entries")
                                AchievementStatCardView(icon: "text.bubble.fill", value: viewModel.totalWordsText,    label: "Words")
                                AchievementStatCardView(icon: "sparkles",      value: viewModel.insightScoreText,   label: "Insight")
                            }
                            .padding(.horizontal, 16)

                            // Badge Collection
                            if !viewModel.badges.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Your Collection")
                                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                        Spacer()
                                        Text("\(viewModel.badges.filter(\.isEarned).count) Earned")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                                    }
                                    .padding(.horizontal, 16)

                                    let rows = stride(from: 0, to: viewModel.badges.count, by: 2).map {
                                        Array(viewModel.badges[$0..<min($0+2, viewModel.badges.count)])
                                    }
                                    ForEach(Array(rows.enumerated()), id: \.offset) { _, pair in
                                        HStack(spacing: 12) {
                                            ForEach(pair) { badge in
                                                BadgeCard(name: badge.title, emoji: badge.emoji, earned: badge.isEarned)
                                            }
                                            if pair.count == 1 { Spacer().frame(maxWidth: .infinity) }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.top, 8).padding(.bottom, 40)
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
        .onAppear { viewModel.load() }
    }
}

struct AchievementStatCardView: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 20))
                .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color(red: 0.141, green: 0.098, blue: 0.188)).cornerRadius(12)
    }
}

struct BadgeCard: View {
    let name: String; let emoji: String; let earned: Bool
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                .cornerRadius(12).opacity(earned ? 1.0 : 0.4)
            Text(name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                .lineLimit(2).multilineTextAlignment(.center).opacity(earned ? 1.0 : 0.6)
            if !earned {
                Text("Locked").font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(red: 0.098, green: 0.063, blue: 0.133)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(red: 0.141, green: 0.098, blue: 0.188), lineWidth: 1))
    }
}

#Preview {
    AchievementsView(selectedTab: .constant("achievements"))
}
