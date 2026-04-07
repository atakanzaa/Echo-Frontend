//
//  VoiceRecordingView.swift
//  Echo

import SwiftUI
import AVFoundation

struct VoiceRecordingView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = HomeViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.dateLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.678, green: 0.573, blue: 0.792))
                            .tracking(0.35)

                        Text(viewModel.greetingLabel)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-0.5)
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
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Main Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Prompt Section
                        VStack(spacing: 8) {
                            Text("How was your day?")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(
                                viewModel.awaitingConfirmation
                                    ? "Kaydınız hazır — göndermek istiyor musunuz?"
                                    : viewModel.isRecording
                                        ? "Recording… tap to stop."
                                        : "Tap to start recording your thoughts."
                            )
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(red: 0.678, green: 0.573, blue: 0.792))
                            .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)

                        // Recording Button Area
                        VStack {
                            if viewModel.awaitingConfirmation {
                                // Confirmation buttons
                                VStack(spacing: 16) {
                                    Text(viewModel.recordingTime)
                                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                                        .foregroundColor(.white)

                                    HStack(spacing: 20) {
                                        // Discard
                                        Button(action: { viewModel.discardRecording() }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "trash.fill")
                                                Text("Sil")
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                        }
                                        .background(Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.15))
                                        .cornerRadius(20)

                                        // Send
                                        Button(action: { viewModel.confirmUpload() }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "paperplane.fill")
                                                Text("Gönder")
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                        }
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 127/255, green: 19/255, blue: 236/255),
                                                    Color(red: 94/255, green: 14/255, blue: 179/255)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(20)
                                    }
                                    .padding(.horizontal, 8)
                                }
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 127/255, green: 19/255, blue: 236/255, opacity: viewModel.isRecording ? 0.35 : 0.2))
                                        .blur(radius: 30)
                                        .frame(width: 256, height: 256)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isRecording)

                                    Circle()
                                        .fill(Color(red: 127/255, green: 19/255, blue: 236/255, opacity: 0.3))
                                        .blur(radius: 20)
                                        .frame(width: 192, height: 192)
                                        .offset(x: -50, y: 25)

                                    Button(action: { viewModel.toggleRecording() }) {
                                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 96, height: 96)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                viewModel.isRecording
                                                    ? Color(red: 0.937, green: 0.267, blue: 0.267)
                                                    : Color(red: 127/255, green: 19/255, blue: 236/255),
                                                viewModel.isRecording
                                                    ? Color(red: 0.8, green: 0.1, blue: 0.1)
                                                    : Color(red: 94/255, green: 14/255, blue: 179/255)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(48)
                                    .shadow(color: Color(red: 127/255, green: 19/255, blue: 236/255, opacity: 0.4), radius: 20)
                                    .disabled(viewModel.isUploading || viewModel.isProcessing)
                                }
                                .frame(height: 300)
                                .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: viewModel.awaitingConfirmation)

                        // Status and Transcription Area
                        VStack(spacing: 24) {
                            // Status Pill
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(viewModel.isRecording
                                          ? Color(red: 0.937, green: 0.267, blue: 0.267)
                                          : viewModel.isProcessing
                                              ? Color(red: 0.498, green: 0.075, blue: 0.929)
                                              : Color(red: 0.133, green: 0.769, blue: 0.368))
                                    .frame(width: 8, height: 8)

                                Text(viewModel.isRecording
                                     ? "● REC  \(viewModel.recordingTime)"
                                     : viewModel.statusMessage)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.8))
                            }
                            .padding(.horizontal, 17)
                            .padding(.vertical, 7)
                            .background(Color(red: 0.149, green: 0.098, blue: 0.196))
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Error
                            if let err = viewModel.errorMessage {
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                                    .padding(.horizontal, 24)
                            }

                            // Transcription Text Area
                            VStack(alignment: .leading) {
                                Text(viewModel.transcript.isEmpty
                                     ? "Your words will appear here as you speak…"
                                     : viewModel.transcript)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.9))
                                    .lineSpacing(2)

                                Spacer()
                            }
                            .frame(minHeight: 140)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 25)
                            .background(
                                ZStack {
                                    Color(red: 0.149, green: 0.098, blue: 0.196, opacity: 0.5)
                                        .cornerRadius(32)

                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(red: 0.149, green: 0.098, blue: 0.196), location: 1),
                                            .init(color: Color(red: 0.149, green: 0.098, blue: 0.196, opacity: 0), location: 0)
                                        ]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 31)
                }

                Spacer()
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
}
