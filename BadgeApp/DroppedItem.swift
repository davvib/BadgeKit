import Cocoa

enum DroppedItemBadgeStatus {
    case none
    case badgeAppEditable
    case badgeAppAppliedNotEditable
    case externalCustomIcon
}

class DroppedItem {
    let path: String
    let isDirectory: Bool
    var icon: NSImage
    var baseIconForPreview: NSImage?
    var folderColorName: String?
    var folderColor: NSColor?
    var folderSymbolName: String?
    var folderSymbolText: String?
    var badgeStatus: DroppedItemBadgeStatus = .none
    var showsBadgePreview = true
    var cachedPreviewIcon: NSImage?
    var cachedPreviewKey: String?

    init(path: String) {
        self.path = path
        self.isDirectory = (try? URL(fileURLWithPath: path)
            .resourceValues(forKeys: [.isDirectoryKey])
            .isDirectory) == true
        self.icon = NSWorkspace.shared.icon(forFile: path)
    }
}
