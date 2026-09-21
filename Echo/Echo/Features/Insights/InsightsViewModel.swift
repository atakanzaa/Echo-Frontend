import Foundation
import Observation

@Observable
@MainActor
final class InsightsViewModel {
    private(set) var eligibility: InsightEligibility?
    private(set) var summary: PeriodSummary?
    private(set) var report: AIInsights?
    private(set) var stats: DetailedStats?
    private(set) var profile: ProfileSummary?
    private(set) var isLoading = false
    private(set) var error: AppError?
    var selectedPeriod = 7

    @ObservationIgnored private let service: any InsightsServicing
    @ObservationIgnored private var periodLoadID = UUID()
    private(set) var didLoadSupportingData = false

    init(service: any InsightsServicing) {
        self.service = service
    }

    var selectedEligibility: InsightEligibility.Period? {
        eligibility?.periods.first { $0.days == selectedPeriod }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let eligibility = try await service.eligibility()
            self.eligibility = eligibility
            if !eligibility.periods.contains(where: { $0.days == selectedPeriod && $0.isUnlocked }) {
                selectedPeriod = eligibility.periods.first(where: { $0.days == eligibility.defaultPeriod && $0.isUnlocked })?.days
                    ?? eligibility.periods.first(where: \.isUnlocked)?.days
                    ?? eligibility.defaultPeriod
            }
            isLoading = false
            await loadSelectedPeriod()
            if !didLoadSupportingData { await loadSupportingData() }
        } catch {
            isLoading = false
            self.error = AppError.from(error)
        }
    }

    func loadSelectedPeriod() async {
        guard selectedEligibility?.isUnlocked == true else {
            summary = nil
            report = nil
            return
        }
        let requestedPeriod = selectedPeriod
        let loadID = UUID()
        periodLoadID = loadID
        isLoading = true
        error = nil
        defer { if periodLoadID == loadID { isLoading = false } }
        do {
            let summary = try await service.summary(periodDays: requestedPeriod, endDay: nil)
            let report = try await service.insights(periodDays: requestedPeriod)
            try Task.checkCancellation()
            guard periodLoadID == loadID, selectedPeriod == requestedPeriod,
                  requestedPeriod == summary.periodDays else { return }
            self.summary = summary
            self.report = report
        } catch is CancellationError {
            return
        } catch {
            guard periodLoadID == loadID else { return }
            self.error = AppError.from(error)
        }
    }

    private func loadSupportingData() async {
        didLoadSupportingData = true
        stats = try? await service.detailedStats()
        profile = try? await service.profileSummary()
    }
}
