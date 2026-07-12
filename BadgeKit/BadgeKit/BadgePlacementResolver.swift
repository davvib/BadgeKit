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

    private func origin(
        for position: BadgePosition,
        in anchorRect: CGRect,
        badgeSize: CGSize
    ) -> CGPoint {
        switch position {
        case .topLeading:
            return CGPoint(
                x: anchorRect.minX,
                y: anchorRect.maxY - badgeSize.height
            )

        case .topTrailing:
            return CGPoint(
                x: anchorRect.maxX - badgeSize.width,
                y: anchorRect.maxY - badgeSize.height
            )

        case .center:
            return CGPoint(
                x: anchorRect.midX - badgeSize.width / 2,
                y: anchorRect.midY - badgeSize.height / 2
            )

        case .bottomLeading:
            return CGPoint(
                x: anchorRect.minX,
                y: anchorRect.minY
            )

        case .bottomTrailing:
            return CGPoint(
                x: anchorRect.maxX - badgeSize.width,
                y: anchorRect.minY
            )
        }
    }

    private func offsetAdjustment(
        kind: BadgePlacementKind,
        position: BadgePosition
    ) -> CGPoint {
        let baseAdjustment: CGPoint

        switch kind {
        case .folder:
            baseAdjustment = folderBadgeOffsetAdjustment

        case .file:
            baseAdjustment = fileBadgeOffsetAdjustment
        }

        switch position {
        case .topLeading:
            return CGPoint(
                x: -baseAdjustment.x,
                y: -baseAdjustment.y
            )

        case .topTrailing:
            return CGPoint(
                x: baseAdjustment.x,
                y: -baseAdjustment.y
            )

        case .center:
            return .zero

        case .bottomLeading:
            return CGPoint(
                x: -baseAdjustment.x,
                y: baseAdjustment.y
            )

        case .bottomTrailing:
            return baseAdjustment
        }
    }

    func placement(
        from anchorRect: CGRect,
        badgeSize: CGSize,
        badgeOffset: CGPoint,
        position: BadgePosition = .bottomTrailing,
        visibleRectResolver: (CGRect) -> CGRect = { $0 }
    ) -> BadgePlacement {
        let badgeScale =
            min(anchorRect.width, anchorRect.height) /
            baseBadgeDivisor

        let size = CGSize(
            width: badgeSize.width * badgeScale,
            height: badgeSize.height * badgeScale
        )

        let baseOrigin = origin(
            for: position,
            in: anchorRect,
            badgeSize: size
        )

        let logicalRect = CGRect(
            x: baseOrigin.x + badgeOffset.x,
            y: baseOrigin.y + badgeOffset.y,
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
        position: BadgePosition = .bottomTrailing,
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

        let badgeScale =
            min(sizeAnchorRect.width, sizeAnchorRect.height) /
            baseBadgeDivisor

        let size = CGSize(
            width: badgeSize.width * badgeScale * kindScale,
            height: badgeSize.height * badgeScale * kindScale
        )

        let baseOrigin = origin(
            for: position,
            in: positionAnchorRect,
            badgeSize: size
        )

        let kindAdjustment = offsetAdjustment(
            kind: kind,
            position: position
        )

        let logicalRect = CGRect(
            x: baseOrigin.x
                + badgeOffset.x
                + kindAdjustment.x,
            y: baseOrigin.y
                + badgeOffset.y
                + kindAdjustment.y,
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
