import SwiftUI

// MARK: — Chat Geçmişi Listesi

struct CoachSessionsListView: View {
    @Binding var selectedTab: String
    @StateObject private var viewModel = CoachViewModel()

    @State private var isMenuOpen      = false
    @State private var isCreating      = false
    @State private var createError:    String?
    @State private var selectedSession: APICoachSession?

    var body: some View {
        ZStack {
            Color(red: 0.063, green: 0.098, blue: 0.137).ignoresSafeArea()

            // Ambient gradient
            VStack {
                HStack {
                    Circle()
                        .fill(Color(red: 43/255, green: 140/255, blue: 238/255, opacity: 0.08))
                        .blur(radius: 60).frame(width: 200, height: 200).offset(x: -50, y: -40)
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // İçerik
                if viewModel.isLoadingSessions {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }

            // Hamburger menu overlay
            if isMenuOpen {
                HStack(spacing: 0) {
                    HamburgerMenuView(isMenuOpen: $isMenuOpen, selectedTab: $selectedTab)
                        .frame(maxWidth: 250)
                    Spacer()
                }
                .transition(.move(edge: .leading)).zIndex(1)
            }

            // Hata toast
            if let err = createError {
                VStack {
                    Spacer()
                    Text(err)
                        .font(.system(size: 14)).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.red.opacity(0.85)).cornerRadius(12)
                        .padding(.horizontal, 24).padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .onAppear { viewModel.loadSessions() }
        // Journal context varsa bekleyen session'ı aç
        .onAppear { handlePendingJournalContext() }
        .navigationDestination(item: $selectedSession) { session in
            ReflectionCoachView(sessionId: session.id, viewModel: viewModel)
        }
    }

    // MARK: — Header

    private var header: some View {
        HStack {
            Button(action: { isMenuOpen.toggle() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            .background(Color(red: 0.149, green: 0.098, blue: 0.196)).cornerRadius(20)

            Spacer()

            Text("AI Coach")
                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)

            Spacer()

            // (+) Yeni konuşma butonu
            Button(action: startNewSession) {
                ZStack {
                    if isCreating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 43/255, green: 140/255, blue: 238/255),
                        Color(red: 29/255, green: 78/255, blue: 216/255)
                    ]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .disabled(isCreating)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: — Session Listesi

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture { selectedSession = session }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteSession(id: session.id)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                }
                // Daha fazla yükleme
                if viewModel.hasMorePages {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical, 12)
                        .onAppear { viewModel.loadMoreSessions() }
                }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
        }
    }

    // MARK: — Boş State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(red: 43/255, green: 140/255, blue: 238/255).opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40)).foregroundColor(Color(red: 43/255, green: 140/255, blue: 238/255))
            }
            VStack(spacing: 8) {
                Text("Henüz konuşma yok")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text("AI Coach ile ilk konuşmanı başlat")
                    .font(.system(size: 14)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            Button(action: startNewSession) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                        Text("Yeni Konuşma").font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32).padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 43/255, green: 140/255, blue: 238/255),
                            Color(red: 29/255, green: 78/255, blue: 216/255)
                        ]),
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .disabled(isCreating)
            Spacer()
        }
    }

    // MARK: — Aksiyonlar

    private func startNewSession() {
        guard !isCreating else { return }
        isCreating  = true
        createError = nil
        Task {
            do {
                let session = try await viewModel.createNewSession()
                selectedSession = session
            } catch {
                createError = error.localizedDescription
                // Hata 3 saniye sonra kaybolur
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                createError = nil
            }
            isCreating = false
        }
    }

    private func handlePendingJournalContext() {
        guard let journalId = CoachJournalContext.shared.pendingJournalEntryId else { return }
        CoachJournalContext.shared.pendingJournalEntryId = nil
        isCreating = true
        Task {
            do {
                let session = try await viewModel.createSessionWithJournal(journalEntryId: journalId)
                selectedSession = session
            } catch {
                createError = error.localizedDescription
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                createError = nil
            }
            isCreating = false
        }
    }
}

// MARK: — Session Satırı

struct SessionRowView: View {
    let session: APICoachSession

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 99/255, green: 102/255, blue: 241/255),
                            Color(red: 147/255, green: 51/255, blue: 234/255)
                        ]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 46, height: 46)
                Image(systemName: session.journalEntryId != nil ? "doc.text" : "person.fill")
                    .font(.system(size: 18)).foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.title ?? "Konuşma")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        .lineLimit(1)
                    if session.isActive {
                        Circle().fill(Color(red: 0.2, green: 0.8, blue: 0.4)).frame(width: 7, height: 7)
                    }
                }
                HStack(spacing: 6) {
                    Text(relativeDate(session.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                    if session.journalEntryId != nil {
                        HStack(spacing: 3) {
                            Image(systemName: "book").font(.system(size: 10))
                            Text("Günlük").font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color(red: 0.149, green: 0.098, blue: 0.196))
        .cornerRadius(14)
    }

    private func relativeDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else { return iso }
        let diff = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: Date())
        if let day = diff.day, day >= 2  { return "\(day) gün önce" }
        if let day = diff.day, day == 1  { return "Dün" }
        if let hour = diff.hour, hour >= 1 { return "\(hour) saat önce" }
        if let min = diff.minute, min >= 1  { return "\(min) dk önce" }
        return "Az önce"
    }
}
