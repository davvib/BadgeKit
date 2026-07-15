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
        makeKey(
            icon: icon,
            badgeVisual: BadgeVisual(artwork: badge),
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            badgePosition: .bottomTrailing,
            folderColorName: folderColorName,
            folderSymbolName: folderSymbolName,
            folderSymbolText: folderSymbolText
        )
    }

    public func makeKey(
        icon: NSImage,
        badgeVisual: BadgeVisual,
        badgeSize: CGFloat,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition,
        folderColorName: String?,
        folderSymbolName: String?,
        folderSymbolText: String?
    ) -> String {
        let shadowKey = badgeVisual.contactShadow.map {
            "\(ObjectIdentifier($0))|\(String(format: "%.6f", Double(badgeVisual.contactShadowOpacity)))"
        } ?? ""

        return [
            "\(ObjectIdentifier(icon))",
            "\(ObjectIdentifier(badgeVisual.artwork))",
            shadowKey,
            "\(badgeSize)",
            "\(badgeOffset.x)",
            "\(badgeOffset.y)",
            badgePosition.rawValue,
            folderColorName ?? "",
            folderSymbolName ?? "",
            folderSymbolText ?? ""
        ].joined(separator: "|")
    }
}
