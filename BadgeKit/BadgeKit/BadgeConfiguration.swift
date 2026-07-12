//
//  BadgeKit:BadgeConfiguration.swift
//  BadgeKit
//
//  Created by David Vilches on 22/05/2026.
//

import CoreGraphics

public struct BadgeConfiguration {
    public var size: CGSize
    public var position: BadgePosition
    public var offset: CGPoint

    public init(
        size: CGSize,
        position: BadgePosition = .bottomTrailing,
        offset: CGPoint = .zero
    ) {
        self.size = size
        self.position = position
        self.offset = offset
    }
}
