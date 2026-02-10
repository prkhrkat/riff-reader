import Foundation

/// Represents a musical note with its properties
struct Note: Identifiable, Codable {
    let id: UUID
    let pitch: Pitch
    let frequency: Double
    let startTime: TimeInterval
    let duration: TimeInterval
    let velocity: Int // 0-127 MIDI velocity

    init(pitch: Pitch, frequency: Double, startTime: TimeInterval, duration: TimeInterval, velocity: Int = 64) {
        self.id = UUID()
        self.pitch = pitch
        self.frequency = frequency
        self.startTime = startTime
        self.duration = duration
        self.velocity = velocity
    }
}

/// Represents a note on the guitar fretboard
struct GuitarNote: Identifiable {
    let id: UUID
    let note: Note
    let string: GuitarString // 1-6, where 1 is high E
    let fret: Int

    init(note: Note, string: GuitarString, fret: Int) {
        self.id = UUID()
        self.note = note
        self.string = string
        self.fret = fret
    }
}

/// Guitar string representation
enum GuitarString: Int, CaseIterable {
    case first = 1   // High E (329.63 Hz)
    case second = 2  // B (246.94 Hz)
    case third = 3   // G (196.00 Hz)
    case fourth = 4  // D (146.83 Hz)
    case fifth = 5   // A (110.00 Hz)
    case sixth = 6   // Low E (82.41 Hz)

    var openStringFrequency: Double {
        switch self {
        case .first: return 329.63
        case .second: return 246.94
        case .third: return 196.00
        case .fourth: return 146.83
        case .fifth: return 110.00
        case .sixth: return 82.41
        }
    }

    var name: String {
        switch self {
        case .first: return "E"
        case .second: return "B"
        case .third: return "G"
        case .fourth: return "D"
        case .fifth: return "A"
        case .sixth: return "E"
        }
    }
}

/// Musical pitch representation
struct Pitch: Codable, Equatable {
    let noteName: NoteName
    let octave: Int

    var midiNote: Int {
        return (octave + 1) * 12 + noteName.chromaticIndex
    }

    var frequency: Double {
        // A4 = 440 Hz, MIDI note 69
        let a4 = 440.0
        let semitoneRatio = pow(2.0, 1.0/12.0)
        return a4 * pow(semitoneRatio, Double(midiNote - 69))
    }
}

enum NoteName: String, Codable, CaseIterable {
    case C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B

    var chromaticIndex: Int {
        switch self {
        case .C: return 0
        case .Cs: return 1
        case .D: return 2
        case .Ds: return 3
        case .E: return 4
        case .F: return 5
        case .Fs: return 6
        case .G: return 7
        case .Gs: return 8
        case .A: return 9
        case .As: return 10
        case .B: return 11
        }
    }

    var displayName: String {
        self.rawValue.replacingOccurrences(of: "s", with: "#")
    }
}
