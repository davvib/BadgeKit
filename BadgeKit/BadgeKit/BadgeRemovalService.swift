//
//  BadgeRemovalService.swift
//  BadgeApp
//
//  Created by David Vilches on 18/05/2026.
//

import Cocoa

public enum BadgeRemovalResult {
    case restoredOriginal
    case restoredCustomVisualState
    case clearedFallbackIconState
    case unchanged
}

public final class BadgeRemovalService {
    private let finderIconApplier: FinderIconApplier

    public init(finderIconApplier: FinderIconApplier) {
        self.finderIconApplier = finderIconApplier
    }
    
    public func clearFallbackIconState(at path: String) {
        _ = finderIconApplier.clearIcon(at: path)
        finderIconApplier.notifyFileSystemChanged(at: path)
    }
    
    public func cleanAppliedBadgeMetadata(
        at path: String,
        folderMetadataRemover: (String) -> Void,
        badgeStateRemover: (String) -> Void,
        backupIDRemover: (String) -> Void
    ) {
        folderMetadataRemover(path)
        badgeStateRemover(path)
        backupIDRemover(path)
    }
    
    public func removeBadge(
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
            return .restoredCustomVisualState
        }

        if hasBadgeAppState {
            fallbackCleaner(path)
            return .clearedFallbackIconState
        }

        return .unchanged
    }
}
