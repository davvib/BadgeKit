//
//  BadgeKit:BadgeKitRenderer.swift
//  BadgeKit
//
//  Created by David Vilches on 22/05/2026.
//

import AppKit

public final class BadgeKitRenderer {

    private let composer = BadgeIconComposer()

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
}
