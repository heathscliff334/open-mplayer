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

    // MARK: - Media Loading

    func loadMedia(from url: URL) {
        isLoading = true
        errorMessage = nil
        currentMediaURL = url

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
                    let convertedURL = try await MediaConverter.shared.convert(url: url) { progress in
                        // Update progress if needed
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
        let asset = AVAsset(url: url)

        // Load asset properties first to check if it's playable
        do {
            let isPlayable = try await asset.load(.isPlayable)
            let tracks = try await asset.load(.tracks)

            guard isPlayable else {
                await MainActor.run {
                    self.errorMessage = "Format not supported: \(url.pathExtension.uppercased())\n\nAVFoundation cannot decode this file.\nSupported: MP4, MOV, M4V"
                    self.isLoading = false
                }
                return
            }

            guard !tracks.isEmpty else {
                await MainActor.run {
                    self.errorMessage = "No playable tracks found in file"
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
                self.play()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load media: \(error.localizedDescription)\n\nFile: \(url.lastPathComponent)"
                self.isLoading = false
            }
        }
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
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
    }
}
