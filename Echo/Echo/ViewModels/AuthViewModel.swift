import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoading   = false
    @Published var errorMessage: String?

    private let client = APIClient.shared
    private let appState = AppState.shared

    // MARK: — Register

    func register(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        let timezone = TimeZone.current.identifier
        let body = RegisterBody(
            email: email,
            password: password,
            displayName: displayName,
            timezone: timezone
        )

        do {
            let response: APIAuthResponse = try await client.request(.register(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: — Login

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        let body = LoginBody(email: email, password: password)

        do {
            let response: APIAuthResponse = try await client.request(.login(body))
            appState.signIn(with: response)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
