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
}
