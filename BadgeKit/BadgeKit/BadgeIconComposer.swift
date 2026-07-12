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
    private let placementResolver: BadgePlacementResolver
    private let filePreviewNormalizer: FilePreviewNormalizer
    private let badgeImageNormalizer: BadgeImageNormalizer

    init(
        iconSizes: [Int] = [16, 32, 64, 128, 256, 512, 1024],
        canvasPixelSize: CGFloat = 1024,
        placementResolver: BadgePlacementResolver = BadgePlacementResolver(),
        filePreviewNormalizer: FilePreviewNormalizer = FilePreviewNormalizer(),
        badgeImageNormalizer: BadgeImageNormalizer = BadgeImageNormalizer()
    ) {
        self.iconSizes = iconSizes
        self.canvasPixelSize = canvasPixelSize
        self.placementResolver = placementResolver
        self.filePreviewNormalizer = filePreviewNormalizer
        self.badgeImageNormalizer = badgeImageNormalizer
    }

    func makeBadgedIcon(
        originalIcon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition
    ) -> NSImage {
        let normalizedPreview = filePreviewNormalizer.normalizedPreview(from: originalIcon)
        let normalizedOriginalIcon = normalizedPreview.image
        let newIcon = NSImage(size: NSSize(width: canvasPixelSize, height: canvasPixelSize))

        let logicalCanvasSize = NSSize(
            width: canvasPixelSize,
            height: canvasPixelSize
        )

        let imageDrawRect = aspectFitRect(
            for: normalizedOriginalIcon,
            in: NSRect(origin: .zero, size: logicalCanvasSize)
        )

        let badgeAnchorRect = normalizedPreview.contentRect

        let logicalPlacement = placementResolver.placement(
            kind: .file,
            positionAnchorRect: badgeAnchorRect,
            sizeAnchorRect: NSRect(origin: .zero, size: logicalCanvasSize),
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            position: badgePosition
        )

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

            let scale = iconSize / canvasPixelSize

            let iconRect = scaled(
                imageDrawRect,
                scale: scale
            )

            normalizedOriginalIcon.draw(
                in: iconRect,
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )

            let badgeRect = scaled(
                logicalPlacement.logicalRect,
                scale: scale
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

    func makeBadgedSystemIcon(
        originalIcon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition,
        kind: BadgePlacementKind
    ) -> NSImage {
        let newIcon = NSImage(
            size: NSSize(
                width: canvasPixelSize,
                height: canvasPixelSize
            )
        )

        let logicalCanvasSize = NSSize(
            width: canvasPixelSize,
            height: canvasPixelSize
        )

        let imageDrawRect = NSRect(
            origin: .zero,
            size: logicalCanvasSize
        )

        let badgeAnchorRect = placementResolver.systemIconAnchorRect(
            kind: kind,
            canvasRect: imageDrawRect
        )

        let logicalPlacement = placementResolver.placement(
            kind: kind,
            positionAnchorRect: badgeAnchorRect,
            sizeAnchorRect: badgeAnchorRect,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            position: badgePosition
        )

        let badgeToDraw = badgeImageNormalizer.trimmed(badge) ?? badge

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
            ),
            let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
                continue
            }

            let representationSize = CGFloat(iconSize)
            let canvasSize = NSSize(
                width: representationSize,
                height: representationSize
            )

            bitmap.size = canvasSize

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context

            context.cgContext.clear(
                CGRect(origin: .zero, size: canvasSize)
            )
            context.imageInterpolation = .high
            context.shouldAntialias = true

            let scale = representationSize / canvasPixelSize

            originalIcon.draw(
                in: scaled(imageDrawRect, scale: scale),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )

            badgeToDraw.draw(
                in: scaled(logicalPlacement.logicalRect, scale: scale),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    private func scaled(_ rect: NSRect, scale: CGFloat) -> NSRect {
        NSRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
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

    private func scaleRect(_ rect: NSRect, by scale: CGFloat) -> NSRect {
        let newSize = NSSize(
            width: rect.width * scale,
            height: rect.height * scale
        )

        return NSRect(
            x: rect.midX - newSize.width / 2,
            y: rect.midY - newSize.height / 2,
            width: newSize.width,
            height: newSize.height
        )
    }
}
