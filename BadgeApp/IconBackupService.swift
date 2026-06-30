//
//  IconBackupService.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa
import BadgeKit

final class IconBackupService {
    private let backupStore: IconBackupStore
    private let retentionPolicy: IconBackupRetentionPolicy
    private let fileIdentityResolver: FileIdentityResolver
    private let finderInfoStore: FinderInfoStore
    private let finderIconApplier: FinderIconApplier
    private let visualCustomizationRestorer: FolderVisualCustomizationRestorer

    init(
        backupStore: IconBackupStore,
        retentionPolicy: IconBackupRetentionPolicy,
        fileIdentityResolver: FileIdentityResolver,
        finderInfoStore: FinderInfoStore,
        finderIconApplier: FinderIconApplier,
        visualCustomizationRestorer: FolderVisualCustomizationRestorer
    ) {
        self.backupStore = backupStore
        self.retentionPolicy = retentionPolicy
        self.fileIdentityResolver = fileIdentityResolver
        self.finderInfoStore = finderInfoStore
        self.finderIconApplier = finderIconApplier
        self.visualCustomizationRestorer = visualCustomizationRestorer
    }
    
    func shouldKeepStoredBackup(_ record: IconBackupRecord) -> Bool {
        let resolvedURL = fileIdentityResolver.resolvedBookmark(
            from: record.bookmarkData,
            allowingStale: true
        )?.url

        return retentionPolicy.shouldKeep(
            record: record,
            resolvedURL: resolvedURL
        )
    }
    
    func record(withID id: String) -> IconBackupRecord? {
        backupStore.record(withID: id)
    }
    
    func record(_ record: IconBackupRecord, belongsTo path: String) -> Bool {
        let targetURL = URL(fileURLWithPath: path).standardizedFileURL

        if let originalResourceIdentifier = record.originalResourceIdentifier,
           let targetIdentifier = fileIdentityResolver.resourceIdentifierString(for: targetURL) {
            return originalResourceIdentifier == targetIdentifier
        }

        return record.originalPath == path
    }
    
    func record(
        for path: String,
        backupIDProvider: (String) -> String?
    ) -> IconBackupRecord? {
        guard let backupID = backupIDProvider(path),
              let record = record(withID: backupID),
              self.record(record, belongsTo: path) else {
            return nil
        }

        return record
    }
    
    func cleanupStoredBackups() {
        for storedRecord in backupStore.storedRecords() {
            if shouldKeepStoredBackup(storedRecord.record) {
                continue
            }

            backupStore.deleteBackupFiles(for: storedRecord.record)
        }
    }
    
    func saveOriginalIconState(
        path: String,
        visualCustomizationXattrs: [String: Data],
        hasCustomVisualState: Bool,
        workspaceIcon: NSImage,
        backupIDWriter: (String, String) -> Void
    ) {
        do {
            _ = try backupStore.prepareStorageDirectories()
        } catch {
            print("Error preparing icon backup storage: \(error)")
            return
        }

        let url = URL(fileURLWithPath: path)
        let shouldBackupIconImage =
            hasCustomVisualState ||
            !visualCustomizationXattrs.isEmpty

        let finderInfoData = finderInfoStore.data(at: path)
        let id = UUID().uuidString
        let iconFileName = shouldBackupIconImage ? "\(id).tiff" : nil
        let previewIconFileName = "\(id)-preview.tiff"

        do {
            try backupStore.writeTIFFIcon(
                workspaceIcon,
                fileName: previewIconFileName
            )

            if let iconFileName {
                try backupStore.writeTIFFIcon(
                    workspaceIcon,
                    fileName: iconFileName
                )
            }

            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let record = IconBackupRecord(
                id: id,
                originalPath: path,
                bookmarkData: bookmarkData,
                createdAt: Date(),
                originalResourceIdentifier: fileIdentityResolver.resourceIdentifierString(for: url),
                hadCustomIcon: shouldBackupIconImage,
                iconFileName: iconFileName,
                previewIconFileName: previewIconFileName,
                visualCustomizationXattrs: visualCustomizationXattrs.isEmpty ? nil : visualCustomizationXattrs,
                finderInfoData: finderInfoData
            )

            try backupStore.writeRecord(record)
            backupIDWriter(id, path)
        } catch {
            print("Error backing up original icon state: \(error)")
        }
    }
    
    func restoreOriginalIconStateIfAvailable(
        for path: String,
        backupIDProvider: (String) -> String?,
        metadataCleaner: (String) -> Void
    ) -> Bool {
        guard let record = record(for: path, backupIDProvider: backupIDProvider) else {
            return false
        }

        let didRestore: Bool

        if let originalIcon = backupStore.originalIcon(for: record) {
            didRestore = finderIconApplier.applyIcon(originalIcon, to: path)
        } else {
            didRestore = finderIconApplier.clearIcon(at: path)
        }

        if didRestore {
            visualCustomizationRestorer.restoreVisualCustomizationXattrs(
                record.visualCustomizationXattrs,
                to: path
            )

            finderInfoStore.restore(record.finderInfoData, to: path)
            metadataCleaner(path)
            backupStore.deleteBackupFiles(for: record)
            finderIconApplier.notifyFileSystemChanged(at: path)
        }

        return didRestore
    }
}
