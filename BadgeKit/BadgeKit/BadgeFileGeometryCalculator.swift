//
//  BadgeFileGeometryCalculator.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgeFileGeometryCalculator {
    private let canvasSize: CGFloat
    
    private struct AlphaBoundsCacheKey: Hashable {
        let imageID: ObjectIdentifier
        let pixelWidth: Int
        let pixelHeight: Int
    }

    private var alphaBoundsCache: [AlphaBoundsCacheKey: CGRect] = [:]
    
    func logicalCenter(
        forVisibleCenter visibleCenter: NSPoint,
        badge: NSImage,
        currentRect: NSRect
    ) -> NSPoint {
        let visibleRect = visibleBadgeRect(
            for: badge,
            in: currentRect
        )

        return NSPoint(
            x: visibleCenter.x - (visibleRect.midX - currentRect.midX),
            y: visibleCenter.y - (visibleRect.midY - currentRect.midY)
        )
    }

    init(canvasSize: CGFloat = 1024) {
        self.canvasSize = canvasSize
    }

    func badgeRect(
        for icon: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint
    ) -> NSRect {
        let canvasRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
        let iconRect = aspectFitRect(for: icon, in: canvasRect)
        let scale = min(iconRect.width, iconRect.height) / 48.0
        let scaledBadgeSize = NSSize(
            width: badgeSize.width * scale,
            height: badgeSize.height * scale
        )

        return NSRect(
            x: iconRect.maxX - scaledBadgeSize.width + badgeOffset.x,
            y: iconRect.minY + badgeOffset.y,
            width: scaledBadgeSize.width,
            height: scaledBadgeSize.height
        )
    }

    func badgeOffset(
        for icon: NSImage,
        badgeSize: NSSize,
        placingBadgeCenterAt center: NSPoint
    ) -> NSPoint {
        let canvasRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
        let iconRect = aspectFitRect(for: icon, in: canvasRect)
        let scale = min(iconRect.width, iconRect.height) / 48.0
        let scaledBadgeSize = NSSize(
            width: badgeSize.width * scale,
            height: badgeSize.height * scale
        )

        return NSPoint(
            x: center.x - (iconRect.maxX - scaledBadgeSize.width / 2),
            y: center.y - (iconRect.minY + scaledBadgeSize.height / 2)
        )
    }

    func visibleBadgeRect(for badge: NSImage, in rect: NSRect) -> NSRect {
        guard let cgImage = badge.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            return rect
        }

        let cacheKey = AlphaBoundsCacheKey(
            imageID: ObjectIdentifier(badge),
            pixelWidth: cgImage.width,
            pixelHeight: cgImage.height
        )

        let bounds: CGRect?

        if let cachedBounds = alphaBoundsCache[cacheKey] {
            bounds = cachedBounds
        } else {
            let calculatedBounds = alphaBounds(in: cgImage)
            if let calculatedBounds {
                alphaBoundsCache[cacheKey] = calculatedBounds
            }
            bounds = calculatedBounds
        }

        guard let bounds else {
            return rect
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        guard imageWidth > 0, imageHeight > 0 else {
            return rect
        }

        return NSRect(
            x: rect.minX + CGFloat(bounds.minX) / imageWidth * rect.width,
            y: rect.minY + (imageHeight - CGFloat(bounds.maxY)) / imageHeight * rect.height,
            width: CGFloat(bounds.width) / imageWidth * rect.width,
            height: CGFloat(bounds.height) / imageHeight * rect.height
        )
    }

    private func aspectFitRect(for image: NSImage, in bounds: NSRect) -> NSRect {
        guard image.size.width > 0,
              image.size.height > 0 else {
            return bounds
        }

        let scale = min(
            bounds.width / image.size.width,
            bounds.height / image.size.height
        )

        let size = NSSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        return NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func alphaBounds(in image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * 4
        )

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * width + x) * 4 + 3]

                if alpha > 5 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard maxX >= minX,
              maxY >= minY else {
            return nil
        }

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}
