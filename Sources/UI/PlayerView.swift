import SwiftUI
import AVKit

struct PlayerView: View {
    @EnvironmentObject var playerController: PlayerController
    @State private var isHoveringControls = false
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black

            if let player = playerController.player {
                VideoPlayerLayerView(player: player)
                    .onTapGesture(count: 2) {
                        toggleFullscreen()
                    }
                    .onTapGesture {
                        showControls.toggle()
                        scheduleHideControls()
                    }
            } else {
                dropZoneView
            }

            if playerController.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            }

            if let error = playerController.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                }
            }

            VStack {
                Spacer()

                if showControls && playerController.player != nil {
                    ControlsView()
                        .environmentObject(playerController)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onHover { hovering in
                            isHoveringControls = hovering
                            if hovering {
                                hideControlsTask?.cancel()
                            } else {
                                scheduleHideControls()
                            }
                        }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            scheduleHideControls()
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 72))
                .foregroundColor(.gray)

            Text("Drop a video file here")
                .font(.title2)
                .foregroundColor(.gray)

            Text("or press Cmd+O to open")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            DispatchQueue.main.async {
                playerController.loadMedia(from: url)
            }
        }

        return true
    }

    private func scheduleHideControls() {
        hideControlsTask?.cancel()

        guard playerController.isPlaying else { return }

        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled && !isHoveringControls {
                withAnimation {
                    showControls = false
                }
            }
        }
    }

    private func toggleFullscreen() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.toggleFullScreen(nil)
    }
}
