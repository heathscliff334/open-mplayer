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

                Button("Open URL...") {
                    openURL()
                }
                .keyboardShortcut("u", modifiers: .command)
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

                Divider()

                Button("Speed Up") {
                    playerController.setPlaybackRate(playerController.playbackRate + 0.25)
                }
                .keyboardShortcut("]", modifiers: [])

                Button("Speed Down") {
                    playerController.setPlaybackRate(playerController.playbackRate - 0.25)
                }
                .keyboardShortcut("[", modifiers: [])

                Button("Normal Speed") {
                    playerController.setPlaybackRate(1.0)
                }
                .keyboardShortcut("\\", modifiers: [])
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

    private func openURL() {
        let alert = NSAlert()
        alert.messageText = "Open URL"
        alert.informativeText = "Enter a video URL (HTTP/HTTPS):"
        alert.alertStyle = .informational

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "https://example.com/video.mp4"
        alert.accessoryView = textField

        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let urlString = textField.stringValue.trimmingCharacters(in: .whitespaces)
            if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" {
                playerController.loadMedia(from: url)
            }
        }
    }
}
