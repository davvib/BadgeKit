//
//  BadgePreviewCacheKeyBuilder.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgePreviewCacheKeyBuilder {
    public init() {}

    public func makeKey(
        icon: NSImage,
        badge: NSImage,
        badgeSize: CGFloat,
        badgeOffset: NSPoint,
        folderColorName: String?,
        folderSymbolName: String?,
        folderSymbolText: String?
    ) -> String {
        [
            "\(ObjectIdentifier(icon))",
            "\(ObjectIdentifier(badge))",
            "\(badgeSize)",
            "\(badgeOffset.x)",
            "\(badgeOffset.y)",
            folderColorName ?? "",
            folderSymbolName ?? "",
            folderSymbolText ?? ""
        ].joined(separator: "|")
    }
}
