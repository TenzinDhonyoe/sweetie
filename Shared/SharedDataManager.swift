import Foundation
import UIKit
import WidgetKit

struct SharedTapData: Codable, Sendable {
    let emoji: String
    let senderName: String
    let timestamp: Date
}

struct SharedPhotoData: Codable, Sendable {
    let senderName: String
    let caption: String?
    let timestamp: Date
}

enum ActivityKind: String, Codable, Sendable {
    case tap
    case photo
    case note
}

struct SharedActivityItem: Codable, Sendable {
    let kind: ActivityKind
    let emoji: String?
    let senderName: String
    let caption: String?
    let timestamp: Date
}

final class SharedDataManager: Sendable {
    static let shared = SharedDataManager()

    private let suiteName = "group.com.sweetie.together"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        )
    }

    // MARK: - Keys

    private enum Key {
        static let reunionDate = "widget_reunionDate"
        static let lastTap = "widget_lastTap"
        static let latestPhoto = "widget_latestPhoto"
        static let partnerName = "widget_partnerName"
        static let recentActivity = "widget_recentActivity"
    }

    // MARK: - Write (main app)

    func saveReunionDate(_ date: Date?) {
        if let date {
            sharedDefaults?.set(date.timeIntervalSince1970, forKey: Key.reunionDate)
        } else {
            sharedDefaults?.removeObject(forKey: Key.reunionDate)
        }
    }

    func savePartnerName(_ name: String) {
        sharedDefaults?.set(name, forKey: Key.partnerName)
    }

    func saveLastTap(emoji: String, senderName: String) {
        let data = SharedTapData(emoji: emoji, senderName: senderName, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(data) {
            sharedDefaults?.set(encoded, forKey: Key.lastTap)
        }
    }

    func appendActivity(_ item: SharedActivityItem) {
        var items = loadRecentActivity()
        items.insert(item, at: 0)
        if items.count > 5 { items = Array(items.prefix(5)) }
        if let encoded = try? JSONEncoder().encode(items) {
            sharedDefaults?.set(encoded, forKey: Key.recentActivity)
        }
    }

    func saveLatestPhoto(imageData: Data, senderName: String, caption: String?) {
        // Downscale image for widget
        if let image = UIImage(data: imageData),
           let resized = downsample(image, maxWidth: 400),
           let jpeg = resized.jpegData(compressionQuality: 0.7),
           let containerURL = sharedContainerURL {
            let fileURL = containerURL.appendingPathComponent("latest_photo.jpg")
            try? jpeg.write(to: fileURL)
        }

        let metadata = SharedPhotoData(senderName: senderName, caption: caption, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(metadata) {
            sharedDefaults?.set(encoded, forKey: Key.latestPhoto)
        }
    }

    // MARK: - Read (widget)

    func loadReunionDate() -> Date? {
        guard let interval = sharedDefaults?.object(forKey: Key.reunionDate) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    func loadPartnerName() -> String {
        sharedDefaults?.string(forKey: Key.partnerName) ?? "Your love"
    }

    func loadLastTap() -> SharedTapData? {
        guard let data = sharedDefaults?.data(forKey: Key.lastTap) else { return nil }
        return try? JSONDecoder().decode(SharedTapData.self, from: data)
    }

    func loadLatestPhoto() -> SharedPhotoData? {
        guard let data = sharedDefaults?.data(forKey: Key.latestPhoto) else { return nil }
        return try? JSONDecoder().decode(SharedPhotoData.self, from: data)
    }

    func loadRecentActivity() -> [SharedActivityItem] {
        guard let data = sharedDefaults?.data(forKey: Key.recentActivity) else { return [] }
        return (try? JSONDecoder().decode([SharedActivityItem].self, from: data)) ?? []
    }

    func loadLatestPhotoImage() -> UIImage? {
        guard let containerURL = sharedContainerURL else { return nil }
        let fileURL = containerURL.appendingPathComponent("latest_photo.jpg")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Reload

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private func downsample(_ image: UIImage, maxWidth: CGFloat) -> UIImage? {
        let scale = maxWidth / image.size.width
        guard scale < 1 else { return image }
        let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
