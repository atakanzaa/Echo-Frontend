import SwiftUI

struct TimeCapsuleView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = TimeCapsuleViewModel()
    @State private var isMenuOpen = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.298, green: 0.114, blue: 0.584), location: 0.0),
                    .init(color: Color(red: 0.200, green: 0.090, blue: 0.361), location: 0.3),
                    .init(color: Color(red: 0.149, green: 0.075, blue: 0.247), location: 0.45),
                    .init(color: Color(red: 0.098, green: 0.063, blue: 0.133), location: 0.6)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image(systemName: "sparkles").font(.system(size: 100))
                .foregroundColor(.white).opacity(0.05).offset(x: -100, y: -100)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { selectedTab = .profile }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                    Spacer()
                    Text("Time Capsule")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.149, green: 0.098, blue: 0.196)).cornerRadius(20)
                }
                .padding(.horizontal, 24).padding(.vertical, 24)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                                    .padding(.horizontal, 24)
                            }
                            // Countdown Section
                            VStack(spacing: 32) {
                                VStack(spacing: 8) {
                                    Text("NEXT CAPSULE OPENING")
                                        .font(.system(size: 14, weight: .medium)).tracking(1.4)
                                        .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))

                                    Text(viewModel.nextUnlockCountdown)
                                        .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                                        .shadow(color: Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.5), radius: 15)
                                }

                                // Central Lock Icon
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.3))
                                        .blur(radius: 30).frame(width: 192, height: 192)
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                        .frame(width: 192, height: 192)
                                    VStack {
                                        Image(systemName: "lock.fill").font(.system(size: 40))
                                            .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                                            .shadow(color: Color(red: 0.596, green: 0.283, blue: 0.941).opacity(0.8), radius: 10)
                                        Text("SEALED")
                                            .font(.system(size: 12, weight: .bold)).tracking(2.4)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .frame(height: 200)
                            }
                            .padding(.horizontal, 24)

                            // Sealed Memories Section
                            if !viewModel.capsules.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Sealed Memories")
                                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                        Spacer()
                                        Text("\(viewModel.capsules.filter(\.isSealed).count) Pending")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                                    }
                                    .padding(.horizontal, 24)

                                    VStack(spacing: 12) {
                                        ForEach(viewModel.capsules) { capsule in
                                            APISealedMemoryCard(capsule: capsule)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }

                            // Record Button
                            Button(action: { viewModel.showCreateSheet = true }) {
                                HStack {
                                    Image(systemName: "mic.fill").font(.system(size: 16, weight: .semibold))
                                    Text("Record Message to Future Self").font(.system(size: 16, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Color(red: 0.498, green: 0.075, blue: 0.929))
                                .foregroundColor(.white).cornerRadius(9999)
                            }
                            .padding(.horizontal, 24).padding(.bottom, 40)
                        }
                        .padding(.top, 32)
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
        .onAppear { viewModel.loadCapsules() }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateCapsuleSheet(viewModel: viewModel)
        }
    }
}

// MARK: — API Sealed Memory Card

struct APISealedMemoryCard: View {
    let capsule: APITimeCapsule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: capsule.isSealed ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.596, green: 0.283, blue: 0.941))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title ?? capsule.capsuleContentType.displayTitle + " Capsule")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Text(capsule.capsuleContentType.displayTitle + " • Unlock \(capsule.unlockDateFormatted)")
                    .font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(capsule.sealedDateShort)
                    .font(.system(size: 12)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
        }
        .padding(12)
        .background(Color(red: 0.141, green: 0.098, blue: 0.188).opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color(red: 0.498, green: 0.075, blue: 0.929).opacity(0.2), lineWidth: 1))
    }
}

// MARK: — Create Capsule Sheet

struct CreateCapsuleSheet: View {
    @ObservedObject var viewModel: TimeCapsuleViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (optional)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        TextField("Give your capsule a title", text: $viewModel.capsuleTitle)
                            .font(.system(size: 14)).foregroundColor(.white)
                            .padding(12).background(Color.white.opacity(0.05)).cornerRadius(12)
                    }

                    // Unlock in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unlock in \(viewModel.unlockInDays) days")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        HStack(spacing: 12) {
                            ForEach([30, 90, 180, 365], id: \.self) { days in
                                Button(action: { viewModel.unlockInDays = days }) {
                                    Text("\(days)d")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(viewModel.unlockInDays == days ? .white : Color(red: 0.612, green: 0.639, blue: 0.686))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(viewModel.unlockInDays == days
                                            ? Color(red: 0.498, green: 0.075, blue: 0.929)
                                            : Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Record
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Message")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        Button(action: { viewModel.toggleRecording() }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.isRecording ? "Recording…" : "Tap to record")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(viewModel.recordingTime).font(.system(size: 10))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                            .foregroundColor(viewModel.isRecording ? Color(red: 0.937, green: 0.267, blue: 0.267) : .white)
                            .background(viewModel.isRecording
                                ? Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.2)
                                : Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.937, green: 0.267, blue: 0.267))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer()

                    // Create Button
                    Button(action: { viewModel.createCapsule() }) {
                        if viewModel.isCreating {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Seal Capsule 🔒")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color(red: 0.498, green: 0.075, blue: 0.929)).cornerRadius(16)
                    .disabled(viewModel.isCreating)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Time Capsule")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { viewModel.showCreateSheet = false }
                        .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                }
            }
        }
    }
}
