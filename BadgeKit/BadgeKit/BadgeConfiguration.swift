//
//  BadgeKit:BadgeConfiguration.swift
//  BadgeKit
//
//  Created by David Vilches on 22/05/2026.
//

import CoreGraphics

public struct BadgeConfiguration {
    public var size: CGSize
    public var offset: CGPoint

    public init(
        size: CGSize,
        offset: CGPoint = .zero
    ) {
        self.size = size
        self.offset = offset
    }
}
