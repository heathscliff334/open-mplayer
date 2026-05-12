import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var playerController: PlayerController
    @State private var isSeeking = false
    @State private var seekPosition: Double = 0
    @State private var showSpeedMenu = false

    var body: some View {
        VStack(spacing: 12) {
            // Timeline
            timelineView

            // Controls
            HStack(spacing: 24) {
                // Play/Pause
                Button(action: {
                    playerController.togglePlayPause()
                }) {
                    Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                // Time display
                Text(formatTime(playerController.currentTime))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Volume control
                HStack(spacing: 8) {
                    Image(systemName: volumeIcon)
                        .foregroundColor(.white)

                    Slider(value: Binding(
                        get: { Double(playerController.volume) },
                        set: { playerController.setVolume(Float($0)) }
                    ), in: 0...1)
                    .frame(width: 100)
                    .tint(.white)
                }

                // Duration
                Text(formatTime(playerController.duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))

                // Playback speed
                Menu {
                    ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], id: \.self) { speed in
                        Button(action: {
                            playerController.setPlaybackRate(Float(speed))
                        }) {
                            HStack {
                                Text(String(format: "%.2fx", speed))
                                if abs(playerController.playbackRate - Float(speed)) < 0.01 {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(String(format: "%.2fx", playerController.playbackRate))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 60)

                // Picture in Picture
                if playerController.pipController != nil {
                    Button(action: {
                        playerController.togglePictureInPicture()
                    }) {
                        Image(systemName: playerController.isPipActive ? "pip.exit" : "pip.enter")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Fullscreen
                Button(action: toggleFullscreen) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var timelineView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // Progress track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)

                // Seek indicator
                if isSeeking {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: progressWidth(in: geometry.size.width) - 6)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isSeeking = true
                        let progress = max(0, min(1, value.location.x / geometry.size.width))
                        seekPosition = progress * playerController.duration
                    }
                    .onEnded { value in
                        let progress = max(0, min(1, value.location.x / geometry.size.width))
                        let time = progress * playerController.duration
                        playerController.seek(to: time)
                        isSeeking = false
                    }
            )
        }
        .frame(height: 20)
        .padding(.horizontal, 16)
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard playerController.duration > 0 else { return 0 }
        let time = isSeeking ? seekPosition : playerController.currentTime
        return totalWidth * CGFloat(time / playerController.duration)
    }

    private var volumeIcon: String {
        if playerController.volume == 0 {
            return "speaker.slash.fill"
        } else if playerController.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if playerController.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func toggleFullscreen() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.toggleFullScreen(nil)
    }
}
