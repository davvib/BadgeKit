//
//  BadgePreviewGeometryCoordinator.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgePreviewGeometryCoordinator {
    private let folderRenderer: FolderIconRenderer
    private let fileGeometryCalculator: BadgeFileGeometryCalculator

    init(filePreviewNormalizer: FilePreviewNormalizer = FilePreviewNormalizer()) {
        self.folderRenderer = FolderIconRenderer()
        self.fileGeometryCalculator = BadgeFileGeometryCalculator(
            filePreviewNormalizer: filePreviewNormalizer
        )
    }
    
    func geometry(
        isDirectory: Bool,
        folderColorName: String?,
        icon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        position: BadgePosition
    ) -> BadgeGeometry {
        let logicalRect: NSRect

        if isDirectory {
            logicalRect = folderRenderer.badgeRect(
                colorName: folderColorName,
                badgeSize: badgeSize,
                badgeOffset: badgeOffset
            )
        } else {
            logicalRect = fileGeometryCalculator.badgeRect(
                for: icon,
                badgeSize: badgeSize,
                badgeOffset: badgeOffset,
                position: position
            )
        }

        let visibleRect = isDirectory
            ? logicalRect
            : fileGeometryCalculator.visibleBadgeRect(
                for: badge,
                in: logicalRect
            )

        return BadgeGeometry(
            logicalRect: logicalRect,
            visibleRect: visibleRect
        )
    }

    func geometry(
        isDirectory: Bool,
        folderColorName: String?,
        icon: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        position: BadgePosition
    ) -> BadgeGeometry {
        let logicalRect: NSRect

        if isDirectory {
            logicalRect = folderRenderer.badgeRect(
                colorName: folderColorName,
                badgeSize: badgeSize,
                badgeOffset: badgeOffset
            )
        } else {
            logicalRect = fileGeometryCalculator.badgeRect(
                for: icon,
                badgeSize: badgeSize,
                badgeOffset: badgeOffset,
                position: position
            )
        }

        return BadgeGeometry(
            logicalRect: logicalRect,
            visibleRect: logicalRect
        )
    }
    
    func offset(
        isDirectory: Bool,
        folderColorName: String?,
        icon: NSImage,
        badgeSize: NSSize,
        position: BadgePosition,
        placingBadgeCenterAt center: NSPoint
    ) -> NSPoint {
        if isDirectory {
            return folderRenderer.badgeOffset(
                colorName: folderColorName,
                badgeSize: badgeSize,
                placingBadgeCenterAt: center
            )
        }

        return fileGeometryCalculator.badgeOffset(
            for: icon,
            badgeSize: badgeSize,
            position: position,
            placingBadgeCenterAt: center
        )
    }
    
    func logicalCenter(
        forVisibleCenter visibleCenter: NSPoint,
        isDirectory: Bool,
        icon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        position: BadgePosition
    ) -> NSPoint {
        guard !isDirectory else {
            return visibleCenter
        }

        let currentRect = fileGeometryCalculator.badgeRect(
            for: icon,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            position: position
        )

        return fileGeometryCalculator.logicalCenter(
            forVisibleCenter: visibleCenter,
            badge: badge,
            currentRect: currentRect
        )
    }
    
}
