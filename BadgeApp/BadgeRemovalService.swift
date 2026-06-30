//
//  BadgeRemovalService.swift
//  BadgeApp
//
//  Created by David Vilches on 18/05/2026.
//

import Cocoa
import BadgeKit

enum BadgeRemovalResult {
    case restoredOriginal
    case restoredBadgeAppVisualState
    case clearedBadgeAppFallback
    case unchanged
}

final class BadgeRemovalService {
    private let finderIconApplier: FinderIconApplier

    init(finderIconApplier: FinderIconApplier) {
        self.finderIconApplier = finderIconApplier
    }
    
    func clearBadgeAppFallbackState(at path: String) {
        _ = finderIconApplier.clearIcon(at: path)
        finderIconApplier.notifyFileSystemChanged(at: path)
    }
    
    func hasBadgeAppState(
        at path: String,
        folderMetadataProvider: (String) -> BadgeAppFolderMetadata?,
        badgeStateProvider: (String) -> BadgeAppBadgeState?,
        backupIDProvider: (String) -> String?
    ) -> Bool {
        badgeStateProvider(path) != nil ||
        folderMetadataProvider(path) != nil ||
        backupIDProvider(path) != nil
    }
    
    func cleanBadgeAppMetadata(
        at path: String,
        folderMetadataRemover: (String) -> Void,
        badgeStateRemover: (String) -> Void,
        backupIDRemover: (String) -> Void
    ) {
        folderMetadataRemover(path)
        badgeStateRemover(path)
        backupIDRemover(path)
    }
    
    func removeBadge(
        at path: String,
        hasBadgeAppState: Bool,
        restoreOriginalIconState: (String) -> Bool,
        restoreBadgeAppFolderVisualState: (String) -> Bool,
        fallbackCleaner: (String) -> Void
    ) -> BadgeRemovalResult {
        if restoreOriginalIconState(path) {
            return .restoredOriginal
        }

        if restoreBadgeAppFolderVisualState(path) {
            return .restoredBadgeAppVisualState
        }

        if hasBadgeAppState {
            fallbackCleaner(path)
            return .clearedBadgeAppFallback
        }

        return .unchanged
    }
}
