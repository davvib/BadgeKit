import Cocoa
import Darwin
import QuickLookThumbnailing
import UniformTypeIdentifiers
import BadgeKit

struct BadgeAppFolderMetadata: Codable {
    let colorName: String?
    let symbolName: String?
    let symbolText: String?
}

struct BadgeAppBadgeState: Codable {
    let version: Int
    let badgeSize: Double
    let badgeOffsetX: Double
    let badgeOffsetY: Double
}

private struct FolderSymbolInfo {
    let systemName: String?
    let text: String?
}

class ViewController: NSViewController, NSTextFieldDelegate {
    weak var appDelegate: AppDelegate!
    var dropZoneView: DropZoneView!
    var items: [DroppedItem] = []
    var badgeOffsetX: CGFloat = 4
    var badgeOffsetY: CGFloat = -4
    var customBadges: [CustomBadgeRecord] = []
    var isPreviewSelected = false
    private let savedBadgePixelSize = 1024
    private let finderInfoHasCustomIconFlag: UInt16 = 0x0400
    private let finderInfoExtendedFlagsAreInvalidFlag: UInt16 = 0x8000
    private let folderIconFileName = "Icon\r"
    private let folderResetDelay: TimeInterval = 0.8
    private let folderIconRenderSizes = [16, 32, 64, 128, 256, 512, 1024]
    private let badgeAppFolderMetadataXattr = "com.badgeapp.folderMetadata"
    private let badgeAppBadgeStateXattr = "com.badgeapp.badgeState"
    private let badgeAppBackupIDXattr = "com.badgeapp.backupID"
    private let metadataQueue = DispatchQueue(label: "com.badgeapp.metadata", qos: .userInitiated)
    private var previewMessageView: NSView?
    private var previewMessageLabel: NSTextField?
    private var previewMessageTimer: Timer?
    private let badgePreviewGeometryCoordinator = BadgePreviewGeometryCoordinator()
    private let badgeFolderPreviewRenderer = BadgeFolderPreviewRenderer()
    private let badgePreviewCacheKeyBuilder = BadgePreviewCacheKeyBuilder()
    private let badgePreviewIconRenderer = BadgePreviewIconRenderer()
    private let badgeIconComposer = BadgeIconComposer()
    private let badgeImageNormalizer = BadgeImageNormalizer()
    private let customBadgeStore = CustomBadgeStore()
    private let iconBackupStore = IconBackupStore()

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 650))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCustomBadges()
        setupUI()
        metadataQueue.async { [weak self] in
            self?.cleanupStoredIconBackups()
        }
    }

    func loadCustomBadges() {
        customBadges = customBadgeStore.loadBadges()
    }

    func saveCustomBadge(image: NSImage, name: String) -> Bool {
        guard let badge = customBadgeStore.saveBadge(
            image: image,
            name: name,
            normalizer: badgeImageNormalizer
        ) else {
            return false
        }

        customBadges.append(badge)
        return true
    }

    private func iconBackupsDirectory() -> URL? {
        iconBackupStore.backupsDirectory()
    }

    private func iconBackupRecordsDirectory() -> URL? {
        iconBackupStore.recordsDirectory()
    }

    private func iconBackupImagesDirectory() -> URL? {
        iconBackupStore.imagesDirectory()
    }

    private func iconBackupRecordURL(for id: String) -> URL? {
        iconBackupStore.recordURL(for: id)
    }

    private func backedUpIcon(for path: String) -> NSImage? {
        guard shouldUseBackedUpIcon(for: path) else { return nil }

        guard let record = iconBackupRecord(for: path),
              let imagesDir = iconBackupImagesDirectory() else { return nil }

        if let previewIconFileName = record.previewIconFileName,
           let previewIcon = NSImage(contentsOf: imagesDir.appendingPathComponent(previewIconFileName)) {
            return previewIcon
        }

        guard record.hadCustomIcon,
              let iconFileName = record.iconFileName else { return nil }

        return NSImage(contentsOf: imagesDir.appendingPathComponent(iconFileName))
    }

    private func shouldUseBackedUpIcon(for path: String) -> Bool {
        hasCustomFinderIcon(at: path) ||
        hasFolderVisualCustomization(at: path) ||
        folderIconFileExists(at: path)
    }

    private func folderCustomizationColor(at path: String) -> NSColor? {
        folderCustomizationColorInfo(at: path)?.color
    }

    private func folderCustomizationColorInfo(at path: String) -> (name: String, color: NSColor)? {
        if let metadata = badgeAppFolderMetadata(at: path),
           let name = metadata.colorName,
           let color = folderColor(named: name) {
            return (name, color)
        }

        if let colorInfo = folderCustomizationColorInfo(
            fromUserTagsData: xattrData(named: "com.apple.metadata:_kMDItemUserTags", at: path)
        ) {
            return colorInfo
        }

        if let data = iconBackupRecord(for: path)?
            .visualCustomizationXattrs?["com.apple.metadata:_kMDItemUserTags"],
           let colorInfo = folderCustomizationColorInfo(fromUserTagsData: data) {
            return colorInfo
        }

        return nil
    }

    private func folderCustomizationColorInfo(fromUserTagsData data: Data?) -> (name: String, color: NSColor)? {
        guard let data,
              let tags = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] else {
            return nil
        }

        for tag in tags {
            let name = tag
                .components(separatedBy: .newlines)
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let name, let color = folderColor(named: name) {
                return (name, color)
            }
        }

        return nil
    }

    private func folderColor(named name: String) -> NSColor? {
        switch name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) {
        case "roja", "rojo", "red":
            return NSColor(red: 1.00, green: 0.32, blue: 0.28, alpha: 1)
        case "naranja", "orange":
            return NSColor(red: 1.00, green: 0.58, blue: 0.24, alpha: 1)
        case "amarilla", "amarillo", "yellow":
            return NSColor(red: 1.00, green: 0.84, blue: 0.14, alpha: 1)
        case "verde", "green":
            return NSColor(red: 0.30, green: 0.82, blue: 0.42, alpha: 1)
        case "azul", "blue":
            return NSColor(red: 0.18, green: 0.61, blue: 0.95, alpha: 1)
        case "azul claro", "azulclaro", "light blue", "lightblue", "cyan":
            return NSColor(red: 0.38, green: 0.76, blue: 0.92, alpha: 1)
        case "violeta", "morada", "morado", "purpura", "purple", "violet":
            return NSColor(red: 0.78, green: 0.28, blue: 0.93, alpha: 1)
        case "rosa", "pink":
            return NSColor(red: 1.00, green: 0.32, blue: 0.48, alpha: 1)
        case "gris", "gray", "grey":
            return NSColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        default:
            return nil
        }
    }

    private func folderSymbolInfo(at path: String) -> FolderSymbolInfo {
        if let metadata = badgeAppFolderMetadata(at: path),
           metadata.symbolName != nil || metadata.symbolText != nil {
            return FolderSymbolInfo(systemName: metadata.symbolName, text: metadata.symbolText)
        }

        for name in folderSymbolXattrNames(at: path) {
            if let symbolInfo = folderSymbolInfo(fromData: xattrData(named: name, at: path)) {
                return symbolInfo
            }
        }

        if let xattrs = iconBackupRecord(for: path)?.visualCustomizationXattrs {
            for name in folderSymbolXattrNames(in: Array(xattrs.keys)) {
                if let symbolInfo = folderSymbolInfo(fromData: xattrs[name]) {
                    return symbolInfo
                }
            }
        }

        return FolderSymbolInfo(systemName: nil, text: nil)
    }

    private func folderSymbolXattrNames(at path: String) -> [String] {
        folderSymbolXattrNames(in: xattrNames(at: path))
    }

    private func folderSymbolXattrNames(in names: [String]) -> [String] {
        let preferred = ["com.apple.icon.folder#S"]
        let iconNames = names
            .filter { $0.hasPrefix("com.apple.icon.folder") }
            .sorted()

        return preferred + iconNames.filter { !preferred.contains($0) }
    }

    private func folderSymbolInfo(fromData data: Data?) -> FolderSymbolInfo? {
        guard let data else {
            return nil
        }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let stringValues = object.values.compactMap { $0 as? String }

            if let symbolName = object["sym"] as? String,
               NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil {
                return FolderSymbolInfo(systemName: symbolName, text: nil)
            }

            if let emoji = stringValues.first(where: isEmojiFolderSymbol) {
                return FolderSymbolInfo(systemName: nil, text: emoji)
            }

            if let symbolName = stringValues.first(where: {
                NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil
            }) {
                return FolderSymbolInfo(systemName: symbolName, text: nil)
            }
        }

        if let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           isEmojiFolderSymbol(text) {
            return FolderSymbolInfo(systemName: nil, text: text)
        }

        return nil
    }

    private func isEmojiFolderSymbol(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 8 else { return false }

        return trimmed.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation ||
            scalar.properties.isEmojiModifier ||
            scalar.properties.isEmojiModifierBase ||
            scalar.properties.isJoinControl ||
            scalar.value == 0xfe0f
        }
    }

    private func customRenderedFolderIcon(for item: DroppedItem, badge: NSImage? = nil) -> NSImage? {
        badgeFolderPreviewRenderer.renderIcon(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badge: badge,
            badgeSize: NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize),
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY)
        )
    }

    private func customRenderedFolderPreview(for item: DroppedItem, badge: NSImage? = nil) -> NSImage? {
        badgeFolderPreviewRenderer.renderPreview(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badge: badge,
            badgeSize: NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize),
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY)
        )
    }

    func previewIcon(for item: DroppedItem) -> NSImage {
        guard item.showsBadgePreview,
              let badge = appDelegate.selectedBadge else {
            return customRenderedFolderPreview(for: item) ?? item.icon
        }

        let previewKey = badgePreviewCacheKeyBuilder.makeKey(
            icon: item.baseIconForPreview ?? item.icon,
            badge: badge,
            badgeSize: appDelegate.badgeSize,
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY),
            folderColorName: item.folderColorName,
            folderSymbolName: item.folderSymbolName,
            folderSymbolText: item.folderSymbolText
        )

        if item.cachedPreviewKey == previewKey,
           let cachedPreviewIcon = item.cachedPreviewIcon {
            return cachedPreviewIcon
        }

        let badgeSize = NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize)
        let previewIcon = badgePreviewIconRenderer.renderPreviewIcon(
            baseIcon: item.baseIconForPreview ?? item.icon,
            folderColorName: item.folderColorName,
            folderColor: item.folderColor,
            folderSymbolName: item.folderSymbolName,
            folderSymbolText: item.folderSymbolText,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY),
            fallbackRenderer: { [weak self] baseIcon, badge, badgeSize in
                guard let self else { return baseIcon }
                return self.makeBadgedIcon(
                    originalIcon: baseIcon,
                    badge: badge,
                    badgeSize: badgeSize
                )
            }
        )
        item.cachedPreviewKey = previewKey
        item.cachedPreviewIcon = previewIcon

        return previewIcon
    }

    func previewBadgeRect(for item: DroppedItem) -> NSRect? {
        previewBadgeGeometry(for: item)?.logicalRect
    }

    func previewBadgeGeometry(for item: DroppedItem) -> BadgeGeometry? {
        guard item.showsBadgePreview,
              let badge = appDelegate.selectedBadge else {
            return nil
        }

        return badgePreviewGeometryCoordinator.geometry(
            isDirectory: item.isDirectory,
            folderColorName: item.folderColorName,
            icon: item.baseIconForPreview ?? item.icon,
            badge: badge,
            badgeSize: NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize),
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY)
        )
    }

    func placePreviewBadgeCenter(_ center: NSPoint, for item: DroppedItem) {
        let offset = badgePreviewGeometryCoordinator.offset(
            isDirectory: item.isDirectory,
            folderColorName: item.folderColorName,
            icon: item.baseIconForPreview ?? item.icon,
            badgeSize: NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize),
            placingBadgeCenterAt: center
        )
        badgeOffsetX = offset.x
        badgeOffsetY = offset.y
        item.showsBadgePreview = true
        item.cachedPreviewIcon = nil
        item.cachedPreviewKey = nil
        dropZoneView.needsDisplay = true
    }

    func placePreviewBadgeVisibleCenter(_ center: NSPoint, for item: DroppedItem) {
        guard let badge = appDelegate.selectedBadge else {
            placePreviewBadgeCenter(center, for: item)
            return
        }

        let logicalCenter = badgePreviewGeometryCoordinator.logicalCenter(
            forVisibleCenter: center,
            isDirectory: item.isDirectory,
            icon: item.baseIconForPreview ?? item.icon,
            badge: badge,
            badgeSize: NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize),
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY)
        )

        placePreviewBadgeCenter(logicalCenter, for: item)
    }

    private func refreshRestoredVisualState(for item: DroppedItem) {
        refreshCurrentVisualState(for: item, showsBadgePreview: false)
    }

    private func refreshCurrentVisualState(for item: DroppedItem, showsBadgePreview: Bool? = nil) {
        let colorInfo = folderCustomizationColorInfo(at: item.path)
        item.folderColorName = colorInfo?.name
        item.folderColor = colorInfo?.color
        let symbolInfo = folderSymbolInfo(at: item.path)
        item.folderSymbolName = symbolInfo.systemName
        item.folderSymbolText = symbolInfo.text
        item.icon = customRenderedFolderPreview(for: item) ?? NSWorkspace.shared.icon(forFile: item.path)
        item.baseIconForPreview = backedUpIcon(for: item.path)
        item.badgeStatus = badgeStatus(
            badgeState: badgeAppBadgeState(at: item.path),
            hasAppBadge: hasBadgeAppliedByBadgeApp(at: item.path),
            hasCustomIcon: hasCustomFinderIcon(at: item.path),
            hasVisualCustomization: item.isDirectory && hasFolderVisualCustomization(at: item.path),
            hasCleanBaseIcon: item.baseIconForPreview != nil
        )
        item.cachedPreviewIcon = nil
        item.cachedPreviewKey = nil
        if let showsBadgePreview {
            item.showsBadgePreview = showsBadgePreview
        }
    }

    private func folderIcon(_ icon: NSImage, tintedWith color: NSColor?) -> NSImage {
        guard let color else { return icon }

        let renderedIcon = NSImage(size: icon.size)
        renderedIcon.lockFocus()

        let bounds = NSRect(origin: .zero, size: renderedIcon.size)
        icon.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0)
        color.withAlphaComponent(0.24).setFill()
        bounds.fill(using: .sourceAtop)
        icon.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 0.55)

        renderedIcon.unlockFocus()

        return renderedIcon
    }

    private func configureRepeatingButton(_ button: NSButton) {
        button.isContinuous = true
        (button.cell as? NSButtonCell)?.setPeriodicDelay(0.25, interval: 0.04)
    }

    private func saveOriginalIconStateIfNeeded(for path: String) {
        if iconBackupRecord(for: path) != nil {
            return
        }

        removeBadgeAppBackupID(at: path)

        guard let backupsDir = iconBackupsDirectory(),
              let recordsDir = iconBackupRecordsDirectory(),
              let imagesDir = iconBackupImagesDirectory() else { return }

        let url = URL(fileURLWithPath: path)
        let visualCustomizationXattrs = folderVisualCustomizationXattrs(at: path)
        let hasCustomIcon = hasCustomFinderIcon(at: path)
        let shouldBackupIconImage = hasCustomIcon || !visualCustomizationXattrs.isEmpty || folderIconFileExists(at: path)
        let finderInfoData = xattrData(named: "com.apple.FinderInfo", at: path)
        let id = UUID().uuidString
        let iconFileName = shouldBackupIconImage ? "\(id).tiff" : nil
        let previewIconFileName = "\(id)-preview.tiff"

        do {
            try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: recordsDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

            if let tiffData = NSWorkspace.shared.icon(forFile: path).tiffRepresentation {
                try tiffData.write(to: imagesDir.appendingPathComponent(previewIconFileName))
            }

            if let iconFileName,
               let tiffData = NSWorkspace.shared.icon(forFile: path).tiffRepresentation {
                try tiffData.write(to: imagesDir.appendingPathComponent(iconFileName))
            }

            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            let record = IconBackupRecord(
                id: id,
                originalPath: path,
                bookmarkData: bookmarkData,
                createdAt: Date(),
                originalResourceIdentifier: fileResourceIdentifierString(for: url),
                hadCustomIcon: shouldBackupIconImage,
                iconFileName: iconFileName,
                previewIconFileName: previewIconFileName,
                visualCustomizationXattrs: visualCustomizationXattrs.isEmpty ? nil : visualCustomizationXattrs,
                finderInfoData: finderInfoData
            )
            let data = try JSONEncoder().encode(record)
            try data.write(to: iconBackupRecordURL(for: id)!)
            writeBadgeAppBackupID(id, at: path)
        } catch {
            print("Error backing up original icon state: \(error)")
        }
    }

    private func restoreOriginalIconStateIfAvailable(for path: String) -> Bool {
        guard let record = iconBackupRecord(for: path),
              let recordURL = iconBackupRecordURL(for: record.id) else {
            return false
        }

        var didRestore = false

        if record.hadCustomIcon,
           let iconFileName = record.iconFileName,
           let imagesDir = iconBackupImagesDirectory(),
           let originalIcon = NSImage(contentsOf: imagesDir.appendingPathComponent(iconFileName)) {
            didRestore = NSWorkspace.shared.setIcon(originalIcon, forFile: path, options: [])
        } else {
            didRestore = NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
        }

        if didRestore {
            restoreFolderVisualCustomizationXattrs(record.visualCustomizationXattrs, to: path)
            restoreFinderInfo(record.finderInfoData, to: path)
            removeBadgeAppFolderMetadata(at: path)
            removeBadgeAppBadgeState(at: path)
            removeBadgeAppBackupID(at: path)
            try? FileManager.default.removeItem(at: recordURL)
            if let iconFileName = record.iconFileName,
               let imagesDir = iconBackupImagesDirectory() {
                try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(iconFileName))
            }
            if let previewIconFileName = record.previewIconFileName,
               let imagesDir = iconBackupImagesDirectory() {
                try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(previewIconFileName))
            }
            NSWorkspace.shared.noteFileSystemChanged(path)
        }

        return didRestore
    }

    private func cleanupStoredIconBackups() {
        guard let recordsDir = iconBackupRecordsDirectory(),
              let recordURLs = try? FileManager.default.contentsOfDirectory(
                at: recordsDir,
                includingPropertiesForKeys: nil
              ) else {
            return
        }

        for recordURL in recordURLs where recordURL.pathExtension == "json" {
            guard let data = try? Data(contentsOf: recordURL),
                  let record = try? JSONDecoder().decode(IconBackupRecord.self, from: data) else {
                continue
            }

            if shouldKeepStoredIconBackup(record) {
                continue
            }

            deleteIconBackupFiles(for: record, recordURL: recordURL)
        }
    }

    private func shouldKeepStoredIconBackup(_ record: IconBackupRecord) -> Bool {
        if let resolved = resolvedBookmark(from: record.bookmarkData, allowingStale: true) {
            return fileExistsOrIsInTrash(at: resolved.url)
        }

        if FileManager.default.fileExists(atPath: record.originalPath) {
            return true
        }

        return trashContainsItemNamed((record.originalPath as NSString).lastPathComponent)
    }

    private func fileExistsOrIsInTrash(at url: URL) -> Bool {
        if FileManager.default.fileExists(atPath: url.path) {
            return true
        }

        return url.standardizedFileURL.pathComponents.contains(".Trash") ||
            url.standardizedFileURL.pathComponents.contains(".Trashes")
    }

    private func trashContainsItemNamed(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }

        for trashDirectory in trashSearchDirectories() {
            guard let enumerator = FileManager.default.enumerator(
                at: trashDirectory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let itemURL as URL in enumerator where itemURL.lastPathComponent == name {
                return true
            }
        }

        return false
    }

    private func trashSearchDirectories() -> [URL] {
        var directories = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        ]

        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        if let volumeURLs = try? FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            let uid = String(getuid())
            directories += volumeURLs.map {
                $0.appendingPathComponent(".Trashes").appendingPathComponent(uid)
            }
        }

        return directories
    }

    private func deleteIconBackupFiles(for record: IconBackupRecord, recordURL: URL) {
        try? FileManager.default.removeItem(at: recordURL)

        guard let imagesDir = iconBackupImagesDirectory() else { return }
        if let iconFileName = record.iconFileName {
            try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(iconFileName))
        }
        if let previewIconFileName = record.previewIconFileName {
            try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(previewIconFileName))
        }
    }

    private func iconBackupRecord(for path: String) -> IconBackupRecord? {
        guard let backupID = badgeAppBackupID(at: path),
              let record = iconBackupRecord(withID: backupID),
              iconBackupRecord(record, belongsTo: path) else {
            return nil
        }

        return record
    }

    private func iconBackupRecord(withID id: String) -> IconBackupRecord? {
        iconBackupStore.record(withID: id)
    }

    private func iconBackupRecord(_ record: IconBackupRecord, belongsTo path: String) -> Bool {
        let targetURL = URL(fileURLWithPath: path).standardizedFileURL

        if let originalResourceIdentifier = record.originalResourceIdentifier,
           let targetIdentifier = fileResourceIdentifierString(for: targetURL) {
            return originalResourceIdentifier == targetIdentifier
        }

        return record.originalPath == path
    }

    private func resolvedBookmark(from bookmarkData: Data, allowingStale: Bool = false) -> (url: URL, isStale: Bool)? {
        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), allowingStale || !isStale {
            return (url, isStale)
        }

        isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), allowingStale || !isStale {
            return (url, isStale)
        }

        return nil
    }

    private func fileResourceIdentifier(for url: URL) -> NSObject? {
        guard let identifier = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]).fileResourceIdentifier else {
            return nil
        }

        return identifier as? NSObject
    }

    private func fileResourceIdentifierString(for url: URL) -> String? {
        guard let identifier = fileResourceIdentifier(for: url) else { return nil }
        if let data = identifier as? Data {
            return data.base64EncodedString()
        }
        return String(describing: identifier)
    }

    private func hasCustomFinderIcon(at path: String) -> Bool {
        guard let finderInfo = finderInfoBytes(at: path),
              finderInfo.count >= 10 else { return false }

        let flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        return (flags & finderInfoHasCustomIconFlag) != 0
    }

    private func hasFolderVisualCustomization(at path: String) -> Bool {
        !folderVisualCustomizationXattrs(at: path).isEmpty
    }

    private func isDirectory(at path: String) -> Bool {
        (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func folderVisualCustomizationXattrs(at path: String) -> [String: Data] {
        guard (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
            return [:]
        }

        return xattrNames(at: path)
            .filter(isFolderVisualCustomizationXattr)
            .reduce(into: [String: Data]()) { result, name in
                result[name] = xattrData(named: name, at: path)
            }
    }

    private func removeFolderVisualCustomizationXattrs(at path: String) {
        let xattrsToRemove = xattrNames(at: path).filter(isFolderVisualCustomizationXattr)
        let url = URL(fileURLWithPath: path)
        try? (url as NSURL).setResourceValue([], forKey: .tagNamesKey)

        for name in xattrsToRemove {
            path.withCString { pathPointer in
                name.withCString { namePointer in
                    _ = removexattr(pathPointer, namePointer, 0)
                }
            }
        }
    }

    private func isFolderVisualCustomizationXattr(_ name: String) -> Bool {
        name == "com.apple.metadata:_kMDItemUserTags" ||
        name.hasPrefix("com.apple.metadata:kMDLabel_") ||
        name.hasPrefix("com.apple.icon.")
    }

    private func folderIconFileURL(for path: String) -> URL {
        URL(fileURLWithPath: path).appendingPathComponent(folderIconFileName)
    }

    private func folderIconFileExists(at path: String) -> Bool {
        guard isDirectory(at: path) else { return false }
        return FileManager.default.fileExists(atPath: folderIconFileURL(for: path).path)
    }

    private func finderInfoBytes(at path: String) -> [UInt8]? {
        guard let data = xattrData(named: "com.apple.FinderInfo", at: path), data.count >= 32 else {
            return nil
        }

        return Array(data.prefix(32))
    }

    private func setFinderInfoBytes(_ finderInfo: [UInt8], at path: String) -> Bool {
        guard finderInfo.count == 32 else { return false }

        let result = finderInfo.withUnsafeBytes { buffer in
            path.withCString { pathPointer in
                setxattr(pathPointer, "com.apple.FinderInfo", buffer.baseAddress, buffer.count, 0, 0)
            }
        }

        return result == 0
    }

    private func restoreFinderInfo(_ data: Data?, to path: String) {
        guard let data else {
            path.withCString { pathPointer in
                _ = removexattr(pathPointer, "com.apple.FinderInfo", 0)
            }
            return
        }

        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }

            path.withCString { pathPointer in
                _ = setxattr(pathPointer, "com.apple.FinderInfo", baseAddress, buffer.count, 0, 0)
            }
        }
    }

    private func forceFinderCustomIconState(at path: String) {
        var finderInfo = finderInfoBytes(at: path) ?? [UInt8](repeating: 0, count: 32)

        var flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        flags |= finderInfoHasCustomIconFlag
        finderInfo[8] = UInt8((flags >> 8) & 0xff)
        finderInfo[9] = UInt8(flags & 0xff)

        var extendedFlags = (UInt16(finderInfo[24]) << 8) | UInt16(finderInfo[25])
        extendedFlags &= ~finderInfoExtendedFlagsAreInvalidFlag
        finderInfo[24] = UInt8((extendedFlags >> 8) & 0xff)
        finderInfo[25] = UInt8(extendedFlags & 0xff)

        _ = setFinderInfoBytes(finderInfo, at: path)
    }

    private func clearFinderCustomIconState(at path: String) {
        guard var finderInfo = finderInfoBytes(at: path) else { return }

        var flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        flags &= ~finderInfoHasCustomIconFlag
        finderInfo[8] = UInt8((flags >> 8) & 0xff)
        finderInfo[9] = UInt8(flags & 0xff)

        _ = setFinderInfoBytes(finderInfo, at: path)
    }

    private func resetFolderToPlainIconBeforeApplying(at path: String) {
        guard isDirectory(at: path) else { return }

        removeFolderVisualCustomizationXattrs(at: path)
        _ = NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
        try? FileManager.default.removeItem(at: folderIconFileURL(for: path))
        clearFinderCustomIconState(at: path)

        NSWorkspace.shared.noteFileSystemChanged(path)
        NSWorkspace.shared.noteFileSystemChanged((path as NSString).deletingLastPathComponent)
    }

    private func badgeAppFolderMetadata(at path: String) -> BadgeAppFolderMetadata? {
        guard let data = xattrData(named: badgeAppFolderMetadataXattr, at: path) else { return nil }
        return try? JSONDecoder().decode(BadgeAppFolderMetadata.self, from: data)
    }

    private func badgeAppBadgeState(at path: String) -> BadgeAppBadgeState? {
        guard let data = xattrData(named: badgeAppBadgeStateXattr, at: path) else { return nil }
        return try? JSONDecoder().decode(BadgeAppBadgeState.self, from: data)
    }

    private func badgeAppBackupID(at path: String) -> String? {
        guard let data = xattrData(named: badgeAppBackupIDXattr, at: path) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func hasBadgeAppliedByBadgeApp(at path: String) -> Bool {
        badgeAppBadgeState(at: path) != nil ||
        (iconBackupRecord(for: path) != nil && hasCustomFinderIcon(at: path))
    }

    private func badgeStatus(
        badgeState: BadgeAppBadgeState?,
        hasAppBadge: Bool,
        hasCustomIcon: Bool,
        hasVisualCustomization: Bool,
        hasCleanBaseIcon: Bool
    ) -> DroppedItemBadgeStatus {
        if badgeState != nil, hasCleanBaseIcon {
            return .badgeAppEditable
        }

        if hasAppBadge {
            return .badgeAppAppliedNotEditable
        }

        if hasCustomIcon || hasVisualCustomization {
            return .externalCustomIcon
        }

        return .none
    }

    private func writeBadgeAppBadgeState(at path: String) {
        let state = BadgeAppBadgeState(
            version: 1,
            badgeSize: Double(appDelegate.badgeSize),
            badgeOffsetX: Double(badgeOffsetX),
            badgeOffsetY: Double(badgeOffsetY)
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        setXattrData(data, named: badgeAppBadgeStateXattr, at: path)
    }

    private func removeBadgeAppBadgeState(at path: String) {
        path.withCString { pathPointer in
            _ = removexattr(pathPointer, badgeAppBadgeStateXattr, 0)
        }
    }

    private func writeBadgeAppBackupID(_ id: String, at path: String) {
        guard let data = id.data(using: .utf8) else { return }
        setXattrData(data, named: badgeAppBackupIDXattr, at: path)
    }

    private func removeBadgeAppBackupID(at path: String) {
        path.withCString { pathPointer in
            _ = removexattr(pathPointer, badgeAppBackupIDXattr, 0)
        }
    }

    private func writeBadgeAppFolderMetadata(for item: DroppedItem) {
        guard isDirectory(at: item.path),
              item.folderColorName != nil || item.folderSymbolName != nil || item.folderSymbolText != nil,
              let data = try? JSONEncoder().encode(BadgeAppFolderMetadata(
                colorName: item.folderColorName,
                symbolName: item.folderSymbolName,
                symbolText: item.folderSymbolText
              )) else {
            return
        }

        setXattrData(data, named: badgeAppFolderMetadataXattr, at: item.path)
    }

    private func removeBadgeAppFolderMetadata(at path: String) {
        path.withCString { pathPointer in
            _ = removexattr(pathPointer, badgeAppFolderMetadataXattr, 0)
        }
    }

    private func restoreBadgeAppFolderVisualStateIfAvailable(for path: String) -> Bool {
        guard let metadata = badgeAppFolderMetadata(at: path),
              metadata.colorName != nil || metadata.symbolName != nil || metadata.symbolText != nil else {
            return false
        }

        _ = NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
        clearFinderCustomIconState(at: path)

        if let colorName = metadata.colorName,
           let data = try? PropertyListSerialization.data(
            fromPropertyList: [colorName],
            format: .binary,
            options: 0
           ) {
            setXattrData(data, named: "com.apple.metadata:_kMDItemUserTags", at: path)
        }

        if let symbolName = metadata.symbolName,
           let data = try? JSONSerialization.data(withJSONObject: ["sym": symbolName]) {
            setXattrData(data, named: "com.apple.icon.folder#S", at: path)
        } else if let symbolText = metadata.symbolText,
                  let data = try? JSONSerialization.data(withJSONObject: ["sym": symbolText]) {
            setXattrData(data, named: "com.apple.icon.folder#S", at: path)
        }

        removeBadgeAppFolderMetadata(at: path)
        removeBadgeAppBadgeState(at: path)
        removeBadgeAppBackupID(at: path)
        NSWorkspace.shared.noteFileSystemChanged(path)
        NSWorkspace.shared.noteFileSystemChanged((path as NSString).deletingLastPathComponent)

        return true
    }

    private func restoreFolderVisualCustomizationXattrs(_ xattrs: [String: Data]?, to path: String) {
        guard let xattrs else { return }

        for (name, data) in xattrs {
            data.withUnsafeBytes { buffer in
                guard let baseAddress = buffer.baseAddress else { return }

                path.withCString { pathPointer in
                    name.withCString { namePointer in
                        _ = setxattr(pathPointer, namePointer, baseAddress, buffer.count, 0, 0)
                    }
                }
            }
        }
    }

    private func xattrNames(at path: String) -> [String] {
        let size = path.withCString { pathPointer in
            listxattr(pathPointer, nil, 0, 0)
        }
        guard size > 0 else { return [] }

        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { buffer in
            path.withCString { pathPointer in
                listxattr(pathPointer, buffer.baseAddress, size, 0)
            }
        }
        guard result > 0 else { return [] }

        return data
            .split(separator: 0)
            .compactMap { String(data: Data($0), encoding: .utf8) }
    }

    private func xattrData(named name: String, at path: String) -> Data? {
        let size = path.withCString { pathPointer in
            name.withCString { namePointer in
                getxattr(pathPointer, namePointer, nil, 0, 0, 0)
            }
        }
        guard size > 0 else { return nil }

        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { buffer in
            path.withCString { pathPointer in
                name.withCString { namePointer in
                    getxattr(pathPointer, namePointer, buffer.baseAddress, size, 0, 0)
                }
            }
        }

        return result > 0 ? data : nil
    }

    private func setXattrData(_ data: Data, named name: String, at path: String) {
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }

            path.withCString { pathPointer in
                name.withCString { namePointer in
                    _ = setxattr(pathPointer, namePointer, baseAddress, buffer.count, 0, 0)
                }
            }
        }
    }

    func deleteCustomBadge(at index: Int) {
        guard index < customBadges.count else {
            return
        }

        let badge = customBadges[index]

        guard customBadgeStore.deleteBadge(badge) else {
            return
        }

        customBadges.remove(at: index)
    }

    func setupUI() {
        let controlsPanel = NSView()
        controlsPanel.translatesAutoresizingMaskIntoConstraints = false
        controlsPanel.wantsLayer = true
        controlsPanel.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(controlsPanel)

        let badgeSectionLabel = NSTextField(labelWithString: "Badge")
        badgeSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeSectionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeSectionLabel.textColor = .secondaryLabelColor
        controlsPanel.addSubview(badgeSectionLabel)

        let badgeButton = NSButton(title: "Badge", image: appDelegate.selectedBadge ?? NSImage(), target: self, action: #selector(selectBadge))
        badgeButton.translatesAutoresizingMaskIntoConstraints = false
        badgeButton.bezelStyle = .rounded
        badgeButton.imagePosition = .imageLeft
        badgeButton.tag = 100
        controlsPanel.addSubview(badgeButton)

        let sizeLabel = NSTextField(labelWithString: "Tamaño:")
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsPanel.addSubview(sizeLabel)

        let sizeField = NSTextField(frame: NSRect(x: 0, y: 0, width: 50, height: 24))
        sizeField.translatesAutoresizingMaskIntoConstraints = false
        sizeField.stringValue = "\(Int(appDelegate.badgeSize))"
        let formatter = NumberFormatter()
        formatter.minimum = 5
        formatter.maximum = 64
        sizeField.formatter = formatter
        sizeField.tag = 201
        sizeField.target = self
        sizeField.action = #selector(changeBadgeSizeField(_:))
        sizeField.delegate = self
        sizeField.isEditable = true
        sizeField.isBezeled = true
        controlsPanel.addSubview(sizeField)

        let applyButton = NSButton(title: "Aplicar", target: self, action: #selector(applyBadge))
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.bezelStyle = .rounded
        controlsPanel.addSubview(applyButton)

        let removeButton = NSButton(title: "Eliminar Aplicado", target: self, action: #selector(removeBadge))
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.bezelStyle = .rounded
        controlsPanel.addSubview(removeButton)

        let previewSectionLabel = NSTextField(labelWithString: "Previsualización")
        previewSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        previewSectionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        previewSectionLabel.textColor = .secondaryLabelColor
        controlsPanel.addSubview(previewSectionLabel)

        let previewButton = NSButton(title: "Previsualizar", target: self, action: #selector(previewBadge))
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.bezelStyle = .rounded
        controlsPanel.addSubview(previewButton)

        let removePreviewButton = NSButton(title: "Quitar Preview", target: self, action: #selector(removePreviewBadge))
        removePreviewButton.translatesAutoresizingMaskIntoConstraints = false
        removePreviewButton.bezelStyle = .rounded
        controlsPanel.addSubview(removePreviewButton)

        let librarySectionLabel = NSTextField(labelWithString: "Biblioteca")
        librarySectionLabel.translatesAutoresizingMaskIntoConstraints = false
        librarySectionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        librarySectionLabel.textColor = .secondaryLabelColor
        controlsPanel.addSubview(librarySectionLabel)

        let addBadgeButton = NSButton(title: "Añadir Badge", target: self, action: #selector(addBadgeClicked))
        addBadgeButton.translatesAutoresizingMaskIntoConstraints = false
        addBadgeButton.bezelStyle = .rounded
        controlsPanel.addSubview(addBadgeButton)

        let deleteBadgeButton = NSButton(title: "Eliminar Custom", target: self, action: #selector(deleteBadgeClicked))
        deleteBadgeButton.translatesAutoresizingMaskIntoConstraints = false
        deleteBadgeButton.bezelStyle = .rounded
        controlsPanel.addSubview(deleteBadgeButton)

        let messageView = NSView()
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.wantsLayer = true
        messageView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
        messageView.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.62).cgColor
        messageView.layer?.borderWidth = 1
        messageView.layer?.cornerRadius = 12
        messageView.isHidden = true
        controlsPanel.addSubview(messageView)
        previewMessageView = messageView

        let messageLabel = NSTextField(labelWithString: "Coloca el badge\ndonde desees.\nArrastralo sobre\nla previsualizacion.")
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        messageLabel.textColor = .white
        messageLabel.alignment = .center
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.maximumNumberOfLines = 0
        messageView.addSubview(messageLabel)
        previewMessageLabel = messageLabel

        dropZoneView = DropZoneView()
        dropZoneView.translatesAutoresizingMaskIntoConstraints = false
        dropZoneView.viewController = self
        view.addSubview(dropZoneView)

        NSLayoutConstraint.activate([
            controlsPanel.topAnchor.constraint(equalTo: view.topAnchor),
            controlsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsPanel.widthAnchor.constraint(equalToConstant: 250),

            badgeSectionLabel.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            badgeSectionLabel.topAnchor.constraint(equalTo: controlsPanel.topAnchor, constant: 46),

            badgeButton.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            badgeButton.topAnchor.constraint(equalTo: badgeSectionLabel.bottomAnchor, constant: 12),
            badgeButton.widthAnchor.constraint(equalToConstant: 105),

            sizeLabel.leadingAnchor.constraint(equalTo: badgeButton.trailingAnchor, constant: 14),
            sizeLabel.centerYAnchor.constraint(equalTo: badgeButton.centerYAnchor),

            sizeField.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 8),
            sizeField.centerYAnchor.constraint(equalTo: badgeButton.centerYAnchor),
            sizeField.widthAnchor.constraint(equalToConstant: 44),

            applyButton.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            applyButton.topAnchor.constraint(equalTo: badgeButton.bottomAnchor, constant: 24),
            applyButton.widthAnchor.constraint(equalToConstant: 92),

            removeButton.leadingAnchor.constraint(equalTo: applyButton.trailingAnchor, constant: 12),
            removeButton.centerYAnchor.constraint(equalTo: applyButton.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 128),

            previewSectionLabel.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            previewSectionLabel.topAnchor.constraint(equalTo: applyButton.bottomAnchor, constant: 56),

            previewButton.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            previewButton.topAnchor.constraint(equalTo: previewSectionLabel.bottomAnchor, constant: 12),
            previewButton.widthAnchor.constraint(equalToConstant: 104),

            removePreviewButton.leadingAnchor.constraint(equalTo: previewButton.trailingAnchor, constant: 10),
            removePreviewButton.centerYAnchor.constraint(equalTo: previewButton.centerYAnchor),
            removePreviewButton.widthAnchor.constraint(equalToConstant: 112),

            librarySectionLabel.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            librarySectionLabel.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 56),

            addBadgeButton.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            addBadgeButton.topAnchor.constraint(equalTo: librarySectionLabel.bottomAnchor, constant: 12),
            addBadgeButton.widthAnchor.constraint(equalToConstant: 104),

            deleteBadgeButton.leadingAnchor.constraint(equalTo: addBadgeButton.trailingAnchor, constant: 8),
            deleteBadgeButton.centerYAnchor.constraint(equalTo: addBadgeButton.centerYAnchor),
            deleteBadgeButton.widthAnchor.constraint(equalToConstant: 112),

            messageView.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 18),
            messageView.trailingAnchor.constraint(equalTo: controlsPanel.trailingAnchor, constant: -18),
            messageView.topAnchor.constraint(equalTo: addBadgeButton.bottomAnchor, constant: 34),
            messageView.heightAnchor.constraint(equalToConstant: 210),

            messageLabel.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(greaterThanOrEqualTo: messageView.topAnchor, constant: 18),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: messageView.bottomAnchor, constant: -18),
            messageLabel.centerYAnchor.constraint(equalTo: messageView.centerYAnchor),

            dropZoneView.topAnchor.constraint(equalTo: view.topAnchor),
            dropZoneView.leadingAnchor.constraint(equalTo: controlsPanel.trailingAnchor),
            dropZoneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropZoneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func selectBadge() {
        let alert = NSAlert()
        alert.messageText = "Seleccionar Badge"
        alert.informativeText = "Elige un icono del sistema o personalizado"

        var icons: [(name: NSImage.Name, label: String, isCustom: Bool, path: String?)] = [
            (NSImage.folderName, "Carpeta", false, nil),
            (NSImage.homeTemplateName, "Home", false, nil),
            (NSImage.trashFullName, "Papelera", false, nil),
            (NSImage.infoName, "Info", false, nil),
            (NSImage.cautionName, "Advertencia", false, nil),
            (NSImage.stopProgressFreestandingTemplateName, "Stop", false, nil),
            (NSImage.refreshTemplateName, "Refresh", false, nil)
        ]

        for custom in customBadges {
            icons.append((name: custom.name, label: custom.label, isCustom: true, path: custom.path))
        }

        let accessory = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        for (_, label, _, _) in icons {
            accessory.addItem(withTitle: label)
        }
        alert.accessoryView = accessory

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancelar")

        if alert.runModal() == .alertFirstButtonReturn {
            let idx = accessory.indexOfSelectedItem
            let selected = icons[idx]
            if selected.isCustom, let path = selected.path {
                appDelegate.selectedBadge = NSImage(contentsOfFile: path)
            } else {
                appDelegate.selectedBadge = NSImage(named: selected.name)
            }
            if let button = view.viewWithTag(100) as? NSButton {
                button.image = appDelegate.selectedBadge
            }
            invalidatePreviewCaches()
            dropZoneView.needsDisplay = true
        }
    }

    @objc func addBadgeClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Seleccionar imagen para badge"

        panel.allowedContentTypes = [.png, .jpeg, .gif]

        guard let window = view.window else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK,
                  let self,
                  let url = panel.url,
                  let image = NSImage(contentsOf: url) else {
                return
            }

            let name = url.deletingPathExtension().lastPathComponent
            _ = self.saveCustomBadge(image: image, name: name)
            self.dropZoneView.needsDisplay = true
        }
    }

    @objc func deleteBadgeClicked() {
        if customBadges.isEmpty {
            let info = NSAlert()
            info.messageText = "No hay badges personalizados"
            info.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Eliminar Badge Personalizado"

        let accessory = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        for custom in customBadges {
            accessory.addItem(withTitle: custom.label)
        }
        alert.accessoryView = accessory

        alert.addButton(withTitle: "Eliminar")
        alert.addButton(withTitle: "Cancelar")

        if alert.runModal() == .alertFirstButtonReturn {
            let idx = accessory.indexOfSelectedItem
            deleteCustomBadge(at: idx)
            dropZoneView.needsDisplay = true
        }
    }

    @objc func changeBadgeSizeField(_ sender: NSTextField) {
        if let value = Int(sender.stringValue), value >= 5 && value <= 64 {
            updateBadgeSize(to: CGFloat(value))
        } else {
            sender.stringValue = "\(Int(appDelegate.badgeSize))"
        }
    }

    private func updateBadgeSize(to newSize: CGFloat) {
        let badgeCenter = items.last.flatMap { item -> NSPoint? in
            guard item.showsBadgePreview else { return nil }
            return previewBadgeGeometry(for: item).map {
                NSPoint(x: $0.visibleRect.midX, y: $0.visibleRect.midY)
            }
        }

        appDelegate.badgeSize = newSize

        if let item = items.last, let badgeCenter {
            placePreviewBadgeVisibleCenter(badgeCenter, for: item)
        } else {
            invalidatePreviewCaches()
            dropZoneView.needsDisplay = true
        }

        if let sizeField = view.viewWithTag(201) as? NSTextField {
            sizeField.stringValue = "\(Int(appDelegate.badgeSize))"
        }

        dropZoneView.needsDisplay = true
        dropZoneView.displayIfNeeded()
        view.window?.makeFirstResponder(dropZoneView)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let sizeField = obj.object as? NSTextField,
              sizeField.tag == 201 else { return }

        changeBadgeSizeField(sizeField)
    }

    @objc func moveBadgeLeft() {
        badgeOffsetX -= 2
        invalidatePreviewCaches()
        dropZoneView.needsDisplay = true
    }

    @objc func moveBadgeRight() {
        badgeOffsetX += 2
        invalidatePreviewCaches()
        dropZoneView.needsDisplay = true
    }

    @objc func moveBadgeUp() {
        badgeOffsetY += 2
        invalidatePreviewCaches()
        dropZoneView.needsDisplay = true
    }

    @objc func moveBadgeDown() {
        badgeOffsetY -= 2
        invalidatePreviewCaches()
        dropZoneView.needsDisplay = true
    }

    @objc func clearAll() {
        items.removeAll()
        dropZoneView.needsDisplay = true
    }

    @objc func previewBadge() {
        guard let item = items.last else { return }

        item.showsBadgePreview = true
        item.cachedPreviewIcon = nil
        item.cachedPreviewKey = nil
        dropZoneView.needsDisplay = true

        showPreviewMessage(previewMessage(for: item))
    }

    @objc func removePreviewBadge() {
        guard let item = items.last else { return }

        item.showsBadgePreview = false
        item.cachedPreviewIcon = nil
        item.cachedPreviewKey = nil
        dropZoneView.needsDisplay = true
        showPreviewMessage("Preview quitada.\nSe muestra de nuevo\nel estado real.")
    }

    private func previewMessage(for item: DroppedItem) -> String {
        switch item.badgeStatus {
        case .none:
            return "Coloca el badge\ndonde desees.\nArrastralo sobre\nla previsualizacion."
        case .badgeAppEditable:
            return "Badge aplicado\ndetectado.\nPuedes moverlo o\ncambiarlo aqui."
        case .badgeAppAppliedNotEditable:
            return "Badge aplicado\ndetectado.\nSe previsualiza uno\nnuevo encima."
        case .externalCustomIcon:
            return "Icono personalizado\ndetectado.\nLa preview anade\nun badge encima."
        }
    }

    private func loadMessage(for item: DroppedItem) -> String {
        switch item.badgeStatus {
        case .none:
            return "Elemento cargado.\nPulsa Previsualizar\npara anadir un badge."
        case .badgeAppEditable:
            return "Badge de BadgeApp\ndetectado.\nSe muestra el estado\nreal del elemento."
        case .badgeAppAppliedNotEditable:
            return "Badge aplicado\ndetectado.\nNo se puede separar\ndel icono actual."
        case .externalCustomIcon:
            return "Icono personalizado\ndetectado.\nSe usa como base\nde trabajo."
        }
    }

    private func showPreviewMessage(_ message: String) {
        previewMessageTimer?.invalidate()
        previewMessageLabel?.stringValue = message
        previewMessageView?.alphaValue = 1
        previewMessageView?.isHidden = false

        previewMessageTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                self?.previewMessageView?.animator().alphaValue = 0
            } completionHandler: {
                self?.previewMessageView?.isHidden = true
                self?.previewMessageView?.alphaValue = 1
            }
        }
    }

    private func invalidatePreviewCaches() {
        for item in items {
            item.cachedPreviewIcon = nil
            item.cachedPreviewKey = nil
        }
    }

    func addItem(path: String) {
        items.removeAll()
        isPreviewSelected = false

        let item = DroppedItem(path: path)
        item.showsBadgePreview = false
        items.append(item)
        dropZoneView.needsDisplay = true

        metadataQueue.async { [weak self, weak item] in
            guard let self else { return }

            let isDirectory = self.isDirectory(at: path)
            let colorInfo = isDirectory ? self.folderCustomizationColorInfo(at: path) : nil
            let symbolInfo = isDirectory ? self.folderSymbolInfo(at: path) : FolderSymbolInfo(systemName: nil, text: nil)
            let badgeState = self.badgeAppBadgeState(at: path)
            let hasAppBadge = self.hasBadgeAppliedByBadgeApp(at: path)
            let hasCustomIcon = self.hasCustomFinderIcon(at: path)
            let hasVisualCustomization = isDirectory && self.hasFolderVisualCustomization(at: path)
            let baseIcon = self.backedUpIcon(for: path)
            let badgeStatus = self.badgeStatus(
                badgeState: badgeState,
                hasAppBadge: hasAppBadge,
                hasCustomIcon: hasCustomIcon,
                hasVisualCustomization: hasVisualCustomization,
                hasCleanBaseIcon: baseIcon != nil
            )

            DispatchQueue.main.async {
                guard let item else { return }
                guard self.items.contains(where: { $0 === item }) else { return }

                if let badgeState, baseIcon != nil {
                    self.appDelegate.badgeSize = CGFloat(badgeState.badgeSize)
                    self.badgeOffsetX = CGFloat(badgeState.badgeOffsetX)
                    self.badgeOffsetY = CGFloat(badgeState.badgeOffsetY)
                    if let sizeField = self.view.viewWithTag(201) as? NSTextField {
                        sizeField.stringValue = "\(Int(self.appDelegate.badgeSize))"
                    }
                }

                item.badgeStatus = badgeStatus
                item.baseIconForPreview = baseIcon
                item.folderColorName = colorInfo?.name
                item.folderColor = colorInfo?.color
                item.folderSymbolName = symbolInfo.systemName
                item.folderSymbolText = symbolInfo.text
                item.cachedPreviewIcon = nil
                item.cachedPreviewKey = nil
                print("Folder color for \(path): \(colorInfo?.name ?? "none")")
                self.dropZoneView.needsDisplay = true
                self.showPreviewMessage(self.loadMessage(for: item))
            }

            self.iconForPreviewingBadge(to: path) { [weak self, weak item] previewIcon, shouldShowBadgePreview in
                DispatchQueue.main.async {
                    guard let self, let item else { return }
                    guard self.items.contains(where: { $0 === item }) else { return }

                    item.icon = previewIcon
                    item.showsBadgePreview = shouldShowBadgePreview
                    item.cachedPreviewIcon = nil
                    item.cachedPreviewKey = nil
                    self.dropZoneView.needsDisplay = true
                }
            }
        }
    }

    func removeSelectedPreviewItem() {
        guard isPreviewSelected else { return }

        items.removeAll()
        isPreviewSelected = false
        dropZoneView.needsDisplay = true
    }

    @objc func applyBadge() {
        guard let badge = appDelegate.selectedBadge else { return }
        guard shouldApplyBadgeOverCustomIcons() else { return }

        let badgeSize = NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize)

        for item in items {
            saveOriginalIconStateIfNeeded(for: item.path)

            if isDirectory(at: item.path) {
                let newIcon = customRenderedFolderIcon(for: item, badge: badge) ??
                    makeBadgedIcon(originalIcon: item.icon, badge: badge, badgeSize: badgeSize)
                resetFolderToPlainIconBeforeApplying(at: item.path)

                DispatchQueue.main.asyncAfter(deadline: .now() + folderResetDelay) { [weak self, weak item] in
                    guard let self,
                          let item,
                          self.items.contains(where: { $0 === item }) else { return }

                    if self.writeBadgedIcon(newIcon, to: item, restoreOriginalOnFailure: true) {
                        item.icon = self.customRenderedFolderPreview(for: item) ?? item.icon
                        item.showsBadgePreview = true
                    } else {
                        self.showIconApplyError(for: item.path)
                    }
                    self.dropZoneView.needsDisplay = true
                }
                continue
            }

            iconForApplyingBadge(to: item.path) { [weak self] originalIcon in
                DispatchQueue.main.async {
                    guard let self else { return }

                    let newIcon = self.makeBadgedIcon(originalIcon: originalIcon, badge: badge, badgeSize: badgeSize)
                    if self.applyBadgedIcon(newIcon, to: item) {
                        item.icon = originalIcon
                        item.showsBadgePreview = true
                    } else {
                        self.showIconApplyError(for: item.path)
                    }
                    self.dropZoneView.needsDisplay = true
                }
            }
        }
    }

    private func applyBadgedIcon(_ icon: NSImage, to item: DroppedItem) -> Bool {
        let path = item.path
        let backupRecord = iconBackupRecord(for: path)
        let needsClearBeforeApplying = hasCustomFinderIcon(at: path) || backupRecord?.hadCustomIcon == true
        let needsVisualCustomizationClear = hasFolderVisualCustomization(at: path) || backupRecord?.visualCustomizationXattrs?.isEmpty == false

        if needsClearBeforeApplying {
            _ = NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
            NSWorkspace.shared.noteFileSystemChanged(path)
        }

        if needsVisualCustomizationClear {
            removeFolderVisualCustomizationXattrs(at: path)
            NSWorkspace.shared.noteFileSystemChanged(path)
        }

        return writeBadgedIcon(
            icon,
            to: item,
            restoreOriginalOnFailure: needsClearBeforeApplying || needsVisualCustomizationClear
        )
    }

    private func writeBadgedIcon(_ icon: NSImage, to item: DroppedItem, restoreOriginalOnFailure: Bool) -> Bool {
        let path = item.path
        let url = URL(fileURLWithPath: path)
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let didApply = NSWorkspace.shared.setIcon(icon, forFile: path, options: [])
        if didApply {
            forceFinderCustomIconState(at: path)
            writeBadgeAppFolderMetadata(for: item)
            writeBadgeAppBadgeState(at: path)
        }
        NSWorkspace.shared.noteFileSystemChanged(path)
        NSWorkspace.shared.noteFileSystemChanged((path as NSString).deletingLastPathComponent)

        if !didApply, restoreOriginalOnFailure {
            _ = restoreOriginalIconStateIfAvailable(for: path)
        }

        return didApply
    }

    private func showIconApplyError(for path: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "No se pudo aplicar el badge"
        alert.informativeText = "macOS no ha permitido cambiar el icono de:\n\((path as NSString).lastPathComponent)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func shouldApplyBadgeOverCustomIcons() -> Bool {
        let itemsWithCustomIcon = items.filter {
            hasCustomFinderIcon(at: $0.path) || hasFolderVisualCustomization(at: $0.path)
        }
        guard !itemsWithCustomIcon.isEmpty else { return true }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Aplicar badge sobre carpetas personalizadas"

        let names = itemsWithCustomIcon
            .prefix(5)
            .map { ($0.path as NSString).lastPathComponent }
            .joined(separator: "\n")
        let remainingCount = itemsWithCustomIcon.count - min(itemsWithCustomIcon.count, 5)
        let remainingText = remainingCount > 0 ? "\n...y \(remainingCount) más" : ""

        alert.informativeText = """
        Algunos elementos ya tienen color, etiqueta o icono personalizado de macOS.

        Para poder añadir badge y conservar el color, la app generará una carpeta propia inspirada en la de macOS. Puede verse algo diferente a la carpeta nativa del sistema.

        La app guardará una copia del estado actual y podrás restaurarlo con "Eliminar Badge".

        \(names)\(remainingText)
        """
        alert.addButton(withTitle: "Aplicar Badge")
        alert.addButton(withTitle: "Cancelar")

        return alert.runModal() == .alertFirstButtonReturn
    }

    private func iconForPreviewingBadge(to path: String, completion: @escaping (NSImage, Bool) -> Void) {
        let isDirectory = isDirectory(at: path)
        let fallbackIcon = NSWorkspace.shared.icon(forFile: path)
        let hasAppBadge = hasBadgeAppliedByBadgeApp(at: path)

        if hasAppBadge {
            completion(fallbackIcon, false)
            return
        }

        if hasCustomFinderIcon(at: path) {
            completion(fallbackIcon, false)
            return
        }

        if isDirectory {
            completion(fallbackIcon, false)
            return
        }

        quickLookIcon(for: path, fallbackIcon: fallbackIcon) { icon in
            completion(icon, false)
        }
    }

    private func iconForApplyingBadge(to path: String, completion: @escaping (NSImage) -> Void) {
        let url = URL(fileURLWithPath: path)
        let fallbackIcon = NSWorkspace.shared.icon(forFile: path)
        let hasAppBadge = hasBadgeAppliedByBadgeApp(at: path)

        if let backedUpIcon = backedUpIcon(for: path) {
            completion(backedUpIcon)
            return
        }

        if hasAppBadge, isDirectory(at: path) {
            completion(defaultFolderIcon())
            return
        }

        if hasAppBadge {
            quickLookIcon(for: path, fallbackIcon: fallbackIcon, completion: completion)
            return
        }

        if hasCustomFinderIcon(at: path) {
            completion(fallbackIcon)
            return
        }

        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            completion(fallbackIcon)
            return
        }

        quickLookIcon(for: path, fallbackIcon: fallbackIcon, completion: completion)
    }

    private func defaultFolderIcon() -> NSImage {
        NSWorkspace.shared.icon(for: UTType.folder)
    }

    private func quickLookIcon(for path: String, fallbackIcon: NSImage, completion: @escaping (NSImage) -> Void) {
        let url = URL(fileURLWithPath: path)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 1024, height: 1024),
            scale: 1.0,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, _ in
            completion(thumbnail?.nsImage ?? fallbackIcon)
        }
    }

    private func makeBadgedIcon(originalIcon: NSImage, badge: NSImage, badgeSize: NSSize) -> NSImage {
        badgeIconComposer.makeBadgedIcon(
            originalIcon: originalIcon,
            badge: badge,
            badgeSize: badgeSize,
            badgeOffset: NSPoint(x: badgeOffsetX, y: badgeOffsetY)
        )
    }

    @objc func removeBadge() {
        for item in items {
            let hadBadgeAppState = badgeAppBadgeState(at: item.path) != nil ||
                badgeAppFolderMetadata(at: item.path) != nil ||
                badgeAppBackupID(at: item.path) != nil

            if restoreOriginalIconStateIfAvailable(for: item.path) {
                refreshRestoredVisualState(for: item)
            } else if restoreBadgeAppFolderVisualStateIfAvailable(for: item.path) {
                refreshRestoredVisualState(for: item)
            } else if hadBadgeAppState {
                NSWorkspace.shared.setIcon(nil, forFile: item.path, options: [])
                NSWorkspace.shared.noteFileSystemChanged(item.path)
                removeBadgeAppFolderMetadata(at: item.path)
                removeBadgeAppBadgeState(at: item.path)
                removeBadgeAppBackupID(at: item.path)
                item.folderColorName = nil
                item.folderColor = nil
                item.folderSymbolName = nil
                item.folderSymbolText = nil
                item.icon = NSWorkspace.shared.icon(forFile: item.path)
                item.showsBadgePreview = true
                refreshCurrentVisualState(for: item, showsBadgePreview: false)
            } else {
                refreshCurrentVisualState(for: item)
            }
        }

        dropZoneView.needsDisplay = true
    }

    @objc func resetFoldersForTest() {
        for item in items where isDirectory(at: item.path) {
            saveOriginalIconStateIfNeeded(for: item.path)
            resetFolderToPlainIconBeforeApplying(at: item.path)
            item.icon = NSWorkspace.shared.icon(forFile: item.path)
        }

        dropZoneView.needsDisplay = true
    }
}
