import Foundation
import AVFoundation

class MediaConverter {
    static let shared = MediaConverter()

    private let tempDirectory: URL = {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("OpenMPlayer", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }()

    func needsConversion(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mkv", "avi", "webm", "flv", "wmv"].contains(ext)
    }

    func convert(url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        guard needsConversion(url: url) else {
            return url
        }

        // Check if FFmpeg is installed
        guard isFFmpegInstalled() else {
            throw ConversionError.ffmpegNotInstalled
        }

        let outputURL = tempDirectory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".mp4")

        // Remove existing temp file
        try? FileManager.default.removeItem(at: outputURL)

        // FFmpeg command: fast conversion with copy when possible
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        process.arguments = [
            "-i", url.path,
            "-c:v", "copy",  // Copy video stream if compatible
            "-c:a", "aac",   // Convert audio to AAC
            "-movflags", "+faststart",  // Optimize for streaming
            "-y",  // Overwrite output
            outputURL.path
        ]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()

        // Monitor progress (simplified - just wait for completion)
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ConversionError.conversionFailed
        }

        return outputURL
    }

    func cleanupTempFiles() {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func isFFmpegInstalled() -> Bool {
        let paths = [
            "/opt/homebrew/bin/ffmpeg",  // Apple Silicon
            "/usr/local/bin/ffmpeg"      // Intel
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    enum ConversionError: LocalizedError {
        case ffmpegNotInstalled
        case conversionFailed

        var errorDescription: String? {
            switch self {
            case .ffmpegNotInstalled:
                return "FFmpeg not installed. Install via: brew install ffmpeg"
            case .conversionFailed:
                return "Failed to convert video file"
            }
        }
    }
}
