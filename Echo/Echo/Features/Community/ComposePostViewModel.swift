import Foundation
import Observation

@Observable
@MainActor
final class ComposePostViewModel {
    var content: String
    var isAnonymous = true
    private(set) var imageData: Data?
    private(set) var isWorking = false
    private(set) var requiresTerms = false
    private(set) var needsSensitiveConfirmation = false
    private(set) var error: AppError?

    @ObservationIgnored private let community: any CommunityServicing
    @ObservationIgnored private let user: any UserServicing
    @ObservationIgnored private var intent: Intent?

    private struct Intent {
        let content: String?
        let imageData: Data?
        let isAnonymous: Bool
        let key: String
    }

    init(prefilledText: String?, community: any CommunityServicing, user: any UserServicing) {
        content = prefilledText ?? ""
        self.community = community
        self.user = user
    }

    var canSubmit: Bool {
        (!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || imageData != nil)
            && content.count <= 1_000 && !isWorking
    }

    var isLocked: Bool { intent != nil }

    func setImageData(_ data: Data?) {
        guard intent == nil else { return }
        imageData = data
    }

    func submit(sensitiveContentConfirmed: Bool = false) async -> CommunityPost? {
        guard canSubmit || intent != nil else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if intent == nil, !sensitiveContentConfirmed, SensitiveContentDetector.containsPersonalData(trimmed) {
            needsSensitiveConfirmation = true
            return nil
        }
        needsSensitiveConfirmation = false
        let currentIntent = intent ?? Intent(content: trimmed.isEmpty ? nil : trimmed,
                                             imageData: imageData,
                                             isAnonymous: isAnonymous,
                                             key: UUID().uuidString)
        intent = currentIntent
        isWorking = true
        error = nil
        defer { isWorking = false }
        do {
            let post: CommunityPost
            if let data = currentIntent.imageData {
                post = try await community.createImagePost(imageData: data, filename: "echo-community.jpg",
                                                           content: currentIntent.content, emoji: nil,
                                                           isAnonymous: currentIntent.isAnonymous,
                                                           badgeKey: nil, idempotencyKey: currentIntent.key)
            } else {
                post = try await community.createPost(content: currentIntent.content, emoji: nil,
                                                      isAnonymous: currentIntent.isAnonymous,
                                                      badgeKey: nil, idempotencyKey: currentIntent.key)
            }
            intent = nil
            return post
        } catch {
            let appError = AppError.from(error)
            if appError.problem?.code == "COMMUNITY_TERMS_REQUIRED" {
                requiresTerms = true
            } else if !appError.isRetryable {
                if case .authenticationRequired = appError { /* Oturum yenilenene kadar niyet korunur. */ }
                else { intent = nil }
            }
            self.error = appError
            return nil
        }
    }

    func acceptCommunityTerms() async -> CommunityPost? {
        isWorking = true
        error = nil
        do {
            _ = try await user.updateConsent(aiTraining: nil, kvkk: nil, communityTerms: true)
            requiresTerms = false
            isWorking = false
            return await submit(sensitiveContentConfirmed: true)
        } catch {
            isWorking = false
            self.error = AppError.from(error)
            return nil
        }
    }

    func dismissSensitiveWarning() {
        needsSensitiveConfirmation = false
    }
}

nonisolated private enum SensitiveContentDetector {
    static func containsPersonalData(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let fullRange = NSRange(text.startIndex..., in: text)
        let types = NSTextCheckingResult.CheckingType.phoneNumber.rawValue
            | NSTextCheckingResult.CheckingType.address.rawValue
            | NSTextCheckingResult.CheckingType.link.rawValue
        if let detector = try? NSDataDetector(types: types), detector.firstMatch(in: text, range: fullRange) != nil {
            return true
        }
        // İki ardışık büyük harfle başlayan kelime, olası kişi adını yalnız uyarı amacıyla işaretler.
        return text.range(of: #"\b[A-ZÇĞİÖŞÜ][a-zçğıöşü]+\s+[A-ZÇĞİÖŞÜ][a-zçğıöşü]+\b"#,
                          options: .regularExpression) != nil
    }
}
