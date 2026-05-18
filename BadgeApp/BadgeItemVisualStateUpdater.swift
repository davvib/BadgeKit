//
//  BadgeItemVisualStateUpdater.swift
//  BadgeApp
//
//  Created by David Vilches on 18/05/2026.
//

import Cocoa

final class BadgeItemVisualStateUpdater {
    func invalidatePreviewCache(for item: DroppedItem) {
        item.cachedPreviewIcon = nil
        item.cachedPreviewKey = nil
    }

    func applyPreviewVisibility(_ showsBadgePreview: Bool?, to item: DroppedItem) {
        guard let showsBadgePreview else {
            return
        }

        item.showsBadgePreview = showsBadgePreview
    }
    
    func showPreview(for item: DroppedItem) {
        item.showsBadgePreview = true
        invalidatePreviewCache(for: item)
    }
    
    func hidePreview(for item: DroppedItem) {
        item.showsBadgePreview = false
        invalidatePreviewCache(for: item)
    }
    
    func setPreviewVisibility(_ showsBadgePreview: Bool, for item: DroppedItem) {
        item.showsBadgePreview = showsBadgePreview
        invalidatePreviewCache(for: item)
    }
}
