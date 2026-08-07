//
//  BadgeComposition.swift
//  BadgeKit
//

import AppKit

public struct BadgeProxy {
    public let image: NSImage
    public let frameRelativeToLogicalRect: CGRect

    public init(image: NSImage, frameRelativeToLogicalRect: CGRect) {
        self.image = image
        self.frameRelativeToLogicalRect = frameRelativeToLogicalRect
    }
}

public struct BadgeCompositionElement {
    public let visual: BadgeVisual
    public let frame: CGRect

    public init(visual: BadgeVisual, frame: CGRect) {
        self.visual = visual
        self.frame = frame
    }
}

public struct BadgeComposition {
    public let elements: [BadgeCompositionElement]

    public init(elements: [BadgeCompositionElement]) {
        self.elements = elements
    }
}
