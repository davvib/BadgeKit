//
//  IconBackupRetentionPolicy.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

public final class IconBackupRetentionPolicy {
    private let fileManager: FileManager
    private let trashLocator: IconBackupTrashLocator

    public init(
        fileManager: FileManager = .default,
        trashLocator: IconBackupTrashLocator = IconBackupTrashLocator()
    ) {
        self.fileManager = fileManager
        self.trashLocator = trashLocator
    }

    public func shouldKeep(
        record: IconBackupRecord,
        resolvedURL: URL?
    ) -> Bool {
        if let resolvedURL {
            return fileExistsOrIsInTrash(at: resolvedURL)
        }

        if fileManager.fileExists(atPath: record.originalPath) {
            return true
        }

        return trashLocator.containsItemNamed(
            (record.originalPath as NSString).lastPathComponent
        )
    }

    private func fileExistsOrIsInTrash(at url: URL) -> Bool {
        if fileManager.fileExists(atPath: url.path) {
            return true
        }

        return url.standardizedFileURL.pathComponents.contains(".Trash") ||
            url.standardizedFileURL.pathComponents.contains(".Trashes")
    }
}
