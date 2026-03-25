//
//  ReflectionCoachView.swift
//  Echo

import SwiftUI

struct ReflectionCoachView: View {
    let sessionId: String
    @ObservedObject var viewModel: CoachViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.063, green: 0.098, blue: 0.137)
                .ignoresSafeArea()

            // Ambient gradient
            VStack {
                HStack {
                    Circle()
                        .fill(Color(red: 43/255, green: 140/255, blue: 238/255, opacity: 0.1))
                        .blur(radius: 60)
                        .frame(width: 195, height: 195)
                        .offset(x: -50, y: -40)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color(red: 37/255, green: 99/255, blue: 235/255, opacity: 0.1))
                        .blur(radius: 50)
                        .frame(width: 156, height: 156)
                        .offset(x: 50, y: 50)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        viewModel.closeSession()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(sessionTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let session = currentSession, session.isActive {
                            HStack(spacing: 4) {
                                Circle().fill(Color(red: 0.2, green: 0.8, blue: 0.4)).frame(width: 6, height: 6)
                                Text("AKTİF")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            }
                        }
                    }
                    Spacer()
                    // Placeholder — simetri için
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                // Chat Mesajları
                if viewModel.isLoadingChat {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                // Tarih damgası
                                Text(sessionTimestamp())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.282, green: 0.333, blue: 0.408))
                                    .padding(.horizontal, 12).padding(.vertical, 4)
                                    .background(Color(red: 0.098, green: 0.149, blue: 0.2, opacity: 0.5))
                                    .cornerRadius(20)

                                ForEach(viewModel.messages) { message in
                                    if message.isUser {
                                        UserMessageBubble(message: message)
                                    } else {
                                        AIMessageBubble(message: message)
                                    }
                                }

                                if viewModel.isSending {
                                    HStack(alignment: .bottom, spacing: 12) {
                                        AIAvatarView()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("AI Coach").font(.system(size: 12))
                                                .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                                            HStack(spacing: 4) {
                                                ForEach(0..<3, id: \.self) { _ in
                                                    Circle().fill(Color.white.opacity(0.5)).frame(width: 6, height: 6)
                                                }
                                            }
                                            .padding(.horizontal, 17).padding(.vertical, 14)
                                            .background(Color(red: 0.098, green: 0.149, blue: 0.2)).cornerRadius(20)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .id("typing")
                                }
                            }
                            .padding(.vertical, 16)
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let last = viewModel.messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                        .onChange(of: viewModel.isSending) { _, sending in
                            if sending { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                        }
                    }
                }

                // Hata mesajı
                if let err = viewModel.chatError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                        .padding(.horizontal, 16).padding(.vertical, 6)
                }

                // Input Alanı
                HStack(spacing: 12) {
                    TextField("Düşüncelerini yaz…", text: $viewModel.inputText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.8))
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Color(red: 0.098, green: 0.149, blue: 0.2))
                        .cornerRadius(12)
                        .onSubmit { viewModel.sendMessage() }

                    Button(action: { viewModel.sendMessage() }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(
                        Group {
                            if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Color(red: 0.098, green: 0.149, blue: 0.2)
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 43/255, green: 140/255, blue: 238/255),
                                        Color(red: 29/255, green: 78/255, blue: 216/255)
                                    ]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .cornerRadius(20)
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.openSession(id: sessionId) }
    }

    // MARK: — Yardımcılar

    private var currentSession: APICoachSession? {
        viewModel.sessions.first { $0.id == sessionId }
    }

    private var sessionTitle: String {
        currentSession?.title ?? "AI Coach"
    }

    private func sessionTimestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, HH:mm"
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: Date())
    }
}

// MARK: — Message Bubbles

struct AIAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 99/255, green: 102/255, blue: 241/255),
                        Color(red: 147/255, green: 51/255, blue: 234/255)
                    ]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
            Image(systemName: "person.fill").font(.system(size: 16)).foregroundColor(.white)
        }
    }
}

struct AIMessageBubble: View {
    let message: APICoachMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            AIAvatarView()
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Coach")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.886, green: 0.910, blue: 0.941))
                    .lineSpacing(2)
                    .padding(.horizontal, 17).padding(.vertical, 17)
                    .background(Color(red: 0.098, green: 0.149, blue: 0.2))
                    .cornerRadius(20)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .id(message.id)
    }
}

struct UserMessageBubble: View {
    let message: APICoachMessage
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .padding(.horizontal, 16).padding(.vertical, 16)
                    .background(Color(red: 0.169, green: 0.549, blue: 0.933))
                    .cornerRadius(20)
                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.system(size: 12)).foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10)).foregroundColor(Color(red: 0.576, green: 0.639, blue: 0.725))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .id(message.id)
    }
}
