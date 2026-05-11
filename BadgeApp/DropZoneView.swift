import Cocoa

class DropZoneView: NSView {
    weak var viewController: ViewController!
    private let badgeHitSlop: CGFloat = 10
    private var currentIconRect: NSRect = .zero
    private var currentBadgeRect: NSRect = .zero
    private var currentBadgeVisibleRect: NSRect = .zero
    private var isDraggingBadge = false
    private var badgeDragCenterOffset: NSPoint = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let items = viewController.items
        if items.isEmpty {
            currentIconRect = .zero
            currentBadgeRect = .zero
            currentBadgeVisibleRect = .zero
            drawDropPrompt()
            return
        }

        guard let item = items.last else { return }

        let iconRect = previewIconRect()
        currentIconRect = iconRect
        let badgeGeometry = badgeGeometryInView(for: item, iconRect: iconRect)
        currentBadgeRect = badgeGeometry?.logicalRect ?? .zero
        currentBadgeVisibleRect = badgeGeometry?.visibleRect ?? .zero

        drawItem(
            item: item,
            iconRect: iconRect
        )
    }

    func drawDropPrompt() {
        let text = "Arrastra una carpeta o archivo aqui"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let rect = NSRect(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2, width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attrs)

        let borderRect = bounds.insetBy(dx: 20, dy: 20)
        NSColor.secondaryLabelColor.setStroke()
        let path = NSBezierPath(roundedRect: borderRect, xRadius: 10, yRadius: 10)
        path.lineWidth = 2
        path.setLineDash([6, 4], count: 2, phase: 0)
        path.stroke()
    }

    func drawItem(item: DroppedItem, iconRect: NSRect) {
        if viewController.isPreviewSelected {
            NSColor.selectedControlColor.withAlphaComponent(0.26).setFill()
            NSBezierPath(roundedRect: iconRect.insetBy(dx: -10, dy: -10), xRadius: 18, yRadius: 18).fill()

            NSColor.selectedControlColor.setStroke()
            let selectionPath = NSBezierPath(roundedRect: iconRect.insetBy(dx: -10, dy: -10), xRadius: 18, yRadius: 18)
            selectionPath.lineWidth = 3
            selectionPath.stroke()
        }

        let previewImage = viewController.previewIcon(for: item)
        let imageRect = item.isDirectory ? iconRect : aspectFitRect(for: previewImage, in: iconRect)
        previewImage.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        let name = (item.path as NSString).lastPathComponent
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let nameSize = (name as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: iconRect.midX - min(nameSize.width + 20, iconRect.width) / 2,
            y: iconRect.minY - 72,
            width: min(nameSize.width + 20, iconRect.width),
            height: 22
        )
        (name as NSString).draw(in: textRect, withAttributes: attrs)

        if item.isDirectory {
            drawFolderColorInfo(for: item, below: textRect)
        }
    }

    private func drawFolderColorInfo(for item: DroppedItem, below rect: NSRect) {
        let label = item.folderColorName ?? "sin color"
        let color = item.folderColor ?? NSColor.clear
        let swatchSize: CGFloat = 9
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: item.folderColor == nil ? NSColor.tertiaryLabelColor : NSColor.secondaryLabelColor
        ]
        let labelSize = (label as NSString).size(withAttributes: attrs)
        let totalWidth = labelSize.width + (item.folderColor == nil ? 0 : swatchSize + 5)
        let originX = rect.midX - totalWidth / 2
        let swatchRect = NSRect(
            x: originX,
            y: rect.minY - 24,
            width: swatchSize,
            height: swatchSize
        )

        if item.folderColor != nil {
            color.setFill()
            NSBezierPath(ovalIn: swatchRect).fill()
            NSColor.separatorColor.setStroke()
            NSBezierPath(ovalIn: swatchRect).stroke()
        }

        let textRect = NSRect(
            x: item.folderColor == nil ? originX : swatchRect.maxX + 5,
            y: rect.minY - 27,
            width: labelSize.width + 4,
            height: 16
        )
        (label as NSString).draw(in: textRect, withAttributes: attrs)
    }

    private func previewIconRect() -> NSRect {
        let labelHeight: CGFloat = 112
        let verticalPadding: CGFloat = 24
        let previewSize = min(512, bounds.width - 48, bounds.height - labelHeight - verticalPadding * 2)

        return NSRect(
            x: bounds.midX - previewSize / 2,
            y: bounds.midY - (previewSize + labelHeight) / 2 + labelHeight,
            width: previewSize,
            height: previewSize
        )
    }

    private func aspectFitRect(for image: NSImage, in bounds: NSRect) -> NSRect {
        let imageSize = imagePixelSize(image)
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let fittedSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return NSRect(
            x: bounds.midX - fittedSize.width / 2,
            y: bounds.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private func imagePixelSize(_ image: NSImage) -> NSSize {
        if let representation = image.representations.max(by: {
            ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
        }), representation.pixelsWide > 0, representation.pixelsHigh > 0 {
            return NSSize(width: representation.pixelsWide, height: representation.pixelsHigh)
        }

        return image.size
    }

    private func badgeGeometryInView(for item: DroppedItem, iconRect: NSRect) -> BadgeGeometry? {
        guard let badgeGeometry = viewController.previewBadgeGeometry(for: item) else { return nil }

        let scale = iconRect.width / 1024
        return BadgeGeometry(
            logicalRect: NSRect(
                x: iconRect.minX + badgeGeometry.logicalRect.minX * scale,
                y: iconRect.minY + badgeGeometry.logicalRect.minY * scale,
                width: badgeGeometry.logicalRect.width * scale,
                height: badgeGeometry.logicalRect.height * scale
            ),
            visibleRect: NSRect(
                x: iconRect.minX + badgeGeometry.visibleRect.minX * scale,
                y: iconRect.minY + badgeGeometry.visibleRect.minY * scale,
                width: badgeGeometry.visibleRect.width * scale,
                height: badgeGeometry.visibleRect.height * scale
            )
        )
    }

    private func iconPoint(from viewPoint: NSPoint) -> NSPoint {
        let scale = 1024 / currentIconRect.width
        return NSPoint(
            x: (viewPoint.x - currentIconRect.minX) * scale,
            y: (viewPoint.y - currentIconRect.minY) * scale
        )
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        guard let items = pasteboard.pasteboardItems else { return false }

        for item in items.reversed() {
            if let urlString = item.string(forType: NSPasteboard.PasteboardType.fileURL),
               let url = URL(string: urlString) {
                viewController.addItem(path: url.path)
                window?.makeFirstResponder(self)
                return true
            }
        }
        return false
    }

    override func mouseDown(with event: NSEvent) {
        guard let item = viewController.items.last else {
            super.mouseDown(with: event)
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        currentIconRect = previewIconRect()
        let badgeGeometry = badgeGeometryInView(for: item, iconRect: currentIconRect)
        currentBadgeRect = badgeGeometry?.logicalRect ?? .zero
        currentBadgeVisibleRect = badgeGeometry?.visibleRect ?? .zero
        let badgeHitRect = currentBadgeVisibleRect.insetBy(dx: -badgeHitSlop, dy: -badgeHitSlop)

        isDraggingBadge = !currentBadgeVisibleRect.isEmpty && badgeHitRect.contains(point)
        viewController.isPreviewSelected = currentIconRect.contains(point)
        if viewController.isPreviewSelected {
            window?.makeFirstResponder(self)
        }

        if isDraggingBadge {
            let pointInIcon = iconPoint(from: point)
            let badgeCenter = iconPoint(from: NSPoint(x: currentBadgeVisibleRect.midX, y: currentBadgeVisibleRect.midY))
            badgeDragCenterOffset = NSPoint(
                x: badgeCenter.x - pointInIcon.x,
                y: badgeCenter.y - pointInIcon.y
            )
            viewController.placePreviewBadgeVisibleCenter(badgeCenter, for: item)
        }

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDraggingBadge,
              let item = viewController.items.last,
              !currentIconRect.isEmpty else {
            super.mouseDragged(with: event)
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        let pointInIcon = iconPoint(from: point)
        viewController.placePreviewBadgeVisibleCenter(
            NSPoint(
                x: pointInIcon.x + badgeDragCenterOffset.x,
                y: pointInIcon.y + badgeDragCenterOffset.y
            ),
            for: item
        )
    }

    override func mouseUp(with event: NSEvent) {
        isDraggingBadge = false
        badgeDragCenterOffset = .zero
    }

    override func keyDown(with event: NSEvent) {
        guard viewController.isPreviewSelected,
              let character = event.charactersIgnoringModifiers?.first,
              character == Character(UnicodeScalar(NSDeleteCharacter)!) ||
                character == Character(UnicodeScalar(NSBackspaceCharacter)!) else {
            super.keyDown(with: event)
            return
        }

        viewController.removeSelectedPreviewItem()
    }
}
