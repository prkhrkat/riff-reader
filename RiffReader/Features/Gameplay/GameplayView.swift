import SwiftUI

struct GameplayView: View {
    var notes: [Note] = []
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var guitarNotes: [GuitarNote] = []

    private let melodyExtractor = MelodyExtractor()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Score and info area
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(guitarNotes.count) Notes")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(String(format: "%.1fs", notes.last?.startTime ?? 0))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        if isPlaying {
                            Text(String(format: "%.1fs", currentTime))
                                .font(.system(size: 20, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()

                    // Guitar strings and notes
                    GuitarStringsView(
                        guitarNotes: guitarNotes,
                        currentTime: currentTime,
                        isPlaying: isPlaying,
                        geometry: geometry
                    )

                    // Control buttons
                    HStack(spacing: 40) {
                        Button(action: { togglePlayback() }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }

                        Button(action: { resetPlayback() }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Guitar View")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            mapNotesToGuitar()
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if isPlaying {
                currentTime += 0.016
                if currentTime > (notes.last?.startTime ?? 0) + 2.0 {
                    isPlaying = false
                }
            }
        }
    }

    private func mapNotesToGuitar() {
        guitarNotes = melodyExtractor.mapToGuitar(notes: notes)
        print("🎸 Mapped \(notes.count) notes to \(guitarNotes.count) guitar positions")
    }

    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying && currentTime > (notes.last?.startTime ?? 0) + 1.0 {
            currentTime = 0
        }
    }

    private func resetPlayback() {
        currentTime = 0
        isPlaying = false
    }
}

struct GuitarStringsView: View {
    let guitarNotes: [GuitarNote]
    let currentTime: TimeInterval
    let isPlaying: Bool
    let geometry: GeometryProxy

    private let stringCount = 6
    private let hitZoneX: CGFloat = 80 // Left side hit zone

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.black)

            // Draw strings
            VStack(spacing: 0) {
                ForEach(1...stringCount, id: \.self) { stringNumber in
                    HStack(spacing: 0) {
                        // Hit zone indicator
                        Rectangle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: hitZoneX)
                            .overlay(
                                Text(getStringName(stringNumber))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                            )

                        // String line
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                    }
                    .frame(height: geometry.size.height * 0.6 / CGFloat(stringCount))
                }
            }
            .frame(height: geometry.size.height * 0.6)

            // Draw notes
            ForEach(guitarNotes) { guitarNote in
                NoteView(
                    guitarNote: guitarNote,
                    currentTime: currentTime,
                    screenWidth: geometry.size.width,
                    stringHeight: geometry.size.height * 0.6 / CGFloat(stringCount),
                    hitZoneX: hitZoneX
                )
            }
        }
    }

    private func getStringName(_ number: Int) -> String {
        guard let guitarString = GuitarString(rawValue: number) else { return "" }
        return guitarString.name
    }
}

struct NoteView: View {
    let guitarNote: GuitarNote
    let currentTime: TimeInterval
    let screenWidth: CGFloat
    let stringHeight: CGFloat
    let hitZoneX: CGFloat

    private let travelTime: TimeInterval = 3.0 // Time for note to travel across screen

    var body: some View {
        let timeUntilNote = guitarNote.note.startTime - currentTime
        let progress = 1.0 - (timeUntilNote / travelTime)

        // X position: starts from right, moves to left (hit zone)
        let xPosition = hitZoneX + (screenWidth - hitZoneX) * CGFloat(1.0 - progress)

        // Y position: based on string number (1 = top, 6 = bottom)
        let stringIndex = guitarNote.string.rawValue - 1
        let yPosition = stringHeight * (CGFloat(stringIndex) + 0.5)

        let isVisible = progress >= 0 && progress <= 1.2

        if isVisible {
            ZStack {
                // Note background
                RoundedRectangle(cornerRadius: 8)
                    .fill(getNoteColor(progress: progress))
                    .frame(width: 50, height: 35)

                // Fret number
                Text("\(guitarNote.fret)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .position(x: xPosition, y: yPosition)
            .opacity(getOpacity(progress: progress))
        }
    }

    private func getNoteColor(progress: Double) -> Color {
        if progress >= 0.9 && progress <= 1.1 {
            return .green // In hit zone
        } else if progress > 1.1 {
            return .red // Missed
        } else {
            return .blue // Approaching
        }
    }

    private func getOpacity(progress: Double) -> Double {
        if progress > 1.2 {
            return 0
        } else if progress < 0 {
            return 0.3
        } else {
            return 1.0
        }
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
