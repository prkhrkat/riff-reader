import SwiftUI

struct GameplayView: View {
    var notes: [Note] = []
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Score area
                    HStack {
                        Text("Score: 0")
                            .foregroundColor(.white)
                        Spacer()
                        Text("Streak: 0")
                            .foregroundColor(.yellow)
                    }
                    .padding()

                    // Guitar strings and notes
                    GuitarStringsView(
                        notes: notes,
                        currentTime: currentTime,
                        geometry: geometry
                    )

                    // Control buttons
                    HStack(spacing: 40) {
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }

                        Button(action: { currentTime = 0 }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuitarStringsView: View {
    let notes: [Note]
    let currentTime: TimeInterval
    let geometry: GeometryProxy

    private let stringCount = 6
    private let hitZone: CGFloat = 100 // Left side hit zone

    var body: some View {
        ZStack {
            // Draw strings
            VStack(spacing: 0) {
                ForEach(0..<stringCount, id: \.self) { stringIndex in
                    HStack {
                        // Hit zone indicator
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: hitZone)

                        // String line
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                    }
                    .frame(height: geometry.size.height / CGFloat(stringCount))
                }
            }

            // Draw notes (simplified - needs proper mapping)
            ForEach(notes) { note in
                NoteCircle(
                    note: note,
                    currentTime: currentTime,
                    geometry: geometry,
                    hitZone: hitZone
                )
            }
        }
    }
}

struct NoteCircle: View {
    let note: Note
    let currentTime: TimeInterval
    let geometry: GeometryProxy
    let hitZone: CGFloat

    var body: some View {
        let progress = (currentTime - note.startTime) / 3.0 // 3 seconds to traverse screen
        let xPosition = geometry.size.width - (progress * geometry.size.width)

        Circle()
            .fill(Color.blue)
            .frame(width: 40, height: 40)
            .position(x: xPosition, y: geometry.size.height / 2) // Simplified position
            .opacity(xPosition >= -40 && xPosition <= geometry.size.width + 40 ? 1 : 0)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Audio") {
                    Toggle("Auto-tune detection", isOn: .constant(true))
                    Toggle("Background audio", isOn: .constant(false))
                }

                Section("Gameplay") {
                    Picker("Difficulty", selection: .constant(1)) {
                        Text("Easy").tag(0)
                        Text("Medium").tag(1)
                        Text("Hard").tag(2)
                    }

                    Picker("Note speed", selection: .constant(1)) {
                        Text("Slow").tag(0)
                        Text("Normal").tag(1)
                        Text("Fast").tag(2)
                    }
                }

                Section("Analysis") {
                    Toggle("Cloud enhancement", isOn: .constant(false))
                    Text("Use cloud-based analysis for better melody extraction")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    GameplayView()
}
