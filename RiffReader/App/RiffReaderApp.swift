import SwiftUI

@main
struct RiffReaderApp: App {
    @StateObject private var audioEngine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
        }
    }
}
