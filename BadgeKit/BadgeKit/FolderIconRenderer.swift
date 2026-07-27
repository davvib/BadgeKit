import Cocoa

final class FolderIconRenderer {

    init(
        badgeImageNormalizer: BadgeImageNormalizer = BadgeImageNormalizer()
    ) {
        self.badgeVisualDrawer = BadgeVisualDrawer(badgeImageNormalizer: badgeImageNormalizer)
    }

    private struct FolderAsset {
        let directoryName: String
        let filePrefix: String
    }

    private let iconSizes = [16, 32, 64, 128, 256, 512, 1024]
    private let backRect = NSRect(x: 36, y: 252, width: 952, height: 580)
    private let tabRect = NSRect(x: 64, y: 718, width: 330, height: 136)
    private let frontRect = NSRect(x: 36, y: 136, width: 952, height: 624)
    private let symbolRect = NSRect(x: 308, y: 286, width: 408, height: 300)
    private let assetFrontRect = NSRect(x: 32, y: 42, width: 984, height: 704)
    private let assetSymbolRect = NSRect(x: 214.50, y: 236.00, width: 597.50, height: 421.50)
    private let placementResolver = BadgePlacementResolver()
    private let badgeVisualDrawer: BadgeVisualDrawer

    private var folderAssetImageCache: [String: NSImage] = [:]

    func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badge.map { BadgeVisual(artwork: $0) },
            configuration: configuration
        )
    }

    func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badgeVisual,
            badgeComposition: nil,
            configuration: configuration,
            sizes: iconSizes
        )
    }

    func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeComposition: BadgeComposition?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: nil,
            badgeComposition: badgeComposition,
            configuration: configuration,
            sizes: iconSizes
        )
    }

    func renderPreviewFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderPreviewFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badge.map { BadgeVisual(artwork: $0) },
            configuration: configuration
        )
    }

    func renderPreviewFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badgeVisual,
            badgeComposition: nil,
            configuration: configuration,
            sizes: [512]
        )
    }

    func renderPreviewFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeComposition: BadgeComposition?,
        configuration: BadgeConfiguration
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: nil,
            badgeComposition: badgeComposition,
            configuration: configuration,
            sizes: [512]
        )
    }

    func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badge: NSImage?,
        configuration: BadgeConfiguration,
        sizes: [Int]
    ) -> NSImage {
        renderFolderIcon(
            colorName: colorName,
            fallbackColor: fallbackColor,
            symbolName: symbolName,
            symbolText: symbolText,
            badgeVisual: badge.map { BadgeVisual(artwork: $0) },
            badgeComposition: nil,
            configuration: configuration,
            sizes: sizes
        )
    }

    func renderFolderIcon(
        colorName: String?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        badgeComposition: BadgeComposition? = nil,
        configuration: BadgeConfiguration,
        sizes: [Int]
    ) -> NSImage {
        let folderAsset = asset(for: colorName)
        let image = NSImage(size: NSSize(width: 1024, height: 1024))

        for size in sizes {
            guard let representation = renderRepresentation(
                size: size,
                folderAsset: folderAsset,
                fallbackColor: fallbackColor,
                symbolName: symbolName,
                symbolText: symbolText,
                badgeVisual: badgeVisual,
                badgeComposition: badgeComposition,
                configuration: configuration
            ) else {
                continue
            }

            image.addRepresentation(representation)
        }

        return image
    }

    func badgeRect(colorName: String?, badgeSize: NSSize, badgeOffset: NSPoint) -> NSRect {
        let anchorRect = asset(for: colorName) == nil ? frontRect : assetFrontRect

        return placementResolver.placement(
            kind: .folder,
            positionAnchorRect: anchorRect,
            sizeAnchorRect: anchorRect,
            badgeSize: badgeSize,
            badgeOffset: badgeOffset
        ).logicalRect
    }

    func badgeOffset(
        colorName: String?,
        badgeSize: NSSize,
        placingBadgeCenterAt center: NSPoint
    ) -> NSPoint {
        let anchorRect = asset(for: colorName) == nil ? frontRect : assetFrontRect

        let placement = placementResolver.placement(
            from: anchorRect,
            badgeSize: badgeSize,
            badgeOffset: .zero
        )

        return NSPoint(
            x: center.x - placement.logicalRect.midX,
            y: center.y - placement.logicalRect.midY
        )
    }

    private func renderRepresentation(
        size: Int,
        folderAsset: FolderAsset?,
        fallbackColor: NSColor,
        symbolName: String?,
        symbolText: String?,
        badgeVisual: BadgeVisual?,
        badgeComposition: BadgeComposition?,
        configuration: BadgeConfiguration
    ) -> NSBitmapImageRep? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return nil
        }

        let canvas = NSSize(width: size, height: size)
        let scale = CGFloat(size) / 1024.0
        bitmap.size = canvas

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.cgContext.clear(CGRect(origin: .zero, size: canvas))
        context.imageInterpolation = .high
        context.shouldAntialias = true

        if let folderAsset, drawFolderAsset(folderAsset, size: size, in: canvas) {
            drawFolderSymbol(systemName: symbolName, text: symbolText, in: assetSymbolRect, scale: scale)
            drawBadge(
                badgeVisual,
                badgeComposition: badgeComposition,
                in: assetFrontRect,
                configuration: configuration,
                scale: scale
            )
        } else {
            drawFallbackFolderBase(color: fallbackColor, scale: scale)
            drawFolderSymbol(systemName: symbolName, text: symbolText, in: symbolRect, scale: scale)
            drawBadge(
                badgeVisual,
                badgeComposition: badgeComposition,
                in: frontRect,
                configuration: configuration,
                scale: scale
            )
        }

        NSGraphicsContext.restoreGraphicsState()
        return bitmap
    }

    private func drawFolderAsset(_ asset: FolderAsset, size: Int, in canvas: NSSize) -> Bool {
        guard let image = folderAssetImage(asset: asset, size: size) else {
            return false
        }

        image.draw(
            in: NSRect(origin: .zero, size: canvas),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        return true
    }

    private func folderAssetImage(asset: FolderAsset, size: Int) -> NSImage? {
        let cacheKey = "\(asset.directoryName)/\(asset.filePrefix)\(size)"
        if let cachedImage = folderAssetImageCache[cacheKey] {
            return cachedImage
        }

        guard let url = folderAssetURL(asset: asset, size: size),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        folderAssetImageCache[cacheKey] = image
        return image
    }

    private func folderAssetURL(asset: FolderAsset, size: Int) -> URL? {
        let fileName = "\(asset.filePrefix)\(size)"

        let bundle = Bundle(for: BundleToken.self)

        if let url = bundle.url(
            forResource: fileName,
            withExtension: "png",
            subdirectory: "Carpetas/\(asset.directoryName)"
        ) {
            return url
        }

        if let url = Bundle.main.url(
            forResource: fileName,
            withExtension: "png",
            subdirectory: "Carpetas/\(asset.directoryName)"
        ) {
            return url
        }

        return developmentAssetRoot()?
            .appendingPathComponent(asset.directoryName)
            .appendingPathComponent("\(fileName).png")
    }

    private func developmentAssetRoot() -> URL? {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let url = projectRoot.appendingPathComponent("Carpetas")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func asset(for colorName: String?) -> FolderAsset? {
        let effectiveColorName = colorName ?? "blue"

        switch normalized(effectiveColorName) {
        case "roja", "rojo", "red":
            return FolderAsset(directoryName: "Rojo png", filePrefix: "Rojo")
        case "naranja", "orange":
            return FolderAsset(directoryName: "Naranja png", filePrefix: "Naranja")
        case "amarilla", "amarillo", "yellow":
            return FolderAsset(directoryName: "Amarillo png", filePrefix: "Amarillo")
        case "verde", "green":
            return FolderAsset(directoryName: "Verde png", filePrefix: "Verde")
        case "azul", "blue":
            return FolderAsset(directoryName: "Azul png", filePrefix: "Azul")
        case "azulclaro", "azulclara", "lightblue", "cyan":
            return FolderAsset(directoryName: "Azul Claro png", filePrefix: "AzulClaro")
        case "violeta", "morada", "morado", "purpura", "purple", "violet":
            return FolderAsset(directoryName: "Violeta png", filePrefix: "Violeta")
        case "rosa", "pink":
            return FolderAsset(directoryName: "Rosa png", filePrefix: "Rosa")
        case "gris", "gray", "grey":
            return FolderAsset(directoryName: "Gris png", filePrefix: "Gris")
        default:
            return nil
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func drawFallbackFolderBase(color: NSColor, scale: CGFloat) {
        let backRect = scaled(backRect, scale: scale)
        let tabRect = scaled(tabRect, scale: scale)
        let frontRect = scaled(frontRect, scale: scale)

        NSGraphicsContext.current?.cgContext.setShadow(
            offset: CGSize(width: 0, height: -18 * scale),
            blur: 24 * scale,
            color: NSColor.black.withAlphaComponent(0.32).cgColor
        )

        let backPath = NSBezierPath(roundedRect: backRect, xRadius: 44 * scale, yRadius: 44 * scale)
        adjusted(color, brightness: -0.12).setFill()
        backPath.fill()

        let tabPath = folderTabPath(in: tabRect, scale: scale)
        adjusted(color, brightness: -0.08).setFill()
        tabPath.fill()

        NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

        if let backGradient = NSGradient(colors: [
            adjusted(color, brightness: 0.22),
            adjusted(color, brightness: -0.10)
        ]) {
            backGradient.draw(in: backPath, angle: 90)
            backGradient.draw(in: tabPath, angle: 90)
        }

        let frontPath = NSBezierPath(roundedRect: frontRect, xRadius: 42 * scale, yRadius: 42 * scale)
        if let frontGradient = NSGradient(colors: [
            adjusted(color, brightness: 0.28),
            adjusted(color, brightness: 0.04),
            adjusted(color, brightness: -0.08)
        ]) {
            frontGradient.draw(in: frontPath, angle: 90)
        } else {
            color.setFill()
            frontPath.fill()
        }

        NSColor.white.withAlphaComponent(0.30).setStroke()
        frontPath.lineWidth = 2.0 * scale
        frontPath.stroke()

        let topHighlight = NSBezierPath()
        topHighlight.move(to: NSPoint(x: frontRect.minX + 34 * scale, y: frontRect.maxY - 30 * scale))
        topHighlight.line(to: NSPoint(x: frontRect.maxX - 34 * scale, y: frontRect.maxY - 30 * scale))
        NSColor.white.withAlphaComponent(0.20).setStroke()
        topHighlight.lineWidth = 5 * scale
        topHighlight.stroke()

        let lowerShade = NSBezierPath(roundedRect: frontRect.insetBy(dx: 12 * scale, dy: 12 * scale), xRadius: 34 * scale, yRadius: 34 * scale)
        NSColor.black.withAlphaComponent(0.05).setStroke()
        lowerShade.lineWidth = 8 * scale
        lowerShade.stroke()
    }

    private func folderTabPath(in rect: NSRect, scale: CGFloat) -> NSBezierPath {
        let radius = 28 * scale
        let slantWidth = min(rect.width * 0.34, rect.height / tan(50 * CGFloat.pi / 180))
        let topRightX = rect.maxX - slantWidth

        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - radius))
        path.curve(
            to: NSPoint(x: rect.minX + radius, y: rect.maxY),
            controlPoint1: NSPoint(x: rect.minX, y: rect.maxY - radius * 0.45),
            controlPoint2: NSPoint(x: rect.minX + radius * 0.45, y: rect.maxY)
        )
        path.line(to: NSPoint(x: topRightX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        path.close()

        return path
    }

    private func drawFolderSymbol(systemName: String?, text: String?, in container: NSRect, scale: CGFloat) {
        if let systemName,
           let symbol = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) {
            drawSymbolImage(symbol, in: container, scale: scale)
            return
        }

        if let text, !text.isEmpty {
            drawSymbolText(text, in: container, scale: scale)
        }
    }

    private func drawSymbolImage(_ symbol: NSImage, in container: NSRect, scale: CGFloat) {
        let symbolRect = aspectFitRect(for: symbol.size, in: scaled(container, scale: scale))
        symbol.isTemplate = true
        NSColor.black.withAlphaComponent(0.18).set()
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.18)
    }

    private func drawSymbolText(_ text: String, in container: NSRect, scale: CGFloat) {
        let rect = scaled(container, scale: scale)
        let fontSize = rect.height * 0.72
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        attributedText.draw(in: textRect)
    }

    private func drawBadge(
        _ badgeVisual: BadgeVisual?,
        badgeComposition: BadgeComposition?,
        in anchorRect: NSRect,
        configuration: BadgeConfiguration,
        scale: CGFloat
    ) {
        guard badgeVisual != nil || badgeComposition != nil else { return }

        let logicalPlacement = placementResolver.placement(
            kind: .folder,
            positionAnchorRect: anchorRect,
            sizeAnchorRect: anchorRect,
            badgeSize: configuration.size,
            badgeOffset: configuration.offset,
            position: configuration.position
        )

        let rect = scaled(logicalPlacement.logicalRect, scale: scale)

        if let badgeComposition {
            badgeVisualDrawer.draw(
                badgeComposition,
                in: rect,
                trimsArtworkWithoutShadow: true
            )
        } else if let badgeVisual {
            drawTrimmed(badgeVisual: badgeVisual, in: rect)
        }
    }

    private func scaled(_ rect: NSRect, scale: CGFloat) -> NSRect {
        NSRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
    }

    private func aspectFitRect(for sourceSize: NSSize, in container: NSRect) -> NSRect {
        guard sourceSize.width > 0, sourceSize.height > 0 else { return container }

        let scale = min(container.width / sourceSize.width, container.height / sourceSize.height)
        let size = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)

        return NSRect(
            x: container.midX - size.width / 2,
            y: container.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func drawTrimmed(badgeVisual: BadgeVisual, in rect: NSRect) {
        badgeVisualDrawer.draw(
            badgeVisual,
            in: rect,
            trimsArtworkWithoutShadow: true
        )
    }

    private func adjusted(_ color: NSColor, brightness delta: CGFloat) -> NSColor {
        guard let color = color.usingColorSpace(.deviceRGB) else { return color }

        return NSColor(
            red: max(0, min(1, color.redComponent + delta)),
            green: max(0, min(1, color.greenComponent + delta)),
            blue: max(0, min(1, color.blueComponent + delta)),
            alpha: color.alphaComponent
        )
    }
}

private final class BundleToken {}
