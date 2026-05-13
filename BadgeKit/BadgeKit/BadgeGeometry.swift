//
//  BadgeGeometry.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

public struct BadgeGeometry {
    public let logicalRect: NSRect
    public let visibleRect: NSRect

    public init(logicalRect: NSRect, visibleRect: NSRect) {
        self.logicalRect = logicalRect
        self.visibleRect = visibleRect
    }
}
