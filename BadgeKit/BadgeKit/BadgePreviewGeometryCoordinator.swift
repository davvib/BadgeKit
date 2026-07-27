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

    init() {
        self.folderRenderer = FolderIconRenderer()
        self.fileGeometryCalculator = BadgeFileGeometryCalculator()
    }
    
    func geometry(
        isDirectory: Bool,
        folderColorName: String?,
        icon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint
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
                badgeOffset: badgeOffset
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
        badgeOffset: NSPoint
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
                badgeOffset: badgeOffset
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
            placingBadgeCenterAt: center
        )
    }
    
    func logicalCenter(
        forVisibleCenter visibleCenter: NSPoint,
        isDirectory: Bool,
        icon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint
    ) -> NSPoint {
        guard !isDirectory else {
            return visibleCenter
        }

        let currentRect = fileGeometryCalculator.badgeRect(
            for: icon,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        )

        return fileGeometryCalculator.logicalCenter(
            forVisibleCenter: visibleCenter,
            badge: badge,
            currentRect: currentRect
        )
    }
    
}
