//
//  FilePreviewNormalizer.swift
//  BadgeKit
//
//  Created by David Vilches on 08/07/2026.
//

//
//  FilePreviewNormalizer.swift
//  BadgeKit
//

import AppKit

final class FilePreviewNormalizer {
    private let canvasSize: CGFloat
    private let cornerRadiusRatio: CGFloat

    init(
        canvasSize: CGFloat = 1024,
        cornerRadiusRatio: CGFloat = 0.08
    ) {
        self.canvasSize = canvasSize
        self.cornerRadiusRatio = cornerRadiusRatio
    }

    func normalizedPreview(from image: NSImage) -> NSImage {
        let canvas = NSSize(width: canvasSize, height: canvasSize)
        let normalizedImage = NSImage(size: canvas)

        normalizedImage.lockFocus()

        let canvasRect = NSRect(origin: .zero, size: canvas)
        NSGraphicsContext.current?.cgContext.clear(canvasRect)

        let imageRect = aspectFitRect(
            for: image,
            in: canvasRect
        )

        let radius = min(imageRect.width, imageRect.height) * cornerRadiusRatio

        let clippingPath = NSBezierPath(
            roundedRect: imageRect,
            xRadius: radius,
            yRadius: radius
        )

        clippingPath.addClip()

        image.draw(
            in: imageRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )

        normalizedImage.unlockFocus()

        return normalizedImage
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
