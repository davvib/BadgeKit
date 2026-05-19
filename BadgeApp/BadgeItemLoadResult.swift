//
//  BadgeItemLoadResult.swift
//  BadgeApp
//
//  Created by David Vilches on 19/05/2026.
//

import AppKit

struct BadgeItemLoadResult {
    let isDirectory: Bool

    let colorName: String?
    let folderColor: NSColor?

    let symbolName: String?
    let symbolText: String?

    let badgeState: BadgeAppBadgeState?
    let badgeStatus: DroppedItemBadgeStatus

    let hasAppBadge: Bool
    let hasCustomIcon: Bool
    let hasVisualCustomization: Bool

    let baseIconForPreview: NSImage?
}
