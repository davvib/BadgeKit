//
//  BadgePreviewGeometryCoordinator.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

public final class BadgePreviewGeometryCoordinator {
    private let folderRenderer: FolderIconRenderer
    private let fileGeometryCalculator: BadgeFileGeometryCalculator

    public init(
        folderRenderer: FolderIconRenderer = FolderIconRenderer(),
        fileGeometryCalculator: BadgeFileGeometryCalculator = BadgeFileGeometryCalculator()
    ) {
        self.folderRenderer = folderRenderer
        self.fileGeometryCalculator = fileGeometryCalculator
    }
    
    public func geometry(
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
    
}

