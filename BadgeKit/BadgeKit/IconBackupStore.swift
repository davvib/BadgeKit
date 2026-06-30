//
//  IconBackupStore.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Foundation
import Cocoa

public struct StoredIconBackupRecord {
    public let record: IconBackupRecord
    public let recordURL: URL
}

public final class IconBackupStore {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func backupsDirectory() -> URL? {
        fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("BadgeApp/IconBackups")
    }

    public func recordsDirectory() -> URL? {
        backupsDirectory()?.appendingPathComponent("Records")
    }

    public func imagesDirectory() -> URL? {
        backupsDirectory()?.appendingPathComponent("Images")
    }

    public func recordURL(for id: String) -> URL? {
        recordsDirectory()?.appendingPathComponent(id).appendingPathExtension("json")
    }
    
    public func record(withID id: String) -> IconBackupRecord? {
        guard let recordURL = recordURL(for: id),
              let data = try? Data(contentsOf: recordURL) else {
            return nil
        }

        return try? JSONDecoder().decode(IconBackupRecord.self, from: data)
    }
    
    public func previewOrOriginalIcon(for record: IconBackupRecord) -> NSImage? {
        guard let imagesDir = imagesDirectory() else {
            return nil
        }

        if let previewIconFileName = record.previewIconFileName,
           let previewIcon = NSImage(contentsOf: imagesDir.appendingPathComponent(previewIconFileName)) {
            return previewIcon
        }

        guard record.hadCustomIcon,
              let iconFileName = record.iconFileName else {
            return nil
        }

        return NSImage(contentsOf: imagesDir.appendingPathComponent(iconFileName))
    }
    
    public func prepareStorageDirectories() throws -> (backupsDir: URL, recordsDir: URL, imagesDir: URL) {
        guard let backupsDir = backupsDirectory(),
              let recordsDir = recordsDirectory(),
              let imagesDir = imagesDirectory() else {
            throw CocoaError(.fileNoSuchFile)
        }

        try fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: recordsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        return (backupsDir, recordsDir, imagesDir)
    }

    public func writeRecord(_ record: IconBackupRecord) throws {
        guard let recordURL = recordURL(for: record.id) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try JSONEncoder().encode(record)
        try data.write(to: recordURL)
    }
    
    public func writeTIFFIcon(_ icon: NSImage, fileName: String) throws {
        guard let imagesDir = imagesDirectory(),
              let tiffData = icon.tiffRepresentation else {
            return
        }

        try tiffData.write(to: imagesDir.appendingPathComponent(fileName))
    }
    
    public func originalIcon(for record: IconBackupRecord) -> NSImage? {
        guard record.hadCustomIcon,
              let iconFileName = record.iconFileName,
              let imagesDir = imagesDirectory() else {
            return nil
        }

        return NSImage(contentsOf: imagesDir.appendingPathComponent(iconFileName))
    }
    
    public func storedRecords() -> [StoredIconBackupRecord] {
        guard let recordsDir = recordsDirectory(),
              let recordURLs = try? fileManager.contentsOfDirectory(
                at: recordsDir,
                includingPropertiesForKeys: nil
              ) else {
            return []
        }

        return recordURLs.compactMap { recordURL in
            guard recordURL.pathExtension == "json",
                  let data = try? Data(contentsOf: recordURL),
                  let record = try? JSONDecoder().decode(IconBackupRecord.self, from: data) else {
                return nil
            }

            return StoredIconBackupRecord(
                record: record,
                recordURL: recordURL
            )
        }
    }
    
    public func deleteBackupFiles(for record: IconBackupRecord) {
        if let recordURL = recordURL(for: record.id) {
            try? fileManager.removeItem(at: recordURL)
        }

        if let iconFileName = record.iconFileName,
           let imagesDir = imagesDirectory() {
            try? fileManager.removeItem(
                at: imagesDir.appendingPathComponent(iconFileName)
            )
        }

        if let previewIconFileName = record.previewIconFileName,
           let imagesDir = imagesDirectory() {
            try? fileManager.removeItem(
                at: imagesDir.appendingPathComponent(previewIconFileName)
            )
        }
    }
}


