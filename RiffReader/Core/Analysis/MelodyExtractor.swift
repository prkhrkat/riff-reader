import Foundation

/// Extracts melody from a sequence of detected notes
class MelodyExtractor {

    /// Extract the main melody line from polyphonic audio
    /// In a hybrid approach, this can be enhanced with cloud-based source separation
    func extractMelody(from notes: [Note]) -> [Note] {
        // Simple algorithm: keep the highest note in each time window
        // This can be improved with ML models for better melody extraction

        let timeWindow: TimeInterval = 0.1 // 100ms windows
        var melody: [Note] = []
        var currentWindow: [Note] = []
        var currentWindowStart: TimeInterval = 0

        for note in notes.sorted(by: { $0.startTime < $1.startTime }) {
            if note.startTime >= currentWindowStart + timeWindow {
                // Process current window
                if let highestNote = currentWindow.max(by: { $0.frequency < $1.frequency }) {
                    melody.append(highestNote)
                }

                // Start new window
                currentWindow = [note]
                currentWindowStart = note.startTime
            } else {
                currentWindow.append(note)
            }
        }

        // Process last window
        if let highestNote = currentWindow.max(by: { $0.frequency < $1.frequency }) {
            melody.append(highestNote)
        }

        return melody
    }

    /// Map notes to guitar fretboard positions
    func mapToGuitar(notes: [Note]) -> [GuitarNote] {
        var guitarNotes: [GuitarNote] = []

        for note in notes {
            if let position = findOptimalGuitarPosition(for: note) {
                guitarNotes.append(position)
            }
        }

        return guitarNotes
    }

    private func findOptimalGuitarPosition(for note: Note) -> GuitarNote? {
        var bestPosition: (string: GuitarString, fret: Int)?
        var minStretch = Int.max

        // Try each string
        for guitarString in GuitarString.allCases {
            let openFreq = guitarString.openStringFrequency

            // Calculate fret number
            let fret = Int(round(12 * log2(note.frequency / openFreq)))

            // Check if playable (0-22 frets typically)
            if fret >= 0 && fret <= 22 {
                let stretch = abs(fret - 5) // Prefer middle positions
                if stretch < minStretch {
                    minStretch = stretch
                    bestPosition = (guitarString, fret)
                }
            }
        }

        if let position = bestPosition {
            return GuitarNote(note: note, string: position.string, fret: position.fret)
        }

        return nil
    }
}
