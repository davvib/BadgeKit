//
//  BadgeFolderPreviewRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgeFolderPreviewRenderer {
    private let folderRenderer: FolderIconRenderer

    init(folderRenderer: FolderIconRenderer = FolderIconRenderer()) {
        self.folderRenderer = folderRenderer
    }

    func renderIcon(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        badgeSize: NSSize,
        badgeOffset: NSPoint
    ) -> NSImage? {
        guard let fallbackColor else { return nil }

        return folderRenderer.renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        )
    }

    func renderPreview(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        badgeSize: NSSize,
        badgeOffset: NSPoint
    ) -> NSImage? {
        guard let fallbackColor else { return nil }

        return folderRenderer.renderPreviewFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        )
    }
}
