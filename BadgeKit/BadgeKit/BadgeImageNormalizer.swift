//
//  BadgeImageNormalizer.swift
//  BadgeKit
//
//  Created by David Vilches on 13/05/2026.
//

import Cocoa

public struct NormalizedBadgeImage {
    public let image: NSImage
    public let pngData: Data

    public init(image: NSImage, pngData: Data) {
        self.image = image
        self.pngData = pngData
    }
}

public final class BadgeImageNormalizer {
    private let pixelSize: Int

    public init(pixelSize: Int = 1024) {
        self.pixelSize = pixelSize
    }

    public func normalize(_ image: NSImage) -> NormalizedBadgeImage? {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelSize,
                pixelsHigh: pixelSize,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
              ) else {
            return nil
        }

        let canvasSize = NSSize(width: pixelSize, height: pixelSize)
        bitmap.size = canvasSize

        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.cgContext.clear(CGRect(origin: .zero, size: canvasSize))
        context.imageInterpolation = .high
        context.shouldAntialias = true

        let sourceSize = NSSize(width: source.width, height: source.height)
        let scale = min(
            canvasSize.width / sourceSize.width,
            canvasSize.height / sourceSize.height
        )

        let drawSize = NSSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )

        let drawRect = NSRect(
            x: (canvasSize.width - drawSize.width) / 2,
            y: (canvasSize.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )

        NSImage(cgImage: source, size: sourceSize).draw(
            in: drawRect,
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let renderedImage = NSImage(size: canvasSize)
        renderedImage.addRepresentation(bitmap)

        return NormalizedBadgeImage(
            image: renderedImage,
            pngData: pngData
        )
    }
}
