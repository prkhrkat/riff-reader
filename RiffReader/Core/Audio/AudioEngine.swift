import AVFoundation
import Combine
import Accelerate

/// Main audio engine for recording, processing, and analyzing audio
class AudioEngine: ObservableObject {
    @Published var isRecording = false
    @Published var detectedPitch: Double?
    @Published var currentNotes: [Note] = []
    @Published var recordingTime: TimeInterval = 0

    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private let pitchDetector: PitchDetector
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private var lastDetectedPitch: Double?
    private var lastPitchStartTime: TimeInterval?
    private var noteBuffer: [Note] = []

    // Configuration
    let maxRecordingDuration: TimeInterval = 15.0
    private let minNoteDuration: TimeInterval = 0.05 // 50ms minimum note duration

    init() {
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        self.pitchDetector = PitchDetector()

        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startRecording() {
        // Reset recording state
        noteBuffer = []
        recordingTime = 0
        recordingStartTime = Date()
        lastDetectedPitch = nil
        lastPitchStartTime = nil

        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time)
        }

        do {
            try audioEngine.start()
            isRecording = true
            startRecordingTimer()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Finalize the last note if any
        if let lastPitch = lastDetectedPitch, let startTime = lastPitchStartTime {
            finalizeNote(pitch: lastPitch, startTime: startTime, endTime: recordingTime)
        }

        // Update current notes with buffer
        DispatchQueue.main.async {
            self.currentNotes = self.noteBuffer
            print("📝 Recording stopped. Captured \(self.noteBuffer.count) notes")
        }
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if let startTime = self.recordingStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                self.recordingTime = elapsed

                // Auto-stop at max duration
                if elapsed >= self.maxRecordingDuration {
                    self.stopRecording()
                }
            }
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        let currentTime = recordingTime

        if let detectedFreq = pitchDetector.detectPitch(samples: samples, sampleRate: buffer.format.sampleRate) {
            DispatchQueue.main.async {
                self.detectedPitch = detectedFreq
            }

            // Check if this is a new note or continuation
            if let lastPitch = lastDetectedPitch {
                let pitchDiff = abs(detectedFreq - lastPitch)

                // If pitch changed significantly (more than 20 Hz or 5%), it's a new note
                if pitchDiff > 20.0 || (pitchDiff / lastPitch) > 0.05 {
                    // Finalize the previous note
                    if let startTime = lastPitchStartTime {
                        finalizeNote(pitch: lastPitch, startTime: startTime, endTime: currentTime)
                    }

                    // Start tracking new note
                    lastDetectedPitch = detectedFreq
                    lastPitchStartTime = currentTime
                }
            } else {
                // First note detected
                lastDetectedPitch = detectedFreq
                lastPitchStartTime = currentTime
            }
        } else {
            // No pitch detected - finalize previous note if it exists
            if let lastPitch = lastDetectedPitch, let startTime = lastPitchStartTime {
                finalizeNote(pitch: lastPitch, startTime: startTime, endTime: currentTime)
                lastDetectedPitch = nil
                lastPitchStartTime = nil
            }

            DispatchQueue.main.async {
                self.detectedPitch = nil
            }
        }
    }

    private func finalizeNote(pitch: Double, startTime: TimeInterval, endTime: TimeInterval) {
        let duration = endTime - startTime

        // Only create notes that are long enough
        guard duration >= minNoteDuration else { return }

        // Convert frequency to pitch
        if let detectedPitch = pitchDetector.frequencyToNote(pitch) {
            let note = Note(
                pitch: detectedPitch,
                frequency: pitch,
                startTime: startTime,
                duration: duration,
                velocity: 100
            )

            noteBuffer.append(note)
        }
    }
}
