//
//  CustomBadgeStore.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Cocoa
import BadgeKit

final class CustomBadgeStore {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func badgesDirectory() -> URL? {
        fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("BadgeApp/Badges")
    }
    
    func loadBadges() -> [CustomBadgeRecord] {
        guard let badgesDir = badgesDirectory() else {
            return []
        }

        do {
            try fileManager.createDirectory(
                at: badgesDir,
                withIntermediateDirectories: true
            )

            let files = try fileManager.contentsOfDirectory(
                at: badgesDir,
                includingPropertiesForKeys: nil
            )

            return files.compactMap { file in
                guard let image = NSImage(contentsOfFile: file.path) else {
                    return nil
                }

                let label = file.deletingPathExtension().lastPathComponent
                let name = NSImage.Name(label)
                image.setName(name)

                return CustomBadgeRecord(
                    name: name,
                    label: label,
                    path: file.path
                )
            }
        } catch {
            print("Error loading custom badges: \(error)")
            return []
        }
    }
    
    func saveBadge(
        image: NSImage,
        name: String,
        normalizer: BadgeImageNormalizer
    ) -> CustomBadgeRecord? {
        guard let badgesDir = badgesDirectory() else {
            return nil
        }

        let fileURL = badgesDir.appendingPathComponent("\(name).png")

        guard let normalizedBadge = normalizer.normalize(image) else {
            return nil
        }

        do {
            try fileManager.createDirectory(
                at: badgesDir,
                withIntermediateDirectories: true
            )

            try normalizedBadge.pngData.write(to: fileURL)

            let customName = NSImage.Name(name)
            normalizedBadge.image.setName(customName)

            return CustomBadgeRecord(
                name: customName,
                label: name,
                path: fileURL.path
            )
        } catch {
            print("Error saving custom badge: \(error)")
            return nil
        }
    }
}
