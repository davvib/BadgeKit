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
    private let folderRenderer = FolderIconRenderer()
    private let defaultFolderColor = NSColor.systemBlue
    private let geometryCoordinator = BadgePreviewGeometryCoordinator()

    public init() {}

    public func renderPreview(
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderPreview(
            baseIcon: baseIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            configuration: configuration
        )
    }

    public func renderPreview(
        baseIcon: NSImage,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration
    ) -> NSImage {
        composer.makeBadgedIcon(
            originalIcon: baseIcon,
            badgeVisual: badgeVisual,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset,
            badgePosition: configuration.position
        )
    }

    public func renderSystemIcon(
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderSystemIcon(
            baseIcon: baseIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            configuration: configuration
        )
    }

    public func renderSystemIcon(
        baseIcon: NSImage,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration
    ) -> NSImage {
        composer.makeBadgedSystemIcon(
            originalIcon: baseIcon,
            badgeVisual: badgeVisual,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset,
            badgePosition: configuration.position,
            kind: .file
        )
    }

    public func renderFolderSystemIcon(
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderSystemIcon(
            baseIcon: baseIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            configuration: configuration
        )
    }

    public func renderFolderSystemIcon(
        baseIcon: NSImage,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration
    ) -> NSImage {
        composer.makeBadgedSystemIcon(
            originalIcon: baseIcon,
            badgeVisual: badgeVisual,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset,
            badgePosition: configuration.position,
            kind: .folder
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
        makePreviewCacheKey(
            baseIcon: baseIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            configuration: configuration,
            folderColorName: folderColorName,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText
        )
    }

    public func makePreviewCacheKey(
        baseIcon: NSImage,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration,
        folderColorName: String?,
        folderSymbolName: String?,
        folderSymbolText: String?
    ) -> String {
        cacheKeyBuilder.makeKey(
            icon: baseIcon,
            badgeVisual: badgeVisual,
            badgeSize: configuration.size.width,
            badgeOffset: configuration.offset,
            badgePosition: configuration.position,
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
        renderPreviewIcon(
            baseIcon: baseIcon,
            folderColorName: folderColorName,
            folderColor: folderColor,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText,
            badgeVisual: BadgeVisual(artwork: badge),
            configuration: configuration,
            fallbackRenderer: fallbackRenderer
        )
    }

    public func renderPreviewIcon(
        baseIcon: NSImage,
        folderColorName: String?,
        folderColor: NSColor?,
        folderSymbolName: String?,
        folderSymbolText: String?,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration,
        fallbackRenderer: @escaping (NSImage, NSImage, NSSize) -> NSImage
    ) -> NSImage {
        if badgeVisual.contactShadow == nil {
            return previewIconRenderer.renderPreviewIcon(
                baseIcon: baseIcon,
                folderColorName: folderColorName,
                folderColor: folderColor,
                folderSymbolName: folderSymbolName,
                folderSymbolText: folderSymbolText,
                badge: badgeVisual.artwork,
                configuration: configuration,
                fallbackRenderer: fallbackRenderer
            )
        }

        return folderRenderer.renderPreviewFolderIcon(
            colorName: folderColorName,
            fallbackColor: folderColor ?? defaultFolderColor,
            symbolName: folderSymbolName,
            symbolText: folderSymbolText,
            badgeVisual: badgeVisual,
            configuration: configuration
        )
    }

    public func renderPreviewIcon(
        baseIcon: NSImage,
        folderColorName: String?,
        folderColor: NSColor?,
        folderSymbolName: String?,
        folderSymbolText: String?,
        badgeVisual: BadgeVisual,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderPreviewIcon(
            baseIcon: baseIcon,
            folderColorName: folderColorName,
            folderColor: folderColor,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText,
            badgeVisual: badgeVisual,
            configuration: configuration,
            fallbackRenderer: { [weak self] baseIcon, _, _ in
                guard let self else { return baseIcon }
                return self.renderPreview(
                    baseIcon: baseIcon,
                    badgeVisual: badgeVisual,
                    configuration: configuration
                )
            }
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
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badge.map { BadgeVisual(artwork: $0) },
            configuration: configuration
        )
    }

    public func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        configuration: BadgeConfiguration
    ) -> NSImage? {
        let resolvedFallbackColor = fallbackColor ?? defaultFolderColor

        return folderRenderer.renderFolderIcon(
            colorName: colorName,
            fallbackColor: resolvedFallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badgeVisual,
            configuration: configuration
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
        renderFolderPreview(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badge.map { BadgeVisual(artwork: $0) },
            configuration: configuration
        )
    }

    public func renderFolderPreview(
        colorName: String?,
        fallbackColor: NSColor?,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        configuration: BadgeConfiguration
    ) -> NSImage? {
        let resolvedFallbackColor = fallbackColor ?? defaultFolderColor

        return folderRenderer.renderPreviewFolderIcon(
            colorName: colorName,
            fallbackColor: resolvedFallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badgeVisual,
            configuration: configuration
        )
    }

    public func badgeGeometry(
        isDirectory: Bool,
        folderColorName: String?,
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> BadgeGeometry {
        geometryCoordinator.geometry(
            isDirectory: isDirectory,
            folderColorName: folderColorName,
            icon: baseIcon,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset
        )
    }

    public func badgeOffset(
        isDirectory: Bool,
        folderColorName: String?,
        baseIcon: NSImage,
        configuration: BadgeConfiguration,
        placingBadgeCenterAt center: CGPoint
    ) -> CGPoint {
        geometryCoordinator.offset(
            isDirectory: isDirectory,
            folderColorName: folderColorName,
            icon: baseIcon,
            badgeSize: configuration.size,
            placingBadgeCenterAt: center
        )
    }

    public func logicalBadgeCenter(
        forVisibleCenter visibleCenter: CGPoint,
        isDirectory: Bool,
        baseIcon: NSImage,
        badge: NSImage,
        configuration: BadgeConfiguration
    ) -> CGPoint {
        geometryCoordinator.logicalCenter(
            forVisibleCenter: visibleCenter,
            isDirectory: isDirectory,
            icon: baseIcon,
            badge: badge,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset
        )
    }
}
