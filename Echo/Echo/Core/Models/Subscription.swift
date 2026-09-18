import Foundation
import EchoAPI

/// Abonelik ve kota durumu. Kalan hak, izinli eylem ve paywall kararı sunucudan gelir (rules.md §8).
nonisolated struct SubscriptionStatus: Sendable, Equatable {
    let tier: String
    let periodStart: LocalDay?
    let periodEnd: LocalDay?
    let adsEnabled: Bool
    let paywallOffer: Bool
    let paywallReasonCode: String
    let quotas: [Quota]

    nonisolated struct Quota: Sendable, Equatable, Identifiable {
        let feature: String
        let used: Int?
        let limit: Int
        let isUnlimited: Bool
        let remaining: Int?
        let scope: String
        let allowedActions: [EchoAllowedAction]
        let reasonCode: String

        var id: String { feature }
    }

    init(dto: Components.Schemas.QuotaStatusResponse) {
        tier = dto.tier.value1?.rawValue ?? dto.tier.value2 ?? ""
        periodStart = LocalDay(dto.periodStart)
        periodEnd = LocalDay(dto.periodEnd)
        adsEnabled = dto.adsEnabled
        paywallOffer = dto.paywall.offer
        paywallReasonCode = dto.paywall.reasonCode.value1?.rawValue ?? dto.paywall.reasonCode.value2 ?? ""
        quotas = dto.quotas.map {
            Quota(feature: $0.feature.value1?.rawValue ?? $0.feature.value2 ?? "",
                  used: $0.used.map(Int.init),
                  limit: Int($0.limit),
                  isUnlimited: $0.unlimited,
                  remaining: $0.remaining.map(Int.init),
                  scope: $0.scope.value1?.rawValue ?? $0.scope.value2 ?? "",
                  allowedActions: $0.allowedActions.map { EchoAllowedAction(wire: $0.value1?.rawValue ?? $0.value2 ?? "") },
                  reasonCode: $0.reasonCode.value1?.rawValue ?? $0.reasonCode.value2 ?? "")
        }
    }
}

/// Paywall kataloğu. Fiyat StoreKit'ten okunur; backend fiyat göndermez.
nonisolated struct SubscriptionCatalog: Sendable, Equatable {
    let products: [Product]
    let features: [FeatureAllowance]

    nonisolated struct Product: Sendable, Equatable, Identifiable {
        let productID: String
        let plan: String
        let tier: String
        let isHighlighted: Bool
        var id: String { productID }
    }

    nonisolated struct FeatureAllowance: Sendable, Equatable, Identifiable {
        let feature: String
        let freeLimit: Int?
        let freeUnlimited: Bool
        let premiumLimit: Int?
        let premiumUnlimited: Bool
        var id: String { feature }
    }

    init(dto: Components.Schemas.SubscriptionProductsResponse) {
        products = dto.products.map {
            Product(productID: $0.productId,
                    plan: $0.plan.value1?.rawValue ?? $0.plan.value2 ?? "",
                    tier: $0.tier.value1?.rawValue ?? $0.tier.value2 ?? "",
                    isHighlighted: $0.highlighted)
        }
        features = dto.features.map {
            FeatureAllowance(feature: $0.feature.value1?.rawValue ?? $0.feature.value2 ?? "",
                             freeLimit: $0.freeLimit.map(Int.init),
                             freeUnlimited: $0.freeUnlimited,
                             premiumLimit: $0.premiumLimit.map(Int.init),
                             premiumUnlimited: $0.premiumUnlimited)
        }
    }
}

/// Rıza durumu (KVKK, AI eğitimi, topluluk kuralları).
nonisolated struct ConsentStatus: Sendable, Equatable {
    let aiTrainingConsent: Bool
    let aiTrainingConsentAt: Date?
    let kvkkExplicitConsent: Bool
    let kvkkConsentAt: Date?
    let privacyPolicyVersion: String?
    let communityTermsVersion: String?
    let communityTermsAcceptedAt: Date?

    init(dto: Components.Schemas.ConsentStatusResponse) {
        aiTrainingConsent = dto.aiTrainingConsent
        aiTrainingConsentAt = dto.aiTrainingConsentAt
        kvkkExplicitConsent = dto.kvkkExplicitConsent
        kvkkConsentAt = dto.kvkkConsentAt
        privacyPolicyVersion = dto.privacyPolicyVersion
        communityTermsVersion = dto.communityTermsVersion
        communityTermsAcceptedAt = dto.communityTermsAcceptedAt
    }
}

/// Satın alma doğrulaması sonucu. Premium kararını backend verir; istemci tier adından çıkarmaz.
nonisolated struct PurchaseResult: Sendable, Equatable {
    let tier: String
    let status: String
    let productID: String
    let purchaseDate: Date
    let expiresDate: Date
    let autoRenewEnabled: Bool
    let adsEnabled: Bool

    init(dto: Components.Schemas.SubscriptionResponse) {
        tier = dto.tier.value1?.rawValue ?? dto.tier.value2 ?? ""
        status = dto.status.value1?.rawValue ?? dto.status.value2 ?? ""
        productID = dto.productId
        purchaseDate = dto.purchaseDate
        expiresDate = dto.expiresDate
        autoRenewEnabled = dto.autoRenewEnabled
        adsEnabled = dto.adsEnabled
    }
}
