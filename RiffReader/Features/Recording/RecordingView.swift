import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var recordedNotes: [Note] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Pitch display
                if let pitch = audioEngine.detectedPitch {
                    Text(String(format: "%.1f Hz", pitch))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                } else {
                    Text("--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Waveform visualization placeholder
                WaveformView(isRecording: audioEngine.isRecording)
                    .frame(height: 200)
                    .padding()

                Spacer()

                // Record button
                Button(action: toggleRecording) {
                    Image(systemName: audioEngine.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(audioEngine.isRecording ? .red : .blue)
                }

                if !recordedNotes.isEmpty {
                    NavigationLink {
                        GameplayView(notes: recordedNotes)
                    } label: {
                        Text("Play Game")
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
