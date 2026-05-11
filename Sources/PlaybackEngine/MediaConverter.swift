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

        // Check if already converted
        if FileManager.default.fileExists(atPath: outputURL.path) {
            return outputURL
        }

        // FFmpeg command: ultra-fast conversion with stream copy
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        process.arguments = [
            "-i", url.path,
            "-c", "copy",  // Copy all streams without re-encoding
            "-movflags", "+faststart",
            "-y",
            outputURL.path
        ]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            // If copy failed, try with re-encoding (slower but more compatible)
            return try await convertWithReencoding(url: url, outputURL: outputURL)
        }

        return outputURL
    }

    private func convertWithReencoding(url: URL, outputURL: URL) async throws -> URL {
        try? FileManager.default.removeItem(at: outputURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        process.arguments = [
            "-i", url.path,
            "-c:v", "libx264",  // Re-encode video
            "-preset", "ultrafast",  // Fastest encoding
            "-crf", "23",
            "-c:a", "aac",
            "-movflags", "+faststart",
            "-y",
            outputURL.path
        ]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
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
