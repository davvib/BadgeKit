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

    public func trimmed(_ image: NSImage) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bounds = alphaBounds(in: cgImage),
              let cropped = cgImage.cropping(to: bounds) else {
            return nil
        }

        return NSImage(
            cgImage: cropped,
            size: NSSize(width: bounds.width, height: bounds.height)
        )
    }

    private func alphaBounds(in image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

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

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

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

        guard maxX >= minX, maxY >= minY else { return nil }

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}
