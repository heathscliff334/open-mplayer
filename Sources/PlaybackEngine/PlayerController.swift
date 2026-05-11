import AVFoundation
import Combine
import SwiftUI

@MainActor
class PlayerController: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0
    @Published var currentMediaURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }

    // MARK: - Media Loading

    func loadMedia(from url: URL) {
        isLoading = true
        errorMessage = nil
        currentMediaURL = url

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            setupTimeObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        player?.volume = volume

        // Load duration
        Task {
            do {
                let duration = try await asset.load(.duration)
                self.duration = CMTimeGetSeconds(duration)
                self.isLoading = false
                self.play()
            } catch {
                self.errorMessage = "Failed to load media: \(error.localizedDescription)"
                self.isLoading = false
            }
        }

        // Observe playback status
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                self?.isPlaying = false
                self?.seek(to: 0)
            }
            .store(in: &cancellables)
    }

    // MARK: - Playback Controls

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
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
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }
}
