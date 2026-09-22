import Foundation
import Observation
import SwiftUI
import EchoAdminContract

/// Panelin ortak durumu. Sayılar ve kararlar sunucudan gelir; panel gösterir ve işlemi iletir.
@Observable
@MainActor
final class AdminStore {
    private(set) var overview: AdminAPI.AdminOverviewResponse?
    private(set) var error: AppError?
    @ObservationIgnored let service: any AdminServicing

    init(service: any AdminServicing) {
        self.service = service
    }

    func refresh() async {
        do {
            overview = try await service.overview()
            error = nil
        } catch {
            if let shown = AppError.displayable(error) { self.error = shown }
        }
    }

    func apply(controls: [AdminAPI.AdminControlResponse]) {
        overview?.controls = controls
    }
}

/// Panel sekmeleri; bildirim hedefi (`target`) bunlardan birini açar.
nonisolated enum AdminTab: String, CaseIterable, Hashable, Sendable {
    case status, users, blocks, traffic, logs
}

nonisolated enum AdminLogKind: String, CaseIterable, Hashable, Sendable {
    case reports, alerts, audit, errors
}

/// Kullanıcı detayına gidiş; Kullanıcılar ve Trafik sekmeleri aynı hedefi kullanır.
nonisolated struct AdminUserRoute: Hashable, Sendable {
    let id: String
}

/// Onay isteyen bir yönetim işlemi. Gerekçe zorunludur; onaydan sonra Face ID istenir.
struct AdminPendingAction: Identifiable {
    struct Input {
        let reason: String
        let duration: String
        let message: String?
    }

    let id = UUID()
    let title: String
    var message: String?
    var asksDuration = false
    var asksNotice = false
    var destructive = true
    let perform: @MainActor (Input) async throws -> Void
}

/// Yeni engel; başka ekrandan gelindiğinde tür ve değer dolu gelir.
struct AdminBlockDraft: Identifiable {
    let id = UUID()
    var kind = "ip"
    var value = ""
}

nonisolated enum AdminFormat {
    static func lira(_ value: Double) -> String {
        value.formatted(.currency(code: "TRY").precision(.fractionLength(2)))
    }

    static func count(_ value: Int64) -> String {
        value.formatted(.number)
    }

    static func moment(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func ago(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    static let durations = ["24h", "7d", "30d", "permanent"]

    static func durationTitle(_ duration: String) -> String {
        switch duration {
        case "24h": String(localized: "admin.duration.24h")
        case "7d": String(localized: "admin.duration.7d")
        case "30d": String(localized: "admin.duration.30d")
        default: String(localized: "admin.duration.permanent")
        }
    }

    static func controlTitle(_ key: String) -> String {
        switch key {
        case "maintenance": String(localized: "admin.control.maintenance")
        case "ai_paused": String(localized: "admin.control.aiPaused")
        case "registrations_closed": String(localized: "admin.control.registrationsClosed")
        case "community_frozen": String(localized: "admin.control.communityFrozen")
        default: key
        }
    }

    static func blockKindTitle(_ kind: String) -> String {
        switch kind {
        case "ip": String(localized: "admin.block.kind.ip")
        case "cidr": String(localized: "admin.block.kind.cidr")
        case "email": String(localized: "admin.block.kind.email")
        case "email_domain": String(localized: "admin.block.kind.domain")
        default: kind
        }
    }

    static func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": AppTheme.color.feedback.danger
        case "warning": AppTheme.color.feedback.warning
        default: AppTheme.color.feedback.info
        }
    }
}

extension AdminConfirmSheet where Fields == EmptyView {
    init(action: AdminPendingAction, onDone: @escaping (String) -> Void) {
        self.init(action: action, onDone: onDone) { EmptyView() }
    }
}

/// Gerekçe, isteğe bağlı süre ve kullanıcıya gösterilecek metin; onay Face ID ile verilir.
struct AdminConfirmSheet<Fields: View>: View {
    let action: AdminPendingAction
    let onDone: (String) -> Void
    @ViewBuilder var fields: Fields
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var duration = "24h"
    @State private var notice = ""
    @State private var isWorking = false
    @State private var error: AppError?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space.md) {
                    if let message = action.message {

                        Text(verbatim: message)
                            .echoTextStyle(.callout)
                            .foregroundStyle(AppTheme.color.content.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let error {

                        EchoBanner(kind: .danger, title: error.serverMessage ?? String(localized: "error.unexpected"))
                    }
                    fields
                    if action.asksDuration {

                        EchoSegmentedControl(selection: $duration,
                                             options: AdminFormat.durations.map { .init($0, AdminFormat.durationTitle($0)) })
                    }
                    if action.asksNotice {

                        EchoTextField("admin.confirm.notice", placeholder: "admin.confirm.noticePlaceholder", text: $notice)
                    }
                    EchoTextField("admin.confirm.reason", placeholder: "admin.confirm.reasonPlaceholder", text: $reason)
                    EchoButton(verbatimTitle: action.title, variant: action.destructive ? .destructive : .primary, size: .lg,
                               leadingIcon: "faceid", fullWidth: true, isLoading: isWorking) {
                        Task { await confirm() }
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespaces).count < 3)
                }
                .padding(AppTheme.layout.screenHorizontalPadding)
            }
            .background(AppTheme.color.bg.canvas)
            .navigationTitle(Text(verbatim: action.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func confirm() async {
        guard await environment.appLock.confirmOwner(reason: action.title) else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let trimmed = notice.trimmingCharacters(in: .whitespacesAndNewlines)
            try await action.perform(.init(reason: reason.trimmingCharacters(in: .whitespacesAndNewlines), duration: duration,
                                           message: trimmed.isEmpty ? nil : trimmed))
            onDone(action.title)
            dismiss()
        } catch {
            self.error = AppError.displayable(error)
        }
    }
}

/// IP, CIDR, e-posta ya da alan adı engeli ekler. Değer biçimini sunucu doğrular.
struct AdminNewBlockSheet: View {
    let draft: AdminBlockDraft
    let onDone: (String) -> Void
    @Environment(AppEnvironment.self) private var environment
    @State private var kind: String
    @State private var value: String

    init(draft: AdminBlockDraft, onDone: @escaping (String) -> Void) {
        self.draft = draft
        self.onDone = onDone
        _kind = State(initialValue: draft.kind)
        _value = State(initialValue: draft.value)
    }

    var body: some View {
        AdminConfirmSheet(action: action, onDone: onDone) {
            EchoSegmentedControl(selection: $kind, options: ["ip", "cidr", "email", "email_domain"].map {
                .init($0, AdminFormat.blockKindTitle($0))
            })
            EchoTextField("admin.block.value", placeholder: "admin.block.valuePlaceholder", text: $value,
                          keyboardType: kind == "email" || kind == "email_domain" ? .emailAddress : .numbersAndPunctuation)
        }
    }

    private var action: AdminPendingAction {
        let service = environment.admin
        let kind = kind
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return AdminPendingAction(title: String(localized: "admin.block.create"), asksDuration: true) { input in
            _ = try await service.createBlock(kind: kind, value: value, duration: input.duration, reason: input.reason)
        }
    }
}
