import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var recordedNotes: [Note] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Recording timer
                if audioEngine.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text(formatTime(audioEngine.recordingTime))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                        Text("/ 15s")
                            .font(.system(size: 16, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                }

                // Pitch display
                VStack(spacing: 8) {
                    if let pitch = audioEngine.detectedPitch {
                        Text(String(format: "%.1f Hz", pitch))
                            .font(.system(size: 48, weight: .bold, design: .rounded))

                        Text(getNoteName(from: pitch))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.blue)
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                // Waveform visualization placeholder
                WaveformView(isRecording: audioEngine.isRecording)
                    .frame(height: 200)
                    .padding()

                Spacer()

                // Record button
                Button(action: toggleRecording) {
                    VStack(spacing: 12) {
                        Image(systemName: audioEngine.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(audioEngine.isRecording ? .red : .blue)

                        Text(audioEngine.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.headline)
                            .foregroundStyle(audioEngine.isRecording ? .red : .blue)
                    }
                }

                if !recordedNotes.isEmpty {
                    VStack(spacing: 12) {
                        Text("Recorded \(recordedNotes.count) notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            GameplayView(notes: recordedNotes)
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("View on Guitar")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
            .navigationTitle("Record")
        }
    }

    private func toggleRecording() {
        if audioEngine.isRecording {
            audioEngine.stopRecording()
            recordedNotes = audioEngine.currentNotes
        } else {
            audioEngine.startRecording()
            recordedNotes = []
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d.%01d", seconds, milliseconds)
    }

    private func getNoteName(from frequency: Double) -> String {
        // Simple frequency to note conversion
        let midiNote = 69 + 12 * log2(frequency / 440.0)
        let roundedMidi = Int(round(midiNote))
        let octave = (roundedMidi / 12) - 1
        let noteIndex = roundedMidi % 12

        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteName = noteNames[noteIndex]

        return "\(noteName)\(octave)"
    }
}

struct WaveformView: View {
    let isRecording: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))

            if isRecording {
                // Animated waveform placeholder
                HStack(spacing: 4) {
                    ForEach(0..<20) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 8)
                    }
                }
            } else {
                Text("Tap mic to start recording")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RecordingView()
        .environmentObject(AudioEngine())
}
