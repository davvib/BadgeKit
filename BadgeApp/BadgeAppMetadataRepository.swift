//
//  BadgeAppMetadataRepository.swift
//  BadgeApp
//
//  Created by David Vilches on 18/05/2026.
//

import Foundation

final class BadgeAppMetadataRepository {
    private let metadataStore: BadgeAppMetadataStore
    private let xattrStore: XattrStore

    init(
        metadataStore: BadgeAppMetadataStore,
        xattrStore: XattrStore
    ) {
        self.metadataStore = metadataStore
        self.xattrStore = xattrStore
    }

    func backupID(at path: String) -> String? {
        metadataStore.backupID(at: path) { [weak self] name, path in
            self?.xattrStore.data(named: name, at: path)
        }
    }
    
    func folderMetadata(at path: String) -> BadgeAppFolderMetadata? {
        metadataStore.folderMetadata(at: path) { [weak self] name, path in
            self?.xattrStore.data(named: name, at: path)
        }
    }

    func badgeState(at path: String) -> BadgeAppBadgeState? {
        metadataStore.badgeState(at: path) { [weak self] name, path in
            self?.xattrStore.data(named: name, at: path)
        }
    }
    
    func writeBadgeState(
        at path: String,
        badgeSize: Double,
        badgeOffsetX: Double,
        badgeOffsetY: Double
    ) {
        metadataStore.writeBadgeState(
            at: path,
            badgeSize: badgeSize,
            badgeOffsetX: badgeOffsetX,
            badgeOffsetY: badgeOffsetY
        ) { [weak self] data, name, path in
            self?.xattrStore.setData(data, named: name, at: path)
        }
    }

    func writeBackupID(_ id: String, at path: String) {
        metadataStore.writeBackupID(id, at: path) { [weak self] data, name, path in
            self?.xattrStore.setData(data, named: name, at: path)
        }
    }
    
    func writeFolderMetadata(
        at path: String,
        colorName: String?,
        symbolName: String?,
        symbolText: String?
    ) {
        metadataStore.writeFolderMetadata(
            at: path,
            colorName: colorName,
            symbolName: symbolName,
            symbolText: symbolText
        ) { [weak self] data, name, path in
            self?.xattrStore.setData(data, named: name, at: path)
        }
    }
    
    func removeBadgeState(at path: String) {
        metadataStore.removeBadgeState(at: path) { [weak self] name, path in
            self?.xattrStore.remove(named: name, at: path)
        }
    }

    func removeBackupID(at path: String) {
        metadataStore.removeBackupID(at: path) { [weak self] name, path in
            self?.xattrStore.remove(named: name, at: path)
        }
    }

    func removeFolderMetadata(at path: String) {
        metadataStore.removeFolderMetadata(at: path) { [weak self] name, path in
            self?.xattrStore.remove(named: name, at: path)
        }
    }
}


