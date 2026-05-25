//
//  BadgeIconComposer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

final class BadgeIconComposer {
    private let iconSizes: [Int]
    private let canvasPixelSize: CGFloat

    init(
        iconSizes: [Int] = [16, 32, 64, 128, 256, 512, 1024],
        canvasPixelSize: CGFloat = 1024
    ) {
        self.iconSizes = iconSizes
        self.canvasPixelSize = canvasPixelSize
    }

    func makeBadgedIcon(
        originalIcon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint
    ) -> NSImage {
        let newIcon = NSImage(size: NSSize(width: canvasPixelSize, height: canvasPixelSize))

        for iconSize in iconSizes {
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: iconSize,
                pixelsHigh: iconSize,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
                continue
            }

            let iconSize = CGFloat(iconSize)
            let canvasSize = NSSize(width: iconSize, height: iconSize)
            bitmap.size = canvasSize

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.cgContext.clear(CGRect(origin: .zero, size: canvasSize))
            context.imageInterpolation = .high
            context.shouldAntialias = true

            let iconRect = aspectFitRect(
                for: originalIcon,
                in: NSRect(origin: .zero, size: canvasSize)
            )

            originalIcon.draw(
                in: iconRect,
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )

            let scale = min(iconRect.width, iconRect.height) / 48.0
            let canvasScale = min(canvasSize.width, canvasSize.height) / canvasPixelSize
            let scaledBadgeSize = NSSize(
                width: badgeSize.width * scale,
                height: badgeSize.height * scale
            )

            let badgeRect = NSRect(
                x: iconRect.maxX - scaledBadgeSize.width + badgeOffset.x * canvasScale,
                y: iconRect.minY + badgeOffset.y * canvasScale,
                width: scaledBadgeSize.width,
                height: scaledBadgeSize.height
            )

            badge.draw(
                in: badgeRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    private func aspectFitRect(for image: NSImage, in bounds: NSRect) -> NSRect {
        let imageSize = image.size

        guard imageSize.width > 0,
              imageSize.height > 0 else {
            return bounds
        }

        let scale = min(
            bounds.width / imageSize.width,
            bounds.height / imageSize.height
        )

        let size = NSSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        return NSRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
