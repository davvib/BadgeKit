//
//  BadgeBuiltInCompositions.swift
//  BadgeKit
//

import CoreGraphics

public enum BadgeBuiltInCompositions {
    public static var pinnedTag: BadgeComposition? {
        guard let tag = BadgeBuiltInVisuals.tag,
              let pin = BadgeBuiltInVisuals.pin else {
            return nil
        }

        let tagRect = CGRect(
            x: 0,
            y: 0,
            width: 1,
            height: 1
        )

        let pinRect = CGRect(
            x: 0.02,
            y: 0.85,
            width: 0.65,
            height: 0.65
        )

        return BadgeComposition(elements: [
            BadgeCompositionElement(
                visual: tag,
                frame: tagRect
            ),
            BadgeCompositionElement(
                visual: pin,
                frame: pinRect
            )
        ])
    }
}
