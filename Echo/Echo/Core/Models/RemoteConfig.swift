import Foundation
import EchoAPI

/// `GET /app/config` yanıtı. Sürüm kararı, yasal bağlantılar, kriz kaynağı, kayıt sınırları ve
/// kapsül süre seçenekleri sunucudan gelir; uygulamada sabit tutulmaz (rules.md §2).
nonisolated struct RemoteAppConfig: Sendable, Equatable {
    let privacyPolicyURL: URL?
    let termsURL: URL?
    let communityGuidelinesURL: URL?
    let privacyPolicyVersion: String
    let communityTermsVersion: String
    let supportEmail: String?
    let aiDisclaimerTR: String
    let aiDisclaimerEN: String
    let crisis: CrisisResource
    let requiresAITrainingConsent: Bool
    let requiresKVKKConsent: Bool
    let release: Release
    let recording: RecordingLimits
    let capsulePresets: [CapsulePreset]
    let adPlacements: [AdPlacement]

    nonisolated struct CrisisResource: Sendable, Equatable {
        let phoneNumber: String
        let nameTR: String
        let nameEN: String
        let availabilityTR: String
        let availabilityEN: String
        let isFree: Bool

        func name(for language: AppLanguage) -> String { language == .turkish ? nameTR : nameEN }
        func availability(for language: AppLanguage) -> String { language == .turkish ? availabilityTR : availabilityEN }
    }

    nonisolated struct Release: Sendable, Equatable {
        let minimumVersion: String
        let latestVersion: String
        /// Sürüm karşılaştırmasını sunucu yapar; null ise istemci sürüm göndermemiştir.
        let updateRequired: Bool?
        let updateRecommended: Bool?
        let storeURL: URL?
    }

    nonisolated struct RecordingLimits: Sendable, Equatable {
        let minSeconds: Int
        let maxSeconds: Int
        let maxTranscriptCharacters: Int
    }

    nonisolated struct CapsulePreset: Sendable, Equatable, Identifiable {
        let key: String
        let days: Int
        /// İstek dilinde gösterime hazır etiket.
        let label: String

        var id: String { key }
    }

    nonisolated struct AdPlacement: Sendable, Equatable, Identifiable {
        let placement: String
        let isEnabled: Bool
        let frequency: Int?

        var id: String { placement }
    }

    func aiDisclaimer(for language: AppLanguage) -> String {
        language == .turkish ? aiDisclaimerTR : aiDisclaimerEN
    }

    init(dto: Components.Schemas.AppConfigResponse) {
        privacyPolicyURL = dto.legal.privacyPolicyUrl.flatMap(URL.init(string:))
        termsURL = dto.legal.termsUrl.flatMap(URL.init(string:))
        communityGuidelinesURL = dto.legal.communityGuidelinesUrl.flatMap(URL.init(string:))
        privacyPolicyVersion = dto.legal.privacyPolicyVersion
        communityTermsVersion = dto.legal.communityTermsVersion
        supportEmail = dto.supportEmail
        aiDisclaimerTR = dto.aiDisclaimer.tr
        aiDisclaimerEN = dto.aiDisclaimer.en
        crisis = CrisisResource(phoneNumber: dto.crisisResource.phoneNumber,
                                nameTR: dto.crisisResource.nameTr,
                                nameEN: dto.crisisResource.nameEn,
                                availabilityTR: dto.crisisResource.availabilityTr,
                                availabilityEN: dto.crisisResource.availabilityEn,
                                isFree: dto.crisisResource.free)
        requiresAITrainingConsent = dto.consentRequirements.aiTrainingConsentRequired
        requiresKVKKConsent = dto.consentRequirements.kvkkConsentRequired
        release = Release(minimumVersion: dto.release.minimumVersion,
                          latestVersion: dto.release.latestVersion,
                          updateRequired: dto.release.updateRequired,
                          updateRecommended: dto.release.updateRecommended,
                          storeURL: dto.release.storeUrl.flatMap(URL.init(string:)))
        recording = RecordingLimits(minSeconds: Int(dto.recording.minSeconds),
                                    maxSeconds: Int(dto.recording.maxSeconds),
                                    maxTranscriptCharacters: Int(dto.recording.maxTranscriptCharacters))
        capsulePresets = dto.capsules.presets.map {
            CapsulePreset(key: $0.key.value1?.rawValue ?? $0.key.value2 ?? "", days: Int($0.days), label: $0.label)
        }
        adPlacements = dto.ads.placements.map {
            AdPlacement(placement: $0.placement.value1?.rawValue ?? $0.placement.value2 ?? "",
                        isEnabled: $0.enabled,
                        frequency: $0.frequency.map(Int.init))
        }
    }
}

/// `GET /app/vocabulary`: sözlük değerlerinin gösterim metni (rules.md §11).
/// Bilinmeyen değerde ham değer gösterilir; uygulama kendi çeviri tablosunu tutmaz.
nonisolated struct ServerVocabulary: Sendable, Equatable {
    private let moodCategories: [String: String]
    private let energyLevels: [String: String]
    private let moodTrends: [String: String]
    private let goalStatuses: [String: String]

    init(dto: Components.Schemas.VocabularyResponse) {
        // Sunucu bir anahtarı iki kez gönderse de açılış çökmez; ilk etiket kullanılır.
        moodCategories = Dictionary(dto.moodCategories.map { ($0.key, $0.label) }, uniquingKeysWith: { first, _ in first })
        energyLevels = Dictionary(dto.energyLevels.map { ($0.key, $0.label) }, uniquingKeysWith: { first, _ in first })
        moodTrends = Dictionary(dto.moodTrends.map { ($0.key, $0.label) }, uniquingKeysWith: { first, _ in first })
        goalStatuses = Dictionary(dto.goalStatuses.map { ($0.key, $0.label) }, uniquingKeysWith: { first, _ in first })
    }

    init() {
        moodCategories = [:]
        energyLevels = [:]
        moodTrends = [:]
        goalStatuses = [:]
    }

    func label(mood category: EchoMoodCategory) -> String { moodCategories[category.wire] ?? category.wire }
    func label(energy level: EchoEnergyLevel) -> String { energyLevels[level.wire] ?? level.wire }
    func label(trend: EchoMoodTrend) -> String { moodTrends[trend.wire] ?? trend.wire }
    func label(goalStatus status: EchoGoalStatus) -> String { goalStatuses[status.wire] ?? status.wire }
}
