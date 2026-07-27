//
//  BadgeBuiltInVisuals.swift
//  BadgeKit
//

import AppKit

public enum BadgeBuiltInVisuals {
    public static var pin: BadgeVisual? {
        visual(
            artworkName: "Badge_Pin_Artwork",
            contactShadowName: "Badge_Pin_ContactShadow",
            missingArtworkMessage: "BadgeKit: missing built-in pin artwork resource",
            missingContactShadowMessage: "BadgeKit: missing built-in pin contact shadow resource",
            contactShadowOpacity: 1.0
        )
    }

    public static var tag: BadgeVisual? {
        visual(
            artworkName: "Badge_Tag_Artwork",
            contactShadowName: "Badge_Tag_ContactShadow",
            missingArtworkMessage: "BadgeKit: missing built-in tag artwork resource",
            missingContactShadowMessage: "BadgeKit: missing built-in tag contact shadow resource",
            contactShadowOpacity: 1.0
        )
    }

    private static func visual(
        artworkName: String,
        contactShadowName: String,
        missingArtworkMessage: String,
        missingContactShadowMessage: String,
        contactShadowOpacity: CGFloat
    ) -> BadgeVisual? {
        let bundle = Bundle(for: BundleToken.self)

        guard let artwork = image(
            named: artworkName,
            in: bundle
        ) else {
            print(missingArtworkMessage)
            return nil
        }

        let contactShadow = image(
            named: contactShadowName,
            in: bundle
        )

        if contactShadow == nil {
            print(missingContactShadowMessage)
        }

        return BadgeVisual(
            artwork: artwork,
            contactShadow: contactShadow,
            contactShadowOpacity: contactShadowOpacity
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
