//
//  BadgePreviewIconRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgePreviewIconRenderer {
    private let folderPreviewRenderer: BadgeFolderPreviewRenderer

    init(
        folderPreviewRenderer: BadgeFolderPreviewRenderer = BadgeFolderPreviewRenderer()
    ) {
        self.folderPreviewRenderer = folderPreviewRenderer
    }

    func renderPreviewIcon(
        baseIcon: NSImage,
        folderColorName: String?,
        folderColor: NSColor?,
        folderSymbolName: String?,
        folderSymbolText: String?,
        badge: NSImage,
        configuration: BadgeConfiguration,
        fallbackRenderer: (NSImage, NSImage, NSSize) -> NSImage
    ) -> NSImage {
        folderPreviewRenderer.renderPreview(
            colorName: folderColorName,
            fallbackColor: folderColor,
            symbolName: folderSymbolName,
            symbolText: folderSymbolText,
            badge: badge,
            configuration: configuration
        ) ?? fallbackRenderer(
            baseIcon,
            badge,
            configuration.size
        )
    }
}
