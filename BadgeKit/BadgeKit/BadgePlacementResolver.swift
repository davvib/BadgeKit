//
//  BadgePlacementResolver.swift
//  BadgeKit
//
//  Created by David Vilches on 07/07/2026.
//

//
//  BadgePlacementResolver.swift
//  BadgeKit
//

import CoreGraphics

enum BadgePlacementKind {
    case folder
    case file
}

final class BadgePlacementResolver {
    private let canvasSize: CGFloat
    private let baseBadgeDivisor: CGFloat
    private let folderBadgeScale: CGFloat
    private let fileBadgeScale: CGFloat
    private let folderBadgeOffsetAdjustment: CGPoint
    private let fileBadgeOffsetAdjustment: CGPoint
    private let folderBadgeReferenceDimension: CGFloat

    init(
        canvasSize: CGFloat = 1024,
        baseBadgeDivisor: CGFloat = 48,
        folderBadgeScale: CGFloat = 1.0,
        fileBadgeScale: CGFloat = 0.75,
        folderBadgeOffsetAdjustment: CGPoint = CGPoint(x: -40, y: 100),
        fileBadgeOffsetAdjustment: CGPoint = .zero,
        folderBadgeReferenceDimension: CGFloat = 704
    ) {
        self.canvasSize = canvasSize
        self.baseBadgeDivisor = baseBadgeDivisor
        self.folderBadgeScale = folderBadgeScale
        self.fileBadgeScale = fileBadgeScale
        self.folderBadgeOffsetAdjustment = folderBadgeOffsetAdjustment
        self.fileBadgeOffsetAdjustment = fileBadgeOffsetAdjustment
        self.folderBadgeReferenceDimension = folderBadgeReferenceDimension
    }

    func systemIconAnchorRect(
        kind: BadgePlacementKind,
        canvasRect: CGRect
    ) -> CGRect {
        switch kind {
        case .folder:
            let scale = min(
                canvasRect.width / canvasSize,
                canvasRect.height / canvasSize
            )

            return CGRect(
                x: canvasRect.minX + 32 * scale,
                y: canvasRect.minY + 42 * scale,
                width: 984 * scale,
                height: 704 * scale
            )

        case .file:
            return canvasRect
        }
    }

    func placement(
        from anchorRect: CGRect,
        badgeSize: CGSize,
        badgeOffset: CGPoint,
        visibleRectResolver: (CGRect) -> CGRect = { $0 }
    ) -> BadgePlacement {
        let badgeScale = min(anchorRect.width, anchorRect.height) / baseBadgeDivisor

        let size = CGSize(
            width: badgeSize.width * badgeScale,
            height: badgeSize.height * badgeScale
        )

        let logicalRect = CGRect(
            x: anchorRect.maxX - size.width + badgeOffset.x,
            y: anchorRect.minY + badgeOffset.y,
            width: size.width,
            height: size.height
        )

        return BadgePlacement(
            canvasSize: canvasSize,
            anchorRect: anchorRect,
            logicalRect: logicalRect,
            visibleRect: visibleRectResolver(logicalRect)
        )
    }

    func placement(
        kind: BadgePlacementKind,
        positionAnchorRect: CGRect,
        sizeAnchorRect: CGRect,
        badgeSize: CGSize,
        badgeOffset: CGPoint,
        visibleRectResolver: (CGRect) -> CGRect = { $0 }
    ) -> BadgePlacement {
        let kindScale: CGFloat = {
            switch kind {
            case .folder:
                return folderBadgeScale
            case .file:
                return fileBadgeScale
            }
        }()

        let kindOffsetAdjustment: CGPoint = {
            switch kind {
            case .folder:
                return folderBadgeOffsetAdjustment
            case .file:
                return fileBadgeOffsetAdjustment
            }
        }()

        let badgeScale = min(sizeAnchorRect.width, sizeAnchorRect.height) / baseBadgeDivisor

        let size = CGSize(
            width: badgeSize.width * badgeScale * kindScale,
            height: badgeSize.height * badgeScale * kindScale
        )

        let logicalRect = CGRect(
            x: positionAnchorRect.maxX - size.width + badgeOffset.x + kindOffsetAdjustment.x,
            y: positionAnchorRect.minY + badgeOffset.y + kindOffsetAdjustment.y,
            width: size.width,
            height: size.height
        )

        return BadgePlacement(
            canvasSize: canvasSize,
            anchorRect: positionAnchorRect,
            logicalRect: logicalRect,
            visibleRect: visibleRectResolver(logicalRect)
        )
    }
}
