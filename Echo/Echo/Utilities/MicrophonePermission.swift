import Foundation
import AVFoundation

enum MicrophonePermission {
    enum AccessState: Equatable {
        case granted
        case denied

        var errorMessage: String {
            let turkish = Locale.autoupdatingCurrent.identifier.lowercased().hasPrefix("tr")
            return turkish
                ? "Kayit icin mikrofon izni gerekiyor. Ayarlar'dan etkinlestirebilirsiniz."
                : "Microphone access is required to record. You can enable it in Settings."
        }
    }

    @MainActor
    static func requestAccess() async -> AccessState {
        let session = AVAudioSession.sharedInstance()

        switch session.recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            let granted: Bool = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                session.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            return granted ? .granted : .denied
        @unknown default:
            return .denied
        }
    }
}
