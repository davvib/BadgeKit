//
//  PreviewCacheInvalidator.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

final class PreviewCacheInvalidator {
    func invalidate(items: [DroppedItem]) {
        for item in items {
            item.cachedPreviewIcon = nil
            item.cachedPreviewKey = nil
        }
    }
}
