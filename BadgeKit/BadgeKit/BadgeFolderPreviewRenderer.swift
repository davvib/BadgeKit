//
//  BadgeFolderPreviewRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgeFolderPreviewRenderer {
    private let folderRenderer: FolderIconRenderer
    private let defaultFolderColor = NSColor.systemBlue

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
        let resolvedFallbackColor = fallbackColor ?? defaultFolderColor

        return folderRenderer.renderFolderIcon(
            colorName: colorName,
            fallbackColor: resolvedFallbackColor,
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
        let resolvedFallbackColor = fallbackColor ?? defaultFolderColor

        return folderRenderer.renderPreviewFolderIcon(
            colorName: colorName,
            fallbackColor: resolvedFallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        )
    }
}
