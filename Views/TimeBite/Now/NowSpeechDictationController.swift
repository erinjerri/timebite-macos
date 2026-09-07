import AVFoundation
import Combine
import Foundation
import SwiftUI
import Speech

@MainActor
final class NowSpeechDictationController: ObservableObject {
    enum State: Equatable {
        case idle
        case processing
        case listening
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var composedText = ""

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var baseText = ""

    init(locale: Locale = .autoupdatingCurrent) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    var isActive: Bool {
        switch state {
        case .processing, .listening:
            return true
        case .idle, .error:
            return false
        }
    }

    var statusText: String? {
        switch state {
        case .idle:
            return nil
        case .processing:
            return "Preparing dictation..."
        case .listening:
            return "Listening..."
        case .error(let message):
            return message
        }
    }

    var buttonTint: Color {
        switch state {
        case .idle:
            return .secondary
        case .processing:
            return TimeBitePalette.gold
        case .listening:
            return .red
        case .error:
            return .red
        }
    }

    func toggleDictation(currentText: String) {
        switch state {
        case .idle, .error:
            Task { await startDictation(currentText: currentText) }
        case .processing, .listening:
            stopDictation()
        }
    }

    func stopDictation() {
        guard isActive else { return }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        state = .idle
    }

    private func startDictation(currentText: String) async {
        guard speechRecognizer?.isAvailable == true else {
            state = .error("Speech recognition is unavailable on this Mac.")
            return
        }

        state = .processing
        baseText = currentText
        composedText = currentText

        guard await requestSpeechRecognitionAuthorization() else {
            state = .error("Speech recognition permission is required.")
            return
        }

        guard await requestMicrophoneAuthorization() else {
            state = .error("Microphone access is required.")
            return
        }

        do {
            try beginRecognition()
        } catch {
            state = .error(error.localizedDescription)
            cleanupRecognition()
        }
    }

    private func beginRecognition() throws {
        cleanupRecognition()

        let inputNode = audioEngine.inputNode
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        self.recognitionRequest = recognitionRequest

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        state = .listening

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            guard self.isActive else { return }

            if let result {
                self.composedText = self.combinedText(from: result.bestTranscription.formattedString)
                if result.isFinal {
                    self.finishDictation()
                }
                return
            }

            if let error {
                self.state = .error(error.localizedDescription)
                self.cleanupRecognition()
            }
        }
    }

    private func finishDictation() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        state = .idle
    }

    private func cleanupRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func combinedText(from recognizedText: String) -> String {
        let prefix = baseText
        guard !prefix.isEmpty else { return recognizedText }
        guard !recognizedText.isEmpty else { return prefix }

        return prefix.hasSuffix("\n") || prefix.hasSuffix(" ") ? prefix + recognizedText : prefix + " " + recognizedText
    }

    private func requestSpeechRecognitionAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
