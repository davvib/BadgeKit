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

final class BadgePlacementResolver {
    private let canvasSize: CGFloat
    private let baseBadgeDivisor: CGFloat

    init(
        canvasSize: CGFloat = 1024,
        baseBadgeDivisor: CGFloat = 48
    ) {
        self.canvasSize = canvasSize
        self.baseBadgeDivisor = baseBadgeDivisor
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
}
