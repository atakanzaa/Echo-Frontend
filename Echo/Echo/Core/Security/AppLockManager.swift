import SwiftUI
import LocalAuthentication
import Observation

@Observable
@MainActor
final class AppLockManager {
    private(set) var isEnabled: Bool
    private(set) var isUnlocked: Bool
    private(set) var errorMessage: String?
    @ObservationIgnored private let defaults: UserDefaults
    private let key = "echo.app-lock.enabled"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: key)
        isUnlocked = !defaults.bool(forKey: key)
    }

    func enable() async {
        guard await authenticate() else { return }
        isEnabled = true
        isUnlocked = true
        defaults.set(true, forKey: key)
    }

    func disable() {
        isEnabled = false
        isUnlocked = true
        errorMessage = nil
        defaults.set(false, forKey: key)
    }

    func lock() {
        guard isEnabled else { return }
        isUnlocked = false
    }

    @discardableResult
    func unlock() async -> Bool {
        guard isEnabled else { isUnlocked = true; return true }
        let success = await authenticate()
        if success { isUnlocked = true }
        return success
    }

    /// Yönetim işlemleri: uygulama kilidi kapalı olsa da her seferinde cihaz sahibinin onayı istenir.
    func confirmOwner(reason: String) async -> Bool {
        #if DEBUG
        if bypassesOwnerCheck { return true }
        #endif
        return await authenticate(reason: reason)
    }

    #if DEBUG
    /// Yalnız önizleme: simülatörde Face ID olmadan panel akışlarını denemek için.
    @ObservationIgnored var bypassesOwnerCheck = false
    #endif

    private func authenticate(reason: String = String(localized: "lock.reason")) async -> Bool {
        let context = LAContext()
        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            errorMessage = policyError?.localizedDescription ?? String(localized: "lock.unavailable")
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason)
            errorMessage = nil
            return success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct AppLockView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(spacing: AppTheme.space.lg) {
            EchoRippleMark(systemImage: "faceid")
            Text("lock.title").echoTextStyle(.title1)
            Text("lock.message")
                .echoTextStyle(.body)
                .foregroundStyle(AppTheme.color.content.secondary)
                .multilineTextAlignment(.center)
            if let error = environment.appLock.errorMessage {
                Text(error).echoTextStyle(.footnote).foregroundStyle(AppTheme.color.feedback.danger)
            }
            EchoButton("lock.unlock", leadingIcon: "faceid") {
                Task { await environment.appLock.unlock() }
            }
        }
        .padding(AppTheme.layout.screenHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.color.bg.canvas)
        .task { await environment.appLock.unlock() }
    }
}
