//
//  BadgePreviewIconRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

public final class BadgePreviewIconRenderer {
    private let folderPreviewRenderer: BadgeFolderPreviewRenderer

    public init(folderPreviewRenderer: BadgeFolderPreviewRenderer = BadgeFolderPreviewRenderer()) {
        self.folderPreviewRenderer = folderPreviewRenderer
    }

    public func renderPreviewIcon(
        baseIcon: NSImage,
        folderColorName: String?,
        folderColor: NSColor?,
        folderSymbolName: String?,
        folderSymbolText: String?,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        fallbackRenderer: (NSImage, NSImage, NSSize) -> NSImage
    ) -> NSImage {
        folderPreviewRenderer.renderPreview(
            colorName: folderColorName,
            fallbackColor: folderColor,
            symbolName: folderSymbolName,
            symbolText: folderSymbolText,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        ) ?? fallbackRenderer(baseIcon, badge, badgeSize)
    }
}
