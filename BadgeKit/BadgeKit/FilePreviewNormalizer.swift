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

struct NormalizedFilePreview {
    let image: NSImage
    let contentRect: NSRect
}

final class FilePreviewNormalizer {
    private let canvasSize: CGFloat
    private let cornerRadiusRatio: CGFloat
    private let contentScale: CGFloat

    init(
        canvasSize: CGFloat = 1024,
        cornerRadiusRatio: CGFloat = 0.08,
        contentScale: CGFloat = 0.90
    ) {
        self.canvasSize = canvasSize
        self.cornerRadiusRatio = cornerRadiusRatio
        self.contentScale = contentScale
    }
    func normalizedPreview(from image: NSImage) -> NormalizedFilePreview {
        let canvas = NSSize(width: canvasSize, height: canvasSize)
        let normalizedImage = NSImage(size: canvas)

        normalizedImage.lockFocus()

        let canvasRect = NSRect(origin: .zero, size: canvas)
        NSGraphicsContext.current?.cgContext.clear(canvasRect)

        let imageRect = aspectFitRect(
            for: image,
            in: canvasRect
        )
        
        let scaledImageRect = scaleRect(
            imageRect,
            by: contentScale
        )

        let radius = min(scaledImageRect.width, scaledImageRect.height) * cornerRadiusRatio
        
        let clippingPath = NSBezierPath(
            roundedRect: scaledImageRect,
            xRadius: radius,
            yRadius: radius
        )

        clippingPath.addClip()

        image.draw(
            in: scaledImageRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )

        normalizedImage.unlockFocus()

        return NormalizedFilePreview(
            image: normalizedImage,
            contentRect: scaledImageRect
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
