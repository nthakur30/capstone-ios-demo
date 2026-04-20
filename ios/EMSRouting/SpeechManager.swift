import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var parsedVitals: ParsedVitals?
    @Published var error: String?

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    struct ParsedVitals: Equatable {
        var condition: ConditionType?
        var gcs: Int?
        var sbp: Int?
        var rr: Int?

        var isComplete: Bool {
            condition != nil && gcs != nil && sbp != nil && rr != nil
        }
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else { return false }

        let micStatus = await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
        }
        return micStatus
    }

    func startListening() async {
        guard !isListening else { stopListening(); return }

        let granted = await requestPermissions()
        guard granted else {
            error = "Microphone and speech recognition permissions required."
            return
        }

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.isAvailable == true else {
            error = "Speech recognition unavailable."
            return
        }

        do {
            transcript = ""
            parsedVitals = nil
            error = nil

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            request?.shouldReportPartialResults = true

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }

            engine.prepare()
            try engine.start()
            isListening = true

            task = recognizer?.recognitionTask(with: request!) { [weak self] result, err in
                guard let self else { return }
                if let result {
                    Task { @MainActor in
                        self.transcript = result.bestTranscription.formattedString
                        self.parsedVitals = self.parse(self.transcript)
                    }
                }
                if err != nil || result?.isFinal == true {
                    Task { @MainActor in self.stopListening() }
                }
            }
        } catch {
            self.error = "Could not start listening: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isListening = false
    }

    // MARK: - Parsing spoken vitals

    private func parse(_ text: String) -> ParsedVitals {
        let lower = text.lowercased()
        var v = ParsedVitals()

        // Condition detection
        if lower.contains("stemi") || lower.contains("heart attack") || lower.contains("cardiac") {
            v.condition = .STEMI
        } else if lower.contains("stroke") || lower.contains("neurolog") || lower.contains("brain") {
            v.condition = .STROKE
        } else if lower.contains("trauma") || lower.contains("accident") || lower.contains("injury") || lower.contains("crash") {
            v.condition = .TRAUMA
        } else if lower.contains("general") || lower.contains("medical") || lower.contains("shortness") {
            v.condition = .GENERAL
        }

        // GCS - "GCS 13", "Glasgow 12", "gcs of 10"
        v.gcs = extractNumber(from: lower, patterns: [
            #"gcs\s*(?:of\s*)?(\d+)"#,
            #"glasgow\s*(?:coma\s*)?(?:scale\s*)?(?:of\s*)?(\d+)"#,
            #"(?:consciousness|responsive)\s*(?:of\s*)?(\d+)"#,
        ], range: 3...15)

        // SBP - "blood pressure 90", "BP 110", "systolic 85", "pressure 120 over"
        v.sbp = extractNumber(from: lower, patterns: [
            #"(?:systolic|sbp)\s*(?:of\s*)?(\d+)"#,
            #"(?:blood\s*pressure|bp)\s*(?:of\s*)?(\d+)"#,
            #"pressure\s*(?:of\s*)?(\d+)"#,
        ], range: 0...300)

        // RR - "respiratory rate 18", "RR 24", "respirations 20", "breathing 16"
        v.rr = extractNumber(from: lower, patterns: [
            #"(?:respiratory\s*rate|rr)\s*(?:of\s*)?(\d+)"#,
            #"respiration[s]?\s*(?:of\s*)?(\d+)"#,
            #"breath(?:ing|s)?\s*(?:of\s*)?(\d+)"#,
        ], range: 0...60)

        return v
    }

    private func extractNumber(from text: String, patterns: [String], range: ClosedRange<Int>) -> Int? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let numRange = Range(match.range(at: 1), in: text),
               let val = Int(text[numRange]),
               range.contains(val) {
                return val
            }
        }
        return nil
    }
}
