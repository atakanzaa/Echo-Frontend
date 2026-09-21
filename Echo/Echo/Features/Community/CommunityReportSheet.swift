import SwiftUI

struct CommunityReportSheet: View {
    let onSubmit: (CommunityReportReason, String?) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var reason: CommunityReportReason = .spam
    @State private var details = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.space.md) {
                Picker("community.reportReason", selection: $reason) {
                    ForEach(CommunityReportReason.allCases) { reason in
                        Text(reasonTitle(reason)).tag(reason)
                    }
                }
                .pickerStyle(.menu)
                EchoTextEditor(placeholder: "community.reportDetails", text: $details, characterLimit: 500)
                EchoButton("community.submitReport", variant: .destructive, fullWidth: true, isLoading: isWorking) {
                    isWorking = true
                    Task {
                        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
                        if await onSubmit(reason, trimmed.isEmpty ? nil : trimmed) { dismiss() }
                        isWorking = false
                    }
                }
                .disabled(details.count > 500)
                Spacer()
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
            .background(AppTheme.color.bg.canvas)
            .navigationTitle(Text("community.report"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("common.cancel") { dismiss() } }
            }
        }
    }

    private func reasonTitle(_ reason: CommunityReportReason) -> LocalizedStringKey {
        switch reason {
        case .spam: "community.reportReason.spam"
        case .harassment: "community.reportReason.harassment"
        case .hate: "community.reportReason.hate"
        case .sexualContent: "community.reportReason.sexualContent"
        case .violence: "community.reportReason.violence"
        case .selfHarm: "community.reportReason.selfHarm"
        case .other: "community.reportReason.other"
        }
    }
}
