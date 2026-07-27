//
//  BadgeComposition.swift
//  BadgeKit
//

import CoreGraphics

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
