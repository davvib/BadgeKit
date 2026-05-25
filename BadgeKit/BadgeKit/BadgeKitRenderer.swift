//
//  BadgeKit:BadgeKitRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 22/05/2026.
//

import AppKit

public final class BadgeKitRenderer {

    private let composer = BadgeIconComposer()
    private let cacheKeyBuilder = BadgePreviewCacheKeyBuilder()
    private let previewIconRenderer = BadgePreviewIconRenderer()
    private let folderPreviewRenderer = BadgeFolderPreviewRenderer()

    public init() {}

    public func renderPreview(
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> NSImage {

        composer.makeBadgedIcon(
            originalIcon: baseIcon,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset
        )
    }
    
    public func makePreviewCacheKey(
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration,
        folderColorName: String?,
        folderSymbolName: String?,
        folderSymbolText: String?
    ) -> String {
        cacheKeyBuilder.makeKey(
            icon: baseIcon,
            badge: badge,
            badgeSize: configuration.size.width,
            badgeOffset: configuration.offset,
            folderColorName: folderColorName,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText
        )
    }
    
    public func renderPreviewIcon(
        baseIcon: NSImage,
        folderColorName: String?,
        folderColor: NSColor?,
        folderSymbolName: String?,
        folderSymbolText: String?,
        badge: NSImage,
        configuration: BadgeConfiguration,
        fallbackRenderer: @escaping (NSImage, NSImage, NSSize) -> NSImage
    ) -> NSImage {
        previewIconRenderer.renderPreviewIcon(
            baseIcon: baseIcon,
            folderColorName: folderColorName,
            folderColor: folderColor,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset,
            fallbackRenderer: fallbackRenderer
        )
    }
    
    public func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        configuration: BadgeConfiguration
    ) -> NSImage? {
        folderPreviewRenderer.renderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset
        )
    }

    public func renderFolderPreview(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        configuration: BadgeConfiguration
    ) -> NSImage? {
        folderPreviewRenderer.renderPreview(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset
        )
    }
}
