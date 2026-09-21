import SwiftUI
import StoreKit

@Observable
@MainActor
private final class SubscriptionViewModel {
    private(set) var status: SubscriptionStatus?
    private(set) var catalog: SubscriptionCatalog?
    private(set) var isLoading = false
    private(set) var error: AppError?
    @ObservationIgnored let service: any SubscriptionServicing

    init(service: any SubscriptionServicing) { self.service = service }
    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            async let status = service.status()
            async let catalog = service.products()
            self.status = try await status
            self.catalog = try await catalog
        } catch { self.error = AppError.displayable(error) }
    }
}

struct SubscriptionView: View {
    @Environment(AppRouter.self) private var router
    @State private var model: SubscriptionViewModel
    init(subscription: any SubscriptionServicing) {
        _model = State(initialValue: SubscriptionViewModel(service: subscription))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.layout.sectionGap) {
                if let error = model.error { EchoBanner(kind: .danger, title: JournalPresentation.errorMessage(error)) }
                if let status = model.status {
                    EchoCard(style: .raised) {
                        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                            Text(status.tier).echoTextStyle(.title1)
                            if let start = status.periodStart, let end = status.periodEnd {
                                Text("\(start.isoString) – \(end.isoString)")
                                    .echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                            }
                            if status.paywallOffer {
                                EchoButton("subscription.upgrade", fullWidth: true) { router.present(.paywall) }
                            }
                        }
                    }
                    if !status.quotas.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                            EchoSectionHeader("subscription.usage")
                            ForEach(status.quotas) { quota in quotaRow(quota) }
                        }
                    }
                } else if model.isLoading { ProgressView().frame(minHeight: 240) }
            }
            .padding(.horizontal, AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .navigationTitle(Text("subscription.title"))
        .task { await model.load() }
        .echoRefreshable { await model.load() }
    }

    private func quotaRow(_ quota: SubscriptionStatus.Quota) -> some View {
        EchoCard(style: .flat) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.space.xxxs) {
                    Text(quota.feature).echoTextStyle(.headline)
                    Text(quota.scope).echoTextStyle(.caption).foregroundStyle(AppTheme.color.content.tertiary)
                }
                Spacer()
                if quota.isUnlimited {
                    Text("subscription.unlimited").echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.accent)
                } else if let remaining = quota.remaining {
                    Text(String(format: String(localized: "subscription.remaining"), remaining))
                        .echoTextStyle(.subhead).foregroundStyle(AppTheme.color.content.secondary)
                }
            }
        }
    }
}

@Observable
@MainActor
private final class PaywallViewModel {
    private(set) var catalog: SubscriptionCatalog?
    private(set) var products: [StoreKit.Product] = []
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    private(set) var message: String?
    var selectedProductID: String?
    @ObservationIgnored private let service: any SubscriptionServicing

    init(service: any SubscriptionServicing) { self.service = service }

    func load() async {
        guard !isLoading else { return }
        isLoading = true; message = nil
        defer { isLoading = false }
        do {
            let catalog = try await service.products()
            self.catalog = catalog
            products = try await StoreKit.Product.products(for: catalog.products.map(\.productID))
            products.sort { $0.price < $1.price }
            selectedProductID = catalog.products.first(where: { plan in
                plan.isHighlighted && products.contains(where: { $0.id == plan.productID })
            })?.productID
                ?? products.first?.id
        } catch { message = JournalPresentation.errorMessage(AppError.from(error)) }
    }

    func purchaseSelected() async -> Bool {
        guard let product = products.first(where: { $0.id == selectedProductID }), !isPurchasing else { return false }
        isPurchasing = true; message = nil
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = String(localized: "subscription.verificationFailed"); return false
                }
                _ = try await service.verify(signedTransaction: verification.jwsRepresentation)
                await transaction.finish()
                return true
            case .pending:
                message = String(localized: "subscription.pending")
            case .userCancelled: break
            @unknown default: break
            }
        } catch { message = error.localizedDescription }
        return false
    }

    func restore() async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true; message = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            for await verification in Transaction.currentEntitlements {
                guard case .verified(let transaction) = verification else { continue }
                _ = try await service.restore(signedTransaction: verification.jwsRepresentation)
                await transaction.finish()
                return true
            }
            message = String(localized: "subscription.nothingToRestore")
        } catch { message = error.localizedDescription }
        return false
    }

    func dismiss() async { try? await service.dismissPaywall() }
}

struct PaywallView: View {
    @State private var model: PaywallViewModel
    let onClose: () -> Void
    init(subscription: any SubscriptionServicing, onClose: @escaping () -> Void) {
        _model = State(initialValue: PaywallViewModel(service: subscription))
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space.lg) {
                EchoBrandMark(size: 150, tint: AppTheme.color.accent.primary)
                VStack(spacing: AppTheme.space.xxs) {
                    Text("subscription.proTitle").echoTextStyle(.display)
                    Text("subscription.proMessage").echoTextStyle(.body).foregroundStyle(AppTheme.color.content.secondary)
                        .multilineTextAlignment(.center)
                }
                if let catalog = model.catalog {
                    VStack(alignment: .leading, spacing: AppTheme.space.xs) {
                        ForEach(catalog.features) { feature in
                            Label(feature.feature, systemImage: "checkmark.circle.fill")
                                .echoTextStyle(.body).foregroundStyle(AppTheme.color.content.primary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if model.products.isEmpty, !model.isLoading {
                    Text("subscription.productsUnavailable").echoTextStyle(.footnote).foregroundStyle(AppTheme.color.content.secondary)
                } else {
                    HStack(alignment: .top, spacing: AppTheme.space.xs) {
                        ForEach(model.products, id: \.id) { product in
                            EchoPlanCard(planName: planName(product), priceText: product.displayPrice,
                                         periodText: periodText(product),
                                         isHighlighted: model.catalog?.products.first(where: { $0.productID == product.id })?.isHighlighted == true,
                                         isSelected: model.selectedProductID == product.id,
                                         onSelect: { model.selectedProductID = product.id })
                        }
                    }
                }
                if let message = model.message { Text(message).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.feedback.warning) }
                EchoButton("subscription.continue", size: .lg, fullWidth: true, isLoading: model.isPurchasing) {
                    Task { if await model.purchaseSelected() { onClose() } }
                }
                .disabled(model.selectedProductID == nil)
                Button("subscription.restore") { Task { if await model.restore() { onClose() } } }
                    .echoTextStyle(.subhead)
            }
            .padding(AppTheme.layout.screenHorizontalPadding)
            .padding(.bottom, AppTheme.space.xl)
        }
        .background(AppTheme.color.bg.canvas)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { Task { await model.dismiss(); onClose() } } label: { Image(systemName: "xmark") }
                    .accessibilityLabel(Text("common.close"))
            }
        }
        .task { await model.load() }
    }

    private func planName(_ product: StoreKit.Product) -> String {
        model.catalog?.products.first(where: { $0.productID == product.id })?.plan ?? product.displayName
    }
    private func periodText(_ product: StoreKit.Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        return String(format: String(localized: "subscription.period"), period.value, String(describing: period.unit))
    }
}
