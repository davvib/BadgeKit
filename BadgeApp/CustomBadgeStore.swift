//
//  CustomBadgeStore.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Cocoa

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
}
