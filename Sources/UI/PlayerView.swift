import SwiftUI
import AVKit

struct PlayerView: View {
    @EnvironmentObject var playerController: PlayerController
    @State private var isHoveringControls = false
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var gestureOffset: CGSize = .zero
    @State private var gestureType: GestureType?
    @State private var showGestureFeedback = false
    @State private var gestureFeedbackText = ""

    enum GestureType {
        case seek
        case volume
    }

    var body: some View {
        ZStack {
            Color.black

            if let player = playerController.player {
                VideoPlayerLayerView(player: player) { layer in
                    playerController.setupPictureInPicture(with: layer)
                }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                handleGesture(value: value)
                            }
                            .onEnded { _ in
                                endGesture()
                            }
                    )
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

            // Gesture feedback overlay
            if showGestureFeedback {
                VStack {
                    Text(gestureFeedbackText)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                }
                .transition(.opacity)
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
                                showControls = true
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
        .onChange(of: playerController.isPlaying) { _, isPlaying in
            if isPlaying {
                scheduleHideControls()
            } else {
                hideControlsTask?.cancel()
                showControls = true
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                if playerController.player != nil {
                    showControls = true
                    scheduleHideControls()
                }
            case .ended:
                break
            }
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
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showControls = false
                    }
                }
            }
        }
    }

    private func toggleFullscreen() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.toggleFullScreen(nil)
    }

    private func handleGesture(value: DragGesture.Value) {
        let translation = value.translation

        // Determine gesture type based on direction
        if gestureType == nil {
            if abs(translation.width) > abs(translation.height) {
                gestureType = .seek
            } else {
                gestureType = .volume
            }
        }

        gestureOffset = translation

        switch gestureType {
        case .seek:
            let seekAmount = Double(translation.width) / 10.0 // 10 pixels = 1 second
            let newTime = playerController.currentTime + seekAmount
            let clampedTime = max(0, min(newTime, playerController.duration))
            let delta = seekAmount > 0 ? "+\(Int(abs(seekAmount)))s" : "\(Int(seekAmount))s"
            gestureFeedbackText = delta
            showGestureFeedback = true

        case .volume:
            let volumeDelta = Float(-translation.height) / 200.0 // 200 pixels = full range
            let newVolume = max(0, min(1, playerController.volume + volumeDelta))
            gestureFeedbackText = "Volume: \(Int(newVolume * 100))%"
            showGestureFeedback = true

        case .none:
            break
        }
    }

    private func endGesture() {
        switch gestureType {
        case .seek:
            let seekAmount = Double(gestureOffset.width) / 10.0
            playerController.seek(by: seekAmount)

        case .volume:
            let volumeDelta = Float(-gestureOffset.height) / 200.0
            playerController.adjustVolume(by: volumeDelta)

        case .none:
            break
        }

        gestureType = nil
        gestureOffset = .zero

        // Hide feedback after delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation {
                    showGestureFeedback = false
                }
            }
        }
    }
}
