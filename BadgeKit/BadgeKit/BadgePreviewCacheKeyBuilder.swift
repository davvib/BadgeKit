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

    public func makeKey(
        icon: NSImage,
        badgeComposition: BadgeComposition,
        badgeSize: CGFloat,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition,
        folderColorName: String?,
        folderSymbolName: String?,
        folderSymbolText: String?
    ) -> String {
        let compositionKey = badgeComposition.elements.map { element in
            [
                visualKey(element.visual),
                "\(element.frame.minX)",
                "\(element.frame.minY)",
                "\(element.frame.width)",
                "\(element.frame.height)"
            ].joined(separator: ",")
        }.joined(separator: ";")

        return [
            "\(ObjectIdentifier(icon))",
            "composition",
            compositionKey,
            "\(badgeSize)",
            "\(badgeOffset.x)",
            "\(badgeOffset.y)",
            badgePosition.rawValue,
            folderColorName ?? "",
            folderSymbolName ?? "",
            folderSymbolText ?? ""
        ].joined(separator: "|")
    }

    private func visualKey(_ badgeVisual: BadgeVisual) -> String {
        let shadowKey = badgeVisual.contactShadow.map {
            "\(ObjectIdentifier($0))|\(String(format: "%.6f", Double(badgeVisual.contactShadowOpacity)))"
        } ?? ""

        return [
            "\(ObjectIdentifier(badgeVisual.artwork))",
            shadowKey
        ].joined(separator: ":")
    }
}
