import Foundation

class PlaybackHistory {
    static let shared = PlaybackHistory()

    private let defaults = UserDefaults.standard
    private let historyKey = "playbackHistory"
    private let maxHistoryAge: TimeInterval = 30 * 24 * 60 * 60 // 30 days

    struct Entry: Codable {
        let fileHash: String
        let filePath: String
        let position: Double
        let duration: Double
        let lastPlayed: Date
    }

    private init() {
        cleanupOldEntries()
    }

    func savePosition(for url: URL, position: Double, duration: Double) {
        guard position > 0, duration > 0 else { return }

        // Don't save if at start or end
        let progress = position / duration
        guard progress > 0.05 && progress < 0.95 else { return }

        let fileHash = generateHash(for: url)
        let entry = Entry(
            fileHash: fileHash,
            filePath: url.path,
            position: position,
            duration: duration,
            lastPlayed: Date()
        )

        var history = loadHistory()
        history[fileHash] = entry
        saveHistory(history)
    }

    func getPosition(for url: URL) -> Double? {
        let fileHash = generateHash(for: url)
        let history = loadHistory()
        return history[fileHash]?.position
    }

    func clearHistory() {
        defaults.removeObject(forKey: historyKey)
    }

    private func generateHash(for url: URL) -> String {
        // Use path + file size for uniqueness
        let path = url.path
        let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
        return "\(path.hashValue)-\(size)"
    }

    private func loadHistory() -> [String: Entry] {
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([String: Entry].self, from: data) else {
            return [:]
        }
        return history
    }

    private func saveHistory(_ history: [String: Entry]) {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }

    private func cleanupOldEntries() {
        var history = loadHistory()
        let cutoffDate = Date().addingTimeInterval(-maxHistoryAge)

        history = history.filter { $0.value.lastPlayed > cutoffDate }

        // Also remove entries for files that no longer exist
        history = history.filter { entry in
            FileManager.default.fileExists(atPath: entry.value.filePath)
        }

        saveHistory(history)
    }
}
