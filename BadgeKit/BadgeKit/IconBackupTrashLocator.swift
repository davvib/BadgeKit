//
//  IconBackupTrashLocator.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

public final class IconBackupTrashLocator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func containsItemNamed(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        for trashDirectory in trashSearchDirectories() {
            guard let enumerator = fileManager.enumerator(
                at: trashDirectory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let itemURL as URL in enumerator where itemURL.lastPathComponent == name {
                return true
            }
        }

        return false
    }

    private func trashSearchDirectories() -> [URL] {
        var directories = [
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        ]

        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        if let volumeURLs = try? fileManager.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            let uid = String(getuid())
            directories += volumeURLs.map {
                $0.appendingPathComponent(".Trashes").appendingPathComponent(uid)
            }
        }

        return directories
    }
}
