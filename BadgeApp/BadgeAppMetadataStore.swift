//
//  BadgeAppMetadataStore.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

final class BadgeAppMetadataStore {
    private let folderMetadataXattr = "com.badgeapp.folderMetadata"
    private let badgeStateXattr = "com.badgeapp.badgeState"
    private let backupIDXattr = "com.badgeapp.backupID"

    func folderMetadata(at path: String, dataReader: (String, String) -> Data?) -> BadgeAppFolderMetadata? {
        guard let data = dataReader(folderMetadataXattr, path) else {
            return nil
        }

        return try? JSONDecoder().decode(BadgeAppFolderMetadata.self, from: data)
    }

    func badgeState(at path: String, dataReader: (String, String) -> Data?) -> BadgeAppBadgeState? {
        guard let data = dataReader(badgeStateXattr, path) else {
            return nil
        }

        return try? JSONDecoder().decode(BadgeAppBadgeState.self, from: data)
    }

    func backupID(at path: String, dataReader: (String, String) -> Data?) -> String? {
        guard let data = dataReader(backupIDXattr, path) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
    
    func writeBadgeState(
        at path: String,
        badgeSize: Double,
        badgeOffsetX: Double,
        badgeOffsetY: Double,
        dataWriter: (Data, String, String) -> Void
    ) {
        let state = BadgeAppBadgeState(
            version: 1,
            badgeSize: badgeSize,
            badgeOffsetX: badgeOffsetX,
            badgeOffsetY: badgeOffsetY
        )

        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        dataWriter(data, badgeStateXattr, path)
    }

    func writeBackupID(
        _ id: String,
        at path: String,
        dataWriter: (Data, String, String) -> Void
    ) {
        guard let data = id.data(using: .utf8) else {
            return
        }

        dataWriter(data, backupIDXattr, path)
    }

    func writeFolderMetadata(
        at path: String,
        colorName: String?,
        symbolName: String?,
        symbolText: String?,
        dataWriter: (Data, String, String) -> Void
    ) {
        guard colorName != nil || symbolName != nil || symbolText != nil,
              let data = try? JSONEncoder().encode(BadgeAppFolderMetadata(
                version: 1,
                colorName: colorName,
                symbolName: symbolName,
                symbolText: symbolText
              )) else {
            return
        }

        dataWriter(data, folderMetadataXattr, path)
    }
    
    func removeBadgeState(at path: String, remover: (String, String) -> Void) {
        remover(badgeStateXattr, path)
    }

    func removeBackupID(at path: String, remover: (String, String) -> Void) {
        remover(backupIDXattr, path)
    }

    func removeFolderMetadata(at path: String, remover: (String, String) -> Void) {
        remover(folderMetadataXattr, path)
    }
}
