#if DEBUG
import SwiftUI

/// Yalnız DEBUG: `-EchoUsagePreview <ok|warning|exhausted|premiumExhausted|components>` kullanım ekranlarını sahte veriyle açar.
enum UsagePreviewFixtures {
    static func usage(_ name: String) -> AIUsage {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
        let premium = name == "premiumExhausted"
        let (day, month, state): (Int, Int, AIUsage.State) = switch name {
        case "warning": (84, 41, .warning)
        case "exhausted", "premiumExhausted": (100, 62, .exhausted)
        default: (34, 18, .ok)
        }
        let message: String? = switch name {
        case "warning": "Bugünkü kullanım hakkının büyük kısmını kullandın."
        case "exhausted": "Bugünkü kullanım hakkını doldurdun. Premium'la daha uzun sohbetler, daha derin içgörüler ve daha yüksek kullanım hakkı seni bekliyor."
        case "premiumExhausted": "Bugünkü kullanım hakkını doldurdun. Hakkın yenilenince kaldığın yerden devam edebilirsin."
        default: nil
        }
        return AIUsage(isPremium: premium, state: state, usedPercent: day, resetsAt: midnight,
                       windows: [.init(scope: .day, usedPercent: day, resetsAt: midnight, state: state),
                                 .init(scope: .month, usedPercent: month, resetsAt: nextMonth, state: .ok)],
                       message: message, offerUpgrade: state == .exhausted && !premium,
                       allowedActions: state == .exhausted ? ["create_journal"] : ["create_journal", "send_coach_message"])
    }
}

struct UsagePreviewHost: View {
    let name: String
    @State private var environment = AppEnvironment.preview(.morning)
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack {
            if name == "components" {

                components
            } else {
                UsageView()
            }
        }
        .environment(environment)
        .environment(router)
        .onAppear { environment.usage.applyPreview(UsagePreviewFixtures.usage(name == "components" ? "exhausted" : name)) }
    }

    private var components: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.space.lg) {
                UsageNotice(usage: UsagePreviewFixtures.usage("warning"))
                UsageNotice(usage: UsagePreviewFixtures.usage("exhausted"), onUpgrade: {})
                UsageNotice(usage: UsagePreviewFixtures.usage("exhausted"), isRecording: true)
                EchoTimelineRow(time: Date(), state: .waitingForAllowance(transcript: "Akşam koşusundan yeni döndüm, bacaklarım ağır ama kafam hafif.",
                                                                          resumesAt: UsagePreviewFixtures.usage("exhausted").resetsAt)) {}
            }
            .padding()
        }
        .background(AppTheme.color.bg.canvas)
    }
}

#Preview("Kullanım — hak bitti") { UsagePreviewHost(name: "exhausted") }
#Preview("Kullanım — bileşenler") { UsagePreviewHost(name: "components") }
#endif
