import SwiftUI

struct JournalView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = JournalViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.098, green: 0.063, blue: 0.133)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("My Journal")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-0.5)

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
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(height: 56)
                    .background(Color.black.opacity(0.3))

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else if let err = viewModel.errorMessage {
                        Spacer()
                        Text(err)
                            .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                            .padding()
                        Spacer()
                    } else if viewModel.entries.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                            Text("No entries yet.\nTap the mic to record your first journal.")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.entries, id: \.id) { entry in
                                    NavigationLink(destination: JournalDetailView(entry: entry, selectedTab: $selectedTab)) {
                                        APIJournalEntryCard(entry: entry)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                        }
                    }

                    Spacer()
                    BottomNavigationView(currentTab: .journal, selectedTab: $selectedTab)
                }

                // Hamburger Menu Overlay
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
        }
        .navigationViewStyle(.stack)
        .onAppear { viewModel.loadRecent() }
    }
}

// MARK: - Journal Entry Card (API backed)

struct APIJournalEntryCard: View {
    let entry: APIJournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.analysis?.summary ?? entry.transcript ?? "Processing…")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(entry.relativeDate)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if entry.entryStatus == .complete, let analysis = entry.analysis {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(entry.emotionalState.color)
                                .frame(width: 8, height: 8)

                            Text((analysis.moodLabel ?? "neutral").capitalized)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(entry.emotionalState.color)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(entry.emotionalState.color.opacity(0.2))
                        .cornerRadius(6)
                    } else {
                        Text(entry.entryStatus.displayTitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.15))
                            .cornerRadius(6)
                    }

                    if !entry.formattedDuration.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 10))
                            Text(entry.formattedDuration)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    }
                }
            }

            if let summary = entry.analysis?.summary {
                Text(summary)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                    .lineSpacing(2)
                    .lineLimit(3)
            } else if let transcript = entry.transcript {
                Text(transcript)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.820, green: 0.839, blue: 0.855))
                    .lineSpacing(2)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(Color(red: 0.165, green: 0.114, blue: 0.212).opacity(0.5))
        .border(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
