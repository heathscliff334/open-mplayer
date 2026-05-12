import AVFoundation
import Combine
import SwiftUI
import AVKit

@MainActor
class PlayerController: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0
    @Published var playbackRate: Float = 1.0
    @Published var currentMediaURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pipController: AVPictureInPictureController?
    @Published var isPipActive = false

    private var pipDelegate: PipDelegate?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    // MARK: - Media Loading

    func loadMedia(from url: URL) {
        isLoading = true
        errorMessage = nil
        currentMediaURL = url

        // For remote URLs, skip file checks and conversion
        if !url.isFileURL {
            Task {
                await loadAVAsset(from: url)
            }
            return
        }

        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "File not found: \(url.lastPathComponent)"
            isLoading = false
            return
        }

        // Check if conversion is needed
        if MediaConverter.shared.needsConversion(url: url) {
            Task {
                do {
                    await MainActor.run {
                        self.errorMessage = "Converting \(url.pathExtension.uppercased()) to MP4...\nThis may take a moment."
                    }
                    let convertedURL = try await MediaConverter.shared.convert(url: url) { progress in
                        // Update progress if needed
                    }
                    await MainActor.run {
                        self.errorMessage = nil
                    }
                    await loadAVAsset(from: convertedURL)
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Conversion failed: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        } else {
            Task {
                await loadAVAsset(from: url)
            }
        }
    }

    private func loadAVAsset(from url: URL) async {
        let asset = AVURLAsset(url: url)

        // Load asset properties first to check if it's playable
        do {
            let isPlayable = try await asset.load(.isPlayable)
            let tracks = try await asset.load(.tracks)

            guard isPlayable else {
                await MainActor.run {
                    if url.isFileURL {
                        self.errorMessage = "Format not supported: \(url.pathExtension.uppercased())\n\nAVFoundation cannot decode this file.\nSupported: MP4, MOV, M4V"
                    } else {
                        self.errorMessage = "Stream not playable: \(url.absoluteString)\n\nThe remote media cannot be decoded."
                    }
                    self.isLoading = false
                }
                return
            }

            guard !tracks.isEmpty else {
                await MainActor.run {
                    self.errorMessage = "No playable tracks found"
                    self.isLoading = false
                }
                return
            }

            // Asset is valid, create player
            await MainActor.run {
                let playerItem = AVPlayerItem(asset: asset)

                if self.player == nil {
                    self.player = AVPlayer(playerItem: playerItem)
                    self.setupTimeObserver()
                } else {
                    self.player?.replaceCurrentItem(with: playerItem)
                }

                self.player?.volume = self.volume

                // Observe playback status
                NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
                    .sink { [weak self] _ in
                        Task { @MainActor in
                            self?.isPlaying = false
                            self?.seek(to: 0)
                        }
                    }
                    .store(in: &self.cancellables)
            }

            // Load duration
            let duration = try await asset.load(.duration)
            await MainActor.run {
                self.duration = CMTimeGetSeconds(duration)
                self.isLoading = false

                // Check for saved position and resume
                if let url = self.currentMediaURL, url.isFileURL,
                   let savedPosition = PlaybackHistory.shared.getPosition(for: url) {
                    self.seek(to: savedPosition)
                }

                self.play()
            }
        } catch {
            await MainActor.run {
                if url.isFileURL {
                    self.errorMessage = "Failed to load media: \(error.localizedDescription)\n\nFile: \(url.lastPathComponent)"
                } else {
                    self.errorMessage = "Failed to load stream: \(error.localizedDescription)\n\nURL: \(url.absoluteString)"
                }
                self.isLoading = false
            }
        }
    }

    // MARK: - Playback Controls

    func play() {
        player?.rate = playbackRate
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false

        // Save position when pausing
        if let url = currentMediaURL, url.isFileURL {
            PlaybackHistory.shared.savePosition(for: url, position: currentTime, duration: duration)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seek(by seconds: Double) {
        let newTime = currentTime + seconds
        let clampedTime = max(0, min(newTime, duration))
        seek(to: clampedTime)
    }

    func adjustVolume(by delta: Float) {
        volume = max(0, min(1, volume + delta))
        player?.volume = volume
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        player?.volume = volume
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.25, min(2.0, rate))
        if isPlaying {
            player?.rate = playbackRate
        }
    }

    func setupPictureInPicture(with layer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

        pipDelegate = PipDelegate(controller: self)
        pipController = AVPictureInPictureController(playerLayer: layer)
        pipController?.delegate = pipDelegate
    }

    func togglePictureInPicture() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        $volume
            .sink { [weak self] newVolume in
                self?.player?.volume = newVolume
            }
            .store(in: &cancellables)
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = CMTimeGetSeconds(time)

                // Periodically save position (every 5 seconds)
                if Int(self.currentTime) % 5 == 0,
                   let url = self.currentMediaURL, url.isFileURL {
                    PlaybackHistory.shared.savePosition(for: url, position: self.currentTime, duration: self.duration)
                }
            }
        }
    }
}

// MARK: - Picture in Picture Delegate

private class PipDelegate: NSObject, AVPictureInPictureControllerDelegate {
    weak var controller: PlayerController?

    init(controller: PlayerController) {
        self.controller = controller
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            controller?.isPipActive = true
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            controller?.isPipActive = false
        }
    }
}
