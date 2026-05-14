//
//  IconBackupStore.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Foundation

final class IconBackupStore {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func backupsDirectory() -> URL? {
        fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("BadgeApp/IconBackups")
    }

    func recordsDirectory() -> URL? {
        backupsDirectory()?.appendingPathComponent("Records")
    }

    func imagesDirectory() -> URL? {
        backupsDirectory()?.appendingPathComponent("Images")
    }

    func recordURL(for id: String) -> URL? {
        recordsDirectory()?.appendingPathComponent(id).appendingPathExtension("json")
    }
    
    func record(withID id: String) -> IconBackupRecord? {
        guard let recordURL = recordURL(for: id),
              let data = try? Data(contentsOf: recordURL) else {
            return nil
        }

        return try? JSONDecoder().decode(IconBackupRecord.self, from: data)
    }
}
