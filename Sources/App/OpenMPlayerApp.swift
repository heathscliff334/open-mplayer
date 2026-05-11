import SwiftUI

@main
struct OpenMPlayerApp: App {
    @StateObject private var playerController = PlayerController()

    var body: some Scene {
        WindowGroup {
            PlayerView()
                .environmentObject(playerController)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("Playback") {
                Button("Play/Pause") {
                    playerController.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Seek Forward") {
                    playerController.seek(by: 5)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Seek Backward") {
                    playerController.seek(by: -5)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Divider()

                Button("Volume Up") {
                    playerController.adjustVolume(by: 0.1)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Volume Down") {
                    playerController.adjustVolume(by: -0.1)
                }
                .keyboardShortcut(.downArrow, modifiers: [])
            }
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .movie, .video, .mpeg4Movie, .quickTimeMovie,
            .avi, .mpeg, .mp3, .wav, .aiff
        ]

        if panel.runModal() == .OK, let url = panel.url {
            playerController.loadMedia(from: url)
        }
    }
}
