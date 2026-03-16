import SwiftUI

struct HelpSupportView: View {
    @Binding var selectedTab: String
    @State private var expandedQuestion: String? = nil

    private let faqs: [(id: String, q: String, a: String)] = [
        (
            id: "1",
            q: "How does voice journaling work?",
            a: "Tap the record button on the home screen and speak freely. Echo transcribes your voice, analyzes your mood, and generates insights — all automatically after you finish recording."
        ),
        (
            id: "2",
            q: "Is my data private?",
            a: "Yes. Your journal entries are encrypted in transit and at rest. Audio is deleted from our servers immediately after transcription. Only you can access your data."
        ),
        (
            id: "3",
            q: "How is my mood score calculated?",
            a: "Echo uses AI to analyze the emotional content of your journal entry and assigns a score from 1–10. The score reflects sentiment, energy level, and key emotions mentioned."
        ),
        (
            id: "4",
            q: "What is a Time Capsule?",
            a: "A Time Capsule lets you record a voice message to your future self, sealed until a date you choose. Once the unlock date arrives, you can listen back."
        ),
        (
            id: "5",
            q: "How do I earn badges?",
            a: "Badges are awarded for milestones like maintaining streaks, recording your first entry, reaching 10/30/100 entries, and more. Check the Achievements page to see your progress."
        ),
        (
            id: "6",
            q: "Why does analysis take a moment?",
            a: "After you record, Echo transcribes your audio and runs AI analysis. This usually takes 10–30 seconds depending on the length of your recording."
        ),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.098, green: 0.063, blue: 0.133).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { selectedTab = "profile" }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Help & Support")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16).padding(.vertical, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 0.498, green: 0.075, blue: 0.929))
                            Text("How can we help?")
                                .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                            Text("Find answers below or reach out to our team.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)

                        // FAQ
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FREQUENTLY ASKED")
                                .font(.system(size: 12, weight: .bold)).tracking(0.6)
                                .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                                    if index > 0 {
                                        Divider().background(Color.white.opacity(0.06))
                                    }
                                    FAQRow(
                                        question: faq.q,
                                        answer: faq.a,
                                        isExpanded: expandedQuestion == faq.id,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                expandedQuestion = expandedQuestion == faq.id ? nil : faq.id
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        // Contact options
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONTACT US")
                                .font(.system(size: 12, weight: .bold)).tracking(0.6)
                                .foregroundColor(Color(red: 0.420, green: 0.447, blue: 0.502))
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ContactRow(
                                    icon: "envelope.fill",
                                    iconColor: Color(red: 0.498, green: 0.075, blue: 0.929),
                                    title: "Email Support",
                                    subtitle: "support@echo-app.com",
                                    action: {
                                        if let url = URL(string: "mailto:support@echo-app.com") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                                Divider().background(Color.white.opacity(0.06))
                                ContactRow(
                                    icon: "star.fill",
                                    iconColor: Color(red: 0.937, green: 0.722, blue: 0.267),
                                    title: "Rate Echo",
                                    subtitle: "Share your feedback on the App Store",
                                    action: {}
                                )
                            }
                            .padding(16)
                            .background(Color(red: 0.141, green: 0.098, blue: 0.188))
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 32)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct FAQRow: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(question)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                if isExpanded {
                    Text(answer)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
        }
    }
}

private struct ContactRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(subtitle).font(.system(size: 13)).foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.612, green: 0.639, blue: 0.686))
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    HelpSupportView(selectedTab: .constant("help"))
}
