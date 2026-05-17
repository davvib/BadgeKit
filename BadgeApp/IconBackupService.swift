//
//  IconBackupService.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class IconBackupService {
    private let backupStore: IconBackupStore
    private let retentionPolicy: IconBackupRetentionPolicy
    private let fileIdentityResolver: FileIdentityResolver
    private let finderInfoStore: FinderInfoStore

    init(
        backupStore: IconBackupStore,
        retentionPolicy: IconBackupRetentionPolicy,
        fileIdentityResolver: FileIdentityResolver,
        finderInfoStore: FinderInfoStore
    ) {
        self.backupStore = backupStore
        self.retentionPolicy = retentionPolicy
        self.fileIdentityResolver = fileIdentityResolver
        self.finderInfoStore = finderInfoStore
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
}
