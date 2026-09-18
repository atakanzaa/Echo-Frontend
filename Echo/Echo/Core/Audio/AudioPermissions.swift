import AVFoundation
import Speech

/// Mikrofon ve konuşma tanıma izinleri. İzin durumu cihaz kararıdır; uygulama sonucu olduğu gibi gösterir.
nonisolated enum AudioPermissions {
    nonisolated enum Status: Sendable {
        case granted
        case denied
        case undetermined
    }

    static var microphone: Status {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: .granted
        case .denied: .denied
        default: .undetermined
        }
    }

    static var speechRecognition: Status {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: .granted
        case .denied, .restricted: .denied
        default: .undetermined
        }
    }

    static func requestMicrophone() async -> Status {
        await withCheckedContinuation { continuation in

            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted ? .granted : .denied)
            }
        }
    }

    static func requestSpeechRecognition() async -> Status {
        await withCheckedContinuation { continuation in

            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized: continuation.resume(returning: .granted)
                case .denied, .restricted: continuation.resume(returning: .denied)
                default: continuation.resume(returning: .undetermined)
                }
            }
        }
    }
}
