//
//  BadgeBuiltInVisuals.swift
//  BadgeKit
//

import AppKit

public enum BadgeBuiltInVisuals {
    public static var pin: BadgeVisual? {
        let bundle = Bundle(for: BundleToken.self)

        guard let artwork = image(
            named: "Badge_Pin_Artwork",
            in: bundle
        ) else {
            print("BadgeKit: missing built-in pin artwork resource")
            return nil
        }

        let contactShadow = image(
            named: "Badge_Pin_ContactShadow",
            in: bundle
        )

        if contactShadow == nil {
            print("BadgeKit: missing built-in pin contact shadow resource")
        }

        return BadgeVisual(
            artwork: artwork,
            contactShadow: contactShadow,
            contactShadowOpacity: 1.0
        )
    }

    private static func image(named name: String, in bundle: Bundle) -> NSImage? {
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private final class BundleToken {}
