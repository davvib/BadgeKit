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
    private let badgeVisualDrawer: BadgeVisualDrawer

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
        self.badgeVisualDrawer = BadgeVisualDrawer(badgeImageNormalizer: badgeImageNormalizer)
    }

    func makeBadgedIcon(
        originalIcon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition
    ) -> NSImage {
        makeBadgedIcon(
            originalIcon: originalIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            badgePosition: badgePosition
        )
    }

    func makeBadgedIcon(
        originalIcon: NSImage,
        badgeVisual: BadgeVisual,
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

            drawBadgeVisual(badgeVisual, in: badgeRect)

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    func makeBadgedIcon(
        originalIcon: NSImage,
        badgeComposition: BadgeComposition,
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

        let logicalPlacement = placementResolver.placement(
            kind: .file,
            positionAnchorRect: normalizedPreview.contentRect,
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

            normalizedOriginalIcon.draw(
                in: scaled(imageDrawRect, scale: scale),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )

            badgeVisualDrawer.draw(
                badgeComposition,
                in: scaled(logicalPlacement.logicalRect, scale: scale),
                trimsArtworkWithoutShadow: false
            )

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    func makeBadgeProxy(
        badgeVisual: BadgeVisual,
        trimsArtworkWithoutShadow: Bool
    ) -> BadgeProxy {
        makeBadgeProxy(
            frameRelativeToLogicalRect: CGRect(x: 0, y: 0, width: 1, height: 1)
        ) { rect in
            badgeVisualDrawer.draw(
                badgeVisual,
                in: rect,
                trimsArtworkWithoutShadow: trimsArtworkWithoutShadow
            )
        }
    }

    func makeBadgeProxy(
        badgeComposition: BadgeComposition,
        trimsArtworkWithoutShadow: Bool
    ) -> BadgeProxy {
        let compositionBounds = bounds(for: badgeComposition)

        return makeBadgeProxy(
            frameRelativeToLogicalRect: compositionBounds
        ) { rect in
            for element in badgeComposition.elements {
                badgeVisualDrawer.draw(
                    element.visual,
                    in: destinationRect(
                        for: element.frame,
                        in: rect,
                        relativeTo: compositionBounds
                    ),
                    trimsArtworkWithoutShadow: trimsArtworkWithoutShadow
                )
            }
        }
    }

    func makeBadgedSystemIcon(
        originalIcon: NSImage,
        badge: NSImage,
        badgeSize: NSSize,
        badgeOffset: NSPoint,
        badgePosition: BadgePosition,
        kind: BadgePlacementKind
    ) -> NSImage {
        makeBadgedSystemIcon(
            originalIcon: originalIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            badgeSize: badgeSize,
            badgeOffset: badgeOffset,
            badgePosition: badgePosition,
            kind: kind
        )
    }

    func makeBadgedSystemIcon(
        originalIcon: NSImage,
        badgeVisual: BadgeVisual,
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

        let badgeToDraw = badgeVisual.contactShadow == nil
            ? trimmedSystemBadgeVisual(badgeVisual)
            : badgeVisual

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

            drawBadgeVisual(
                badgeToDraw,
                in: scaled(logicalPlacement.logicalRect, scale: scale)
            )

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    func makeBadgedSystemIcon(
        originalIcon: NSImage,
        badgeComposition: BadgeComposition,
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

            badgeVisualDrawer.draw(
                badgeComposition,
                in: scaled(logicalPlacement.logicalRect, scale: scale),
                trimsArtworkWithoutShadow: true
            )

            NSGraphicsContext.restoreGraphicsState()
            newIcon.addRepresentation(bitmap)
        }

        return newIcon
    }

    private func trimmedSystemBadgeVisual(_ badgeVisual: BadgeVisual) -> BadgeVisual {
        guard badgeVisual.contactShadow != nil else {
            return BadgeVisual(
                artwork: badgeImageNormalizer.trimmed(badgeVisual.artwork) ?? badgeVisual.artwork
            )
        }

        return badgeImageNormalizer.alignedTrimmed(badgeVisual) ?? badgeVisual
    }

    private func drawBadgeVisual(_ badgeVisual: BadgeVisual, in rect: NSRect) {
        badgeVisualDrawer.draw(
            badgeVisual,
            in: rect,
            trimsArtworkWithoutShadow: false
        )
    }

    private func makeBadgeProxy(
        frameRelativeToLogicalRect: CGRect,
        drawBadge: (NSRect) -> Void
    ) -> BadgeProxy {
        let imageSize = proxyImageSize(for: frameRelativeToLogicalRect)
        let image = NSImage(size: imageSize)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageSize.width.rounded(.up)),
            pixelsHigh: Int(imageSize.height.rounded(.up)),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return BadgeProxy(
                image: image,
                frameRelativeToLogicalRect: frameRelativeToLogicalRect
            )
        }

        let canvasRect = NSRect(
            x: 0,
            y: 0,
            width: imageSize.width,
            height: imageSize.height
        )
        bitmap.size = canvasRect.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.cgContext.clear(canvasRect)
        context.imageInterpolation = .high
        context.shouldAntialias = true

        drawBadge(canvasRect)

        NSGraphicsContext.restoreGraphicsState()
        image.addRepresentation(bitmap)

        return BadgeProxy(
            image: image,
            frameRelativeToLogicalRect: frameRelativeToLogicalRect
        )
    }

    private func bounds(for composition: BadgeComposition) -> CGRect {
        guard let first = composition.elements.first?.frame else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        return composition.elements
            .dropFirst()
            .map(\.frame)
            .reduce(first) { partialResult, frame in
                partialResult.union(frame)
            }
    }

    private func destinationRect(
        for elementFrame: CGRect,
        in bounds: CGRect,
        relativeTo compositionBounds: CGRect
    ) -> CGRect {
        guard compositionBounds.width > 0,
              compositionBounds.height > 0 else {
            return bounds
        }

        return CGRect(
            x: bounds.minX + (elementFrame.minX - compositionBounds.minX) / compositionBounds.width * bounds.width,
            y: bounds.minY + (elementFrame.minY - compositionBounds.minY) / compositionBounds.height * bounds.height,
            width: elementFrame.width / compositionBounds.width * bounds.width,
            height: elementFrame.height / compositionBounds.height * bounds.height
        )
    }

    private func proxyImageSize(for relativeFrame: CGRect) -> NSSize {
        guard relativeFrame.width > 0,
              relativeFrame.height > 0 else {
            return NSSize(width: canvasPixelSize, height: canvasPixelSize)
        }

        if relativeFrame.width >= relativeFrame.height {
            return NSSize(
                width: canvasPixelSize,
                height: canvasPixelSize * relativeFrame.height / relativeFrame.width
            )
        }

        return NSSize(
            width: canvasPixelSize * relativeFrame.width / relativeFrame.height,
            height: canvasPixelSize
        )
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

}
