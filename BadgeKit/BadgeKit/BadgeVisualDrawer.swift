//
//  BadgeVisualDrawer.swift
//  BadgeKit
//

import AppKit

final class BadgeVisualDrawer {
    private let badgeImageNormalizer: BadgeImageNormalizer

    init(badgeImageNormalizer: BadgeImageNormalizer = BadgeImageNormalizer()) {
        self.badgeImageNormalizer = badgeImageNormalizer
    }

    func draw(
        _ visual: BadgeVisual,
        in rect: NSRect,
        trimsArtworkWithoutShadow: Bool
    ) {
        guard visual.contactShadow != nil else {
            drawArtworkWithoutShadow(
                visual.artwork,
                in: rect,
                trimsArtwork: trimsArtworkWithoutShadow
            )
            return
        }

        guard let layers = badgeImageNormalizer.alignedBadgeLayers(visual) else {
            drawUnaligned(visual, in: rect)
            return
        }

        draw(layers, in: rect)
    }

    func draw(
        _ composition: BadgeComposition,
        in rect: NSRect,
        trimsArtworkWithoutShadow: Bool
    ) {
        for element in composition.elements {
            draw(
                element.visual,
                in: destinationRect(for: element.frame, in: rect),
                trimsArtworkWithoutShadow: trimsArtworkWithoutShadow
            )
        }
    }

    private func drawArtworkWithoutShadow(
        _ artwork: NSImage,
        in rect: NSRect,
        trimsArtwork: Bool
    ) {
        guard trimsArtwork,
              let trimmedArtwork = badgeImageNormalizer.trimmed(artwork) else {
            artwork.draw(
                in: rect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
            return
        }

        let drawRect = aspectFitRect(for: trimmedArtwork.size, in: rect)
        trimmedArtwork.draw(
            in: drawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    private func drawUnaligned(_ visual: BadgeVisual, in rect: NSRect) {
        if let contactShadow = visual.contactShadow,
           visual.contactShadowOpacity > 0 {
            contactShadow.draw(
                in: rect,
                from: .zero,
                operation: .sourceOver,
                fraction: visual.contactShadowOpacity
            )
        }

        visual.artwork.draw(
            in: rect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    private func draw(
        _ layers: BadgeImageNormalizer.AlignedBadgeLayers,
        in rect: NSRect
    ) {
        let artworkDrawRect = aspectFitRect(for: layers.artwork.size, in: rect)

        if let contactShadow = layers.contactShadow,
           layers.contactShadowOpacity > 0 {
            contactShadow.draw(
                in: fullCanvasDestination(
                    for: layers,
                    artworkDrawRect: artworkDrawRect
                ),
                from: .zero,
                operation: .sourceOver,
                fraction: layers.contactShadowOpacity
            )
        }

        layers.artwork.draw(
            in: artworkDrawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    private func destinationRect(for normalizedFrame: CGRect, in rect: NSRect) -> NSRect {
        NSRect(
            x: rect.minX + normalizedFrame.minX * rect.width,
            y: rect.minY + normalizedFrame.minY * rect.height,
            width: normalizedFrame.width * rect.width,
            height: normalizedFrame.height * rect.height
        )
    }

    private func fullCanvasDestination(
        for layers: BadgeImageNormalizer.AlignedBadgeLayers,
        artworkDrawRect: NSRect
    ) -> NSRect {
        let bounds = layers.artworkBoundsInOriginalCanvas
        let canvasSize = layers.originalCanvasSize
        guard bounds.width > 0, bounds.height > 0 else { return artworkDrawRect }

        let scale = min(
            artworkDrawRect.width / bounds.width,
            artworkDrawRect.height / bounds.height
        )
        let bottomOffset = canvasSize.height - bounds.maxY

        return NSRect(
            x: artworkDrawRect.minX - bounds.minX * scale,
            y: artworkDrawRect.minY - bottomOffset * scale,
            width: canvasSize.width * scale,
            height: canvasSize.height * scale
        )
    }

    private func aspectFitRect(for sourceSize: NSSize, in container: NSRect) -> NSRect {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return container }

        let scale = min(
            container.width / sourceSize.width,
            container.height / sourceSize.height
        )
        let size = NSSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )

        return NSRect(
            x: container.midX - size.width / 2,
            y: container.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
