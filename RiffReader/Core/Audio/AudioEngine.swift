import AVFoundation
import Combine
import Accelerate

/// Main audio engine for recording, processing, and analyzing audio
class AudioEngine: ObservableObject {
    @Published var isRecording = false
    @Published var detectedPitch: Double?
    @Published var currentNotes: [Note] = []

    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private let pitchDetector: PitchDetector

    init() {
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        self.pitchDetector = PitchDetector()

        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startRecording() {
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        if let pitch = pitchDetector.detectPitch(samples: samples, sampleRate: buffer.format.sampleRate) {
            DispatchQueue.main.async {
                self.detectedPitch = pitch
            }
        }
    }
}
