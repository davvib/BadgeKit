//
//  BadgeApplyService.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class BadgeApplyService {
    private let finderIconApplier: FinderIconApplier
    private let finderInfoStore: FinderInfoStore
    private let visualCustomizationRestorer: FolderVisualCustomizationRestorer
    private let iconBackupService: IconBackupService

    init(
        finderIconApplier: FinderIconApplier,
        finderInfoStore: FinderInfoStore,
        visualCustomizationRestorer: FolderVisualCustomizationRestorer,
        iconBackupService: IconBackupService
    ) {
        self.finderIconApplier = finderIconApplier
        self.finderInfoStore = finderInfoStore
        self.visualCustomizationRestorer = visualCustomizationRestorer
        self.iconBackupService = iconBackupService
    }
    
    func writeBadgedIcon(
        _ icon: NSImage,
        to path: String,
        restoreOriginalOnFailure: Bool,
        metadataWriter: (String) -> Void,
        restoreOriginalIconState: (String) -> Bool
    ) -> Bool {
        let url = URL(fileURLWithPath: path)
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let didApply = finderIconApplier.applyIcon(icon, to: path)

        if didApply {
            finderInfoStore.forceCustomIconState(at: path)
            metadataWriter(path)
        }

        finderIconApplier.notifyFileAndParentChanged(at: path)

        if !didApply, restoreOriginalOnFailure {
            _ = restoreOriginalIconState(path)
        }

        return didApply
    }
    
    func applyBadgedIcon(
        _ icon: NSImage,
        to path: String,
        backupRecord: IconBackupRecord?,
        hasCustomFinderIcon: Bool,
        hasFolderVisualCustomization: Bool,
        writeBadgedIcon: (NSImage, Bool) -> Bool
    ) -> Bool {
        let needsClearBeforeApplying =
            hasCustomFinderIcon ||
            backupRecord?.hadCustomIcon == true

        let needsVisualCustomizationClear =
            hasFolderVisualCustomization ||
            backupRecord?.visualCustomizationXattrs?.isEmpty == false

        if needsClearBeforeApplying {
            _ = finderIconApplier.clearIcon(at: path)
            finderIconApplier.notifyFileSystemChanged(at: path)
        }

        if needsVisualCustomizationClear {
            visualCustomizationRestorer.removeVisualCustomizationXattrs(at: path)
            finderIconApplier.notifyFileSystemChanged(at: path)
        }

        return writeBadgedIcon(
            icon,
            needsClearBeforeApplying || needsVisualCustomizationClear
        )
    }
}
