//
//  BadgeVisual.swift
//  BadgeKit
//

import AppKit

public struct BadgeVisual {
    public let artwork: NSImage
    public let contactShadow: NSImage?
    public let contactShadowOpacity: CGFloat

    public init(
        artwork: NSImage,
        contactShadow: NSImage? = nil,
        contactShadowOpacity: CGFloat = 0.35
    ) {
        self.artwork = artwork
        self.contactShadow = contactShadow
        self.contactShadowOpacity = min(max(contactShadowOpacity, 0), 1)
    }
}
