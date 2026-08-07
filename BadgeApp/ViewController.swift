import Cocoa
import Darwin
import QuickLookThumbnailing
import UniformTypeIdentifiers
import BadgeKit

class ViewController: NSViewController, NSTextFieldDelegate {
    weak var appDelegate: AppDelegate!
    var dropZoneView: DropZoneView!
    var items: [DroppedItem] = []
    var badgeOffsetX: CGFloat = 4
    var badgeOffsetY: CGFloat = -4
    var customBadges: [CustomBadgeRecord] = []
    var isPreviewSelected = false
    private let folderResetDelay: TimeInterval = 0.8
    private let metadataQueue = DispatchQueue(label: "com.badgeapp.metadata", qos: .userInitiated)
    private var previewMessageView: NSView?
    private var previewMessageLabel: NSTextField?
    private var previewMessageTimer: Timer?
    private let badgeImageNormalizer = BadgeImageNormalizer()
    private let customBadgeStore = CustomBadgeStore()
    private let iconBackupStore = IconBackupStore()
    private let iconBackupRetentionPolicy = IconBackupRetentionPolicy()
    private let badgeAppMetadataStore = BadgeAppMetadataStore()
    private let badgePreviewMessageProvider = BadgePreviewMessageProvider()
    private let previewCacheInvalidator = PreviewCacheInvalidator()
    private let xattrStore = XattrStore()
    private let finderIconFileStore = FinderIconFileStore()
    private let finderIconApplier = FinderIconApplier()
    private let fileIdentityResolver = FileIdentityResolver()
    private let quickLookIconProvider = QuickLookIconProvider()
    private let badgeItemVisualStateUpdater = BadgeItemVisualStateUpdater()
    private let badgeKitRenderer = BadgeKitRenderer()
    private let folderCustomizationPreparer = FolderCustomizationPreparer()
    private lazy var finderInfoStore = FinderInfoStore(xattrStore: xattrStore)
    
    private lazy var badgeItemLoadService = BadgeItemLoadService(
        dependencies: badgeItemLoadDependencies
    )
    
    private lazy var finderIconStateReader = FinderIconStateReader(
        finderInfoStore: finderInfoStore,
        finderIconFileStore: finderIconFileStore
    )
    
    private lazy var folderVisualCustomizationReader = FolderVisualCustomizationReader()
    
    private lazy var folderVisualCustomizationRestorer = FolderVisualCustomizationRestorer(
        xattrStore: xattrStore,
        reader: folderVisualCustomizationReader
    )
    
    private lazy var iconBackupService = IconBackupService(
        backupStore: iconBackupStore,
        retentionPolicy: iconBackupRetentionPolicy,
        fileIdentityResolver: fileIdentityResolver,
        finderInfoStore: finderInfoStore,
        finderIconApplier: finderIconApplier,
        visualCustomizationRestorer: folderVisualCustomizationRestorer
    )
    
    private lazy var badgeBaseIconResolver = BadgeBaseIconResolver(
        quickLookIconProvider: quickLookIconProvider,
        finderIconStateReader: finderIconStateReader
    )
    
    private lazy var badgeApplyService = BadgeApplyService(
        finderIconApplier: finderIconApplier,
        finderInfoStore: finderInfoStore,
        visualCustomizationRestorer: folderVisualCustomizationRestorer,
        iconBackupService: iconBackupService
    )
    
    private lazy var badgeRemovalService = BadgeRemovalService(
        finderIconApplier: finderIconApplier
    )
    
    private lazy var badgeAppMetadataRepository = BadgeAppMetadataRepository(
        metadataStore: badgeAppMetadataStore,
        xattrStore: xattrStore
    )
    
    private lazy var badgeItemLoadDependencies = BadgeItemLoadDependencies(
        isDirectoryProvider: { [weak self] path in
            self?.isDirectory(at: path) ?? false
        },
        colorInfoProvider: { [weak self] path in
            self?.folderCustomizationColorInfo(at: path)
        },
        symbolInfoProvider: { [weak self] path in
            self?.folderSymbolInfo(at: path) ?? FolderSymbolInfo(systemName: nil, text: nil)
        },
        badgeStateProvider: { [weak self] path in
            self?.badgeAppBadgeState(at: path)
        },
        hasAppBadgeProvider: { [weak self] path in
            self?.hasBadgeAppliedByBadgeApp(at: path) ?? false
        },
        hasCustomIconProvider: { [weak self] path in
            self?.hasCustomFinderIcon(at: path) ?? false
        },
        hasVisualCustomizationProvider: { [weak self] path in
            self?.hasFolderVisualCustomization(at: path) ?? false
        },
        baseIconProvider: { [weak self] path in
            self?.backedUpIcon(for: path)
        }
    )
    
    private lazy var folderAppearanceResolver = FolderAppearanceResolver(
        visualCustomizationReader: folderVisualCustomizationReader
    )

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

    private func backedUpIcon(for path: String) -> NSImage? {
        guard shouldUseBackedUpIcon(for: path),
              let record = iconBackupRecord(for: path) else {
            return nil
        }

        return iconBackupStore.previewOrOriginalIcon(for: record)
    }

    private func shouldUseBackedUpIcon(for path: String) -> Bool {
        finderIconStateReader.hasCustomVisualState(at: path) ||
        hasFolderVisualCustomization(at: path)
    }

    private func folderCustomizationColorInfo(at path: String) -> (name: String, color: NSColor)? {
        let metadata = badgeAppFolderMetadata(at: path).map {
            FolderAppearanceMetadata(
                colorName: $0.colorName,
                symbolName: $0.symbolName,
                symbolText: $0.symbolText
            )
        }

        return folderAppearanceResolver.colorInfo(
            at: path,
            folderMetadata: metadata,
            backupVisualCustomizationXattrs: iconBackupRecord(for: path)?.visualCustomizationXattrs,
            xattrDataProvider: { [weak self] name, path in
                self?.xattrData(named: name, at: path)
            }
        )
    }

    private func folderSymbolInfo(at path: String) -> FolderSymbolInfo {
        folderAppearanceResolver.symbolInfo(
            at: path,
            backupVisualCustomizationXattrs: iconBackupRecord(for: path)?.visualCustomizationXattrs,
            xattrNamesProvider: { [weak self] path in
                self?.xattrNames(at: path) ?? []
            },
            xattrDataProvider: { [weak self] name, path in
                self?.xattrData(named: name, at: path)
            }
        )
    }

    private func customRenderedFolderIcon(for item: DroppedItem, badgeVisual: BadgeVisual? = nil) -> NSImage? {
        badgeKitRenderer.renderFolderIcon(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badgeVisual: badgeVisual,
            configuration: currentBadgeConfiguration
        )
    }

    private func customRenderedFolderPreview(for item: DroppedItem, badgeVisual: BadgeVisual? = nil) -> NSImage? {
        badgeKitRenderer.renderFolderPreview(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badgeVisual: badgeVisual,
            configuration: currentBadgeConfiguration
        )
    }

    private func customRenderedFolderIcon(for item: DroppedItem, badgeComposition: BadgeComposition?) -> NSImage? {
        badgeKitRenderer.renderFolderIcon(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badgeComposition: badgeComposition,
            configuration: currentBadgeConfiguration
        )
    }

    private func customRenderedFolderPreview(for item: DroppedItem, badgeComposition: BadgeComposition?) -> NSImage? {
        badgeKitRenderer.renderFolderPreview(
            colorName: item.folderColorName,
            fallbackColor: item.folderColor,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText,
            badgeComposition: badgeComposition,
            configuration: currentBadgeConfiguration
        )
    }

    func previewIcon(for item: DroppedItem) -> NSImage {
        guard item.showsBadgePreview else {
            return customRenderedFolderPreview(for: item) ?? item.icon
        }

        let baseIcon = item.baseIconForPreview ?? item.icon
        let previewKey: String

        if let badgeComposition = appDelegate.selectedBadgeComposition {
            previewKey = badgeKitRenderer.makePreviewCacheKey(
                baseIcon: baseIcon,
                badgeComposition: badgeComposition,
                configuration: currentBadgeConfiguration,
                folderColorName: item.folderColorName,
                folderSymbolName: item.folderSymbolName,
                folderSymbolText: item.folderSymbolText
            )
        } else if let badgeVisual = appDelegate.selectedBadgeVisual {
            previewKey = badgeKitRenderer.makePreviewCacheKey(
                baseIcon: baseIcon,
                badgeVisual: badgeVisual,
                configuration: currentBadgeConfiguration,
                folderColorName: item.folderColorName,
                folderSymbolName: item.folderSymbolName,
                folderSymbolText: item.folderSymbolText
            )
        } else {
            return customRenderedFolderPreview(for: item) ?? item.icon
        }

        if item.cachedPreviewKey == previewKey,
           let cachedPreviewIcon = item.cachedPreviewIcon {
            return cachedPreviewIcon
        }

        let previewIcon: NSImage

        if let badgeComposition = appDelegate.selectedBadgeComposition {
            previewIcon = item.isDirectory
                ? customRenderedFolderPreview(for: item, badgeComposition: badgeComposition) ?? item.icon
                : makeBadgedIcon(
                    originalIcon: baseIcon,
                    badgeComposition: badgeComposition,
                    badgeSize: currentBadgeConfiguration.size
                )
        } else if let badgeVisual = appDelegate.selectedBadgeVisual {
            previewIcon = badgeKitRenderer.renderPreviewIcon(
                baseIcon: baseIcon,
                folderColorName: item.folderColorName,
                folderColor: item.folderColor,
                folderSymbolName: item.folderSymbolName,
                folderSymbolText: item.folderSymbolText,
                badgeVisual: badgeVisual,
                configuration: currentBadgeConfiguration,
                fallbackRenderer: { [weak self] baseIcon, _, badgeSize in
                    guard let self else { return baseIcon }
                    return self.makeBadgedIcon(
                        originalIcon: baseIcon,
                        badgeVisual: badgeVisual,
                        badgeSize: badgeSize
                    )
                }
            )
        } else {
            previewIcon = customRenderedFolderPreview(for: item) ?? item.icon
        }

        item.cachedPreviewKey = previewKey
        item.cachedPreviewIcon = previewIcon

        return previewIcon
    }

    func previewBaseIcon(for item: DroppedItem) -> NSImage {
        if item.isDirectory {
            return customRenderedFolderPreview(for: item) ??
                item.baseIconForPreview ??
                item.icon
        }

        return item.baseIconForPreview ?? item.icon
    }

    func previewBadgeProxy(for item: DroppedItem) -> BadgeProxy? {
        let trimsArtworkWithoutShadow = item.isDirectory

        if let badgeComposition = appDelegate.selectedBadgeComposition {
            return badgeKitRenderer.renderBadgeProxy(
                badgeComposition: badgeComposition,
                trimsArtworkWithoutShadow: trimsArtworkWithoutShadow
            )
        }

        if let badgeVisual = appDelegate.selectedBadgeVisual {
            return badgeKitRenderer.renderBadgeProxy(
                badgeVisual: badgeVisual,
                trimsArtworkWithoutShadow: trimsArtworkWithoutShadow
            )
        }

        return nil
    }

    func previewBadgeGeometry(for item: DroppedItem) -> BadgeGeometry? {
        guard item.showsBadgePreview else {
            return nil
        }

        if let badgeComposition = appDelegate.selectedBadgeComposition {
            return badgeKitRenderer.badgeGeometry(
                isDirectory: item.isDirectory,
                folderColorName: item.folderColorName,
                baseIcon: item.baseIconForPreview ?? item.icon,
                badgeComposition: badgeComposition,
                configuration: currentBadgeConfiguration
            )
        }

        if let badgeVisual = appDelegate.selectedBadgeVisual {
            return badgeKitRenderer.badgeGeometry(
                isDirectory: item.isDirectory,
                folderColorName: item.folderColorName,
                baseIcon: item.baseIconForPreview ?? item.icon,
                badge: badgeVisual.artwork,
                configuration: currentBadgeConfiguration
            )
        }

        return nil
    }

    private func commitPreviewBadgeCenter(_ center: NSPoint, for item: DroppedItem) {
        let offset = badgeKitRenderer.badgeOffset(
            isDirectory: item.isDirectory,
            folderColorName: item.folderColorName,
            baseIcon: item.baseIconForPreview ?? item.icon,
            configuration: currentBadgeConfiguration,
            placingBadgeCenterAt: center
        )
        guard offset.x != badgeOffsetX || offset.y != badgeOffsetY else {
            return
        }

        badgeOffsetX = offset.x
        badgeOffsetY = offset.y
        badgeItemVisualStateUpdater.showPreview(for: item)
        dropZoneView.needsDisplay = true
    }

    func commitPreviewBadgeVisibleCenter(_ center: NSPoint, for item: DroppedItem) {
        guard appDelegate.selectedBadgeVisual != nil ||
            appDelegate.selectedBadgeComposition != nil else {
            commitPreviewBadgeCenter(center, for: item)
            return
        }

        let logicalCenter: CGPoint

        if let badgeComposition = appDelegate.selectedBadgeComposition {
            logicalCenter = badgeKitRenderer.logicalBadgeCenter(
                forVisibleCenter: center,
                isDirectory: item.isDirectory,
                baseIcon: item.baseIconForPreview ?? item.icon,
                badgeComposition: badgeComposition,
                configuration: currentBadgeConfiguration
            )
        } else if let badgeVisual = appDelegate.selectedBadgeVisual {
            logicalCenter = badgeKitRenderer.logicalBadgeCenter(
                forVisibleCenter: center,
                isDirectory: item.isDirectory,
                baseIcon: item.baseIconForPreview ?? item.icon,
                badge: badgeVisual.artwork,
                configuration: currentBadgeConfiguration
            )
        } else {
            logicalCenter = center
        }

        commitPreviewBadgeCenter(logicalCenter, for: item)
    }

    private func refreshRestoredVisualState(for item: DroppedItem) {
        refreshCurrentVisualState(for: item, showsBadgePreview: false)
    }

    private func refreshCurrentVisualState(for item: DroppedItem, showsBadgePreview: Bool? = nil) {
        let loadResult = badgeItemLoadService.loadResult(for: item.path)

        badgeItemLoadService.apply(
            loadResult,
            to: item,
            visualStateUpdater: badgeItemVisualStateUpdater
        )

        item.icon = customRenderedFolderPreview(for: item) ??
            badgeBaseIconResolver.fallbackIcon(for: item.path)

        badgeItemVisualStateUpdater.applyPreviewVisibility(showsBadgePreview, to: item)
    }

    private func saveOriginalIconStateIfNeeded(for path: String) {
        if iconBackupRecord(for: path) != nil {
            return
        }

        removeBadgeAppBackupID(at: path)

        iconBackupService.saveOriginalIconState(
            path: path,
            visualCustomizationXattrs: folderVisualCustomizationXattrs(at: path),
            hasCustomVisualState: finderIconStateReader.hasCustomVisualState(at: path),
            workspaceIcon: badgeBaseIconResolver.fallbackIcon(for: path)
        ) { [weak self] id, path in
            self?.writeBadgeAppBackupID(id, at: path)
        }
    }

    private func restoreOriginalIconStateIfAvailable(for path: String) -> Bool {
        iconBackupService.restoreOriginalIconStateIfAvailable(
            for: path,
            backupIDProvider: { [weak self] path in
                self?.badgeAppBackupID(at: path)
            },
            metadataCleaner: { [weak self] path in
                self?.removeBadgeAppFolderMetadata(at: path)
                self?.removeBadgeAppBadgeState(at: path)
                self?.removeBadgeAppBackupID(at: path)
            }
        )
    }

    private func cleanupStoredIconBackups() {
        iconBackupService.cleanupStoredBackups()
    }

    private func iconBackupRecord(for path: String) -> IconBackupRecord? {
        iconBackupService.record(for: path) { [weak self] path in
            self?.badgeAppBackupID(at: path)
        }
    }

    private func hasCustomFinderIcon(at path: String) -> Bool {
        finderIconStateReader.hasCustomFinderIcon(at: path)
    }
    
    private func hasFolderVisualCustomization(at path: String) -> Bool {
        folderVisualCustomizationReader.hasVisualCustomization(
            at: path,
            xattrNames: xattrNames(at: path)
        )
    }

    private func isDirectory(at path: String) -> Bool {
        (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func folderVisualCustomizationXattrs(at path: String) -> [String: Data] {
        folderAppearanceResolver.visualCustomizationXattrs(
            at: path,
            isDirectoryProvider: { [weak self] path in
                self?.isDirectory(at: path) ?? false
            },
            xattrNamesProvider: { [weak self] path in
                self?.xattrNames(at: path) ?? []
            },
            xattrDataProvider: { [weak self] name, path in
                self?.xattrData(named: name, at: path)
            }
        )
    }

    private func clearFinderCustomIconState(at path: String) {
        finderInfoStore.clearCustomIconState(at: path)
    }

    private func resetFolderToPlainIconBeforeApplying(at path: String) {
        folderCustomizationPreparer.prepareFolderForCustomIcon(at: path)
    }

    private func badgeAppFolderMetadata(at path: String) -> BadgeAppFolderMetadata? {
        badgeAppMetadataRepository.folderMetadata(at: path)
    }
    
    private func hasBadgeAppState(at path: String) -> Bool {
        badgeAppFolderMetadata(at: path) != nil ||
        badgeAppBadgeState(at: path) != nil ||
        badgeAppBackupID(at: path) != nil
    }

    private func badgeAppBadgeState(at path: String) -> BadgeAppBadgeState? {
        badgeAppMetadataRepository.badgeState(at: path)
    }

    private func badgeAppBackupID(at path: String) -> String? {
        badgeAppMetadataRepository.backupID(at: path)
    }

    private func hasBadgeAppliedByBadgeApp(at path: String) -> Bool {
        badgeAppBadgeState(at: path) != nil ||
        (iconBackupRecord(for: path) != nil && hasCustomFinderIcon(at: path))
    }

    private func writeBadgeAppBadgeState(at path: String) {
        badgeAppMetadataRepository.writeBadgeState(
            at: path,
            badgeSize: Double(appDelegate.badgeSize),
            badgeOffsetX: Double(badgeOffsetX),
            badgeOffsetY: Double(badgeOffsetY)
        )
    }

    private func removeBadgeAppBadgeState(at path: String) {
        badgeAppMetadataRepository.removeBadgeState(at: path)
    }

    private func writeBadgeAppBackupID(_ id: String, at path: String) {
        badgeAppMetadataRepository.writeBackupID(id, at: path)
    }

    private func removeBadgeAppBackupID(at path: String) {
        badgeAppMetadataRepository.removeBackupID(at: path)
    }

    private func writeBadgeAppFolderMetadata(for item: DroppedItem) {
        guard isDirectory(at: item.path) else {
            return
        }

        badgeAppMetadataRepository.writeFolderMetadata(
            at: item.path,
            colorName: item.folderColorName,
            symbolName: item.folderSymbolName,
            symbolText: item.folderSymbolText
        )
    }

    private func removeBadgeAppFolderMetadata(at path: String) {
        badgeAppMetadataRepository.removeFolderMetadata(at: path)
    }

    private func restoreBadgeAppFolderVisualStateIfAvailable(for path: String) -> Bool {
        guard let metadata = badgeAppFolderMetadata(at: path),
              metadata.colorName != nil || metadata.symbolName != nil || metadata.symbolText != nil else {
            return false
        }

        _ = finderIconApplier.clearIcon(at: path)
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
        finderIconApplier.notifyFileAndParentChanged(at: path)

        return true
    }

    private func xattrNames(at path: String) -> [String] {
        xattrStore.names(at: path)
    }

    private func xattrData(named name: String, at path: String) -> Data? {
        xattrStore.data(named: name, at: path)
    }

    private func setXattrData(_ data: Data, named name: String, at path: String) {
        xattrStore.setData(data, named: name, at: path)
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

        var icons: [(name: NSImage.Name?, label: String, isCustom: Bool, path: String?, visual: BadgeVisual?, composition: BadgeComposition?)] = [
            (NSImage.folderName, "Carpeta", false, nil, nil, nil),
            (NSImage.homeTemplateName, "Home", false, nil, nil, nil),
            (NSImage.trashFullName, "Papelera", false, nil, nil, nil),
            (NSImage.infoName, "Info", false, nil, nil, nil),
            (NSImage.cautionName, "Advertencia", false, nil, nil, nil),
            (NSImage.stopProgressFreestandingTemplateName, "Stop", false, nil, nil, nil),
            (NSImage.refreshTemplateName, "Refresh", false, nil, nil, nil)
        ]

        if let pinVisual = BadgeBuiltInVisuals.pin {
            icons.append((nil, "Chincheta", false, nil, pinVisual, nil))
        }

        if let pinnedTagComposition = BadgeBuiltInCompositions.pinnedTag {
            icons.append((nil, "Etiqueta con chincheta", false, nil, nil, pinnedTagComposition))
        }

        for custom in customBadges {
            icons.append((name: custom.name, label: custom.label, isCustom: true, path: custom.path, visual: nil, composition: nil))
        }

        let accessory = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        for icon in icons {
            accessory.addItem(withTitle: icon.label)
        }
        alert.accessoryView = accessory

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancelar")

        if alert.runModal() == .alertFirstButtonReturn {
            let idx = accessory.indexOfSelectedItem
            let selected = icons[idx]
            if let visual = selected.visual {
                appDelegate.selectedBadgeVisual = visual
                appDelegate.selectedBadgeComposition = nil
            } else if let composition = selected.composition {
                appDelegate.selectedBadgeVisual = nil
                appDelegate.selectedBadgeComposition = composition
            } else if selected.isCustom, let path = selected.path {
                appDelegate.selectedBadge = NSImage(contentsOfFile: path)
            } else if let name = selected.name {
                appDelegate.selectedBadge = NSImage(named: name)
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
            commitPreviewBadgeVisibleCenter(badgeCenter, for: item)
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

        badgeItemVisualStateUpdater.showPreview(for: item)
        dropZoneView.needsDisplay = true

        showPreviewMessage(previewMessage(for: item))
    }

    @objc func removePreviewBadge() {
        guard let item = items.last else { return }

        badgeItemVisualStateUpdater.hidePreview(for: item)
        dropZoneView.needsDisplay = true
        showPreviewMessage("Preview quitada.\nSe muestra de nuevo\nel estado real.")
    }

    private func previewMessage(for item: DroppedItem) -> String {
        badgePreviewMessageProvider.previewMessage(for: item.badgeStatus)
    }

    private func loadMessage(for item: DroppedItem) -> String {
        badgePreviewMessageProvider.loadMessage(for: item.badgeStatus)
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
        previewCacheInvalidator.invalidate(items: items)
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

            let loadResult = self.badgeItemLoadService.loadResult(for: path)

            DispatchQueue.main.async {
                guard let item else { return }
                guard self.items.contains(where: { $0 === item }) else { return }

                if let badgeState = loadResult.badgeState,
                   loadResult.baseIconForPreview != nil {
                    self.appDelegate.badgeSize = CGFloat(badgeState.badgeSize)
                    self.badgeOffsetX = CGFloat(badgeState.badgeOffsetX)
                    self.badgeOffsetY = CGFloat(badgeState.badgeOffsetY)
                    if let sizeField = self.view.viewWithTag(201) as? NSTextField {
                        sizeField.stringValue = "\(Int(self.appDelegate.badgeSize))"
                    }
                }

                self.badgeItemLoadService.apply(
                    loadResult,
                    to: item,
                    visualStateUpdater: self.badgeItemVisualStateUpdater
                )
                
                print("Folder color for \(path): \(loadResult.colorName ?? "none")")
                self.dropZoneView.needsDisplay = true
                self.showPreviewMessage(self.loadMessage(for: item))
            }

            self.iconForPreviewingBadge(to: path) { [weak self, weak item] previewIcon, shouldShowBadgePreview in
                DispatchQueue.main.async {
                    guard let self, let item else { return }
                    guard self.items.contains(where: { $0 === item }) else { return }

                    item.icon = previewIcon
                    self.badgeItemVisualStateUpdater.setPreviewVisibility(
                        shouldShowBadgePreview,
                        for: item
                    )
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
        guard appDelegate.selectedBadgeVisual != nil ||
            appDelegate.selectedBadgeComposition != nil else { return }
        guard shouldApplyBadgeOverCustomIcons() else { return }

        let badgeSize = NSSize(width: appDelegate.badgeSize, height: appDelegate.badgeSize)

        for item in items {
            saveOriginalIconStateIfNeeded(for: item.path)

            if isDirectory(at: item.path) {
                if let badgeComposition = appDelegate.selectedBadgeComposition {
                    applyBadgeToFolder(
                        item: item,
                        badgeComposition: badgeComposition,
                        badgeSize: badgeSize
                    )
                } else if let badgeVisual = appDelegate.selectedBadgeVisual {
                    applyBadgeToFolder(
                        item: item,
                        badgeVisual: badgeVisual,
                        badgeSize: badgeSize
                    )
                }
                continue
            }

            if let badgeComposition = appDelegate.selectedBadgeComposition {
                applyBadgeToFile(
                    item: item,
                    badgeComposition: badgeComposition,
                    badgeSize: badgeSize
                )
            } else if let badgeVisual = appDelegate.selectedBadgeVisual {
                applyBadgeToFile(
                    item: item,
                    badgeVisual: badgeVisual,
                    badgeSize: badgeSize
                )
            }
        }
    }
    
    // MARK: - Helpers de applyBadge

    private func applyBadgeToFile(
        item: DroppedItem,
        badgeVisual: BadgeVisual,
        badgeSize: NSSize
    ) {
        iconForApplyingBadge(to: item.path) { [weak self] originalIcon in
            DispatchQueue.main.async {
                guard let self else { return }

                let newIcon = self.makeBadgedIcon(
                    originalIcon: originalIcon,
                    badgeVisual: badgeVisual,
                    badgeSize: badgeSize
                )

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

    private func applyBadgeToFile(
        item: DroppedItem,
        badgeComposition: BadgeComposition,
        badgeSize: NSSize
    ) {
        iconForApplyingBadge(to: item.path) { [weak self] originalIcon in
            DispatchQueue.main.async {
                guard let self else { return }

                let newIcon = self.makeBadgedIcon(
                    originalIcon: originalIcon,
                    badgeComposition: badgeComposition,
                    badgeSize: badgeSize
                )

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
    
    private func folderBadgedIcon(
        for item: DroppedItem,
        badgeVisual: BadgeVisual,
        badgeSize: NSSize
    ) -> NSImage {
        customRenderedFolderIcon(for: item, badgeVisual: badgeVisual) ??
            makeBadgedIcon(
                originalIcon: item.icon,
                badgeVisual: badgeVisual,
                badgeSize: badgeSize
            )
    }

    private func folderBadgedIcon(
        for item: DroppedItem,
        badgeComposition: BadgeComposition,
        badgeSize: NSSize
    ) -> NSImage {
        customRenderedFolderIcon(for: item, badgeComposition: badgeComposition) ??
            makeBadgedIcon(
                originalIcon: item.icon,
                badgeComposition: badgeComposition,
                badgeSize: badgeSize
            )
    }
    
    private func applyBadgeToFolder(
        item: DroppedItem,
        badgeVisual: BadgeVisual,
        badgeSize: NSSize
    ) {
        let newIcon = folderBadgedIcon(
            for: item,
            badgeVisual: badgeVisual,
            badgeSize: badgeSize
        )

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
    }

    private func applyBadgeToFolder(
        item: DroppedItem,
        badgeComposition: BadgeComposition,
        badgeSize: NSSize
    ) {
        let newIcon = folderBadgedIcon(
            for: item,
            badgeComposition: badgeComposition,
            badgeSize: badgeSize
        )

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
    }

    private func applyBadgedIcon(_ icon: NSImage, to item: DroppedItem) -> Bool {
        let path = item.path

        return badgeApplyService.applyBadgedIcon(
            icon,
            to: path,
            backupRecord: iconBackupRecord(for: path),
            hasCustomFinderIcon: hasCustomFinderIcon(at: path),
            hasFolderVisualCustomization: hasFolderVisualCustomization(at: path)
        ) { [weak self, weak item] icon, restoreOriginalOnFailure in
            guard let self, let item else { return false }

            return self.writeBadgedIcon(
                icon,
                to: item,
                restoreOriginalOnFailure: restoreOriginalOnFailure
            )
        }
    }

    private func writeBadgedIcon(_ icon: NSImage, to item: DroppedItem, restoreOriginalOnFailure: Bool) -> Bool {
        badgeApplyService.writeBadgedIcon(
            icon,
            to: item.path,
            restoreOriginalOnFailure: restoreOriginalOnFailure,
            metadataWriter: { [weak self, weak item] path in
                guard let self, let item else { return }

                self.writeBadgeAppFolderMetadata(for: item)
                self.writeBadgeAppBadgeState(at: path)
            },
            restoreOriginalIconState: { [weak self] path in
                self?.restoreOriginalIconStateIfAvailable(for: path) ?? false
            }
        )
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
        badgeBaseIconResolver.iconForPreviewingBadge(
            path: path,
            isDirectory: isDirectory(at: path),
            hasAppBadge: hasBadgeAppliedByBadgeApp(at: path),
            completion: completion
        )
    }

    private func iconForApplyingBadge(to path: String, completion: @escaping (NSImage) -> Void) {
        badgeBaseIconResolver.iconForApplyingBadge(
            path: path,
            isDirectory: isDirectory(at: path),
            hasAppBadge: hasBadgeAppliedByBadgeApp(at: path),
            backedUpIconProvider: { [weak self] path in
                self?.backedUpIcon(for: path)
            },
            completion: completion
        )
    }

    private func makeBadgedIcon(originalIcon: NSImage, badge: NSImage, badgeSize: NSSize) -> NSImage {
        makeBadgedIcon(
            originalIcon: originalIcon,
            badgeVisual: BadgeVisual(artwork: badge),
            badgeSize: badgeSize
        )
    }

    private func makeBadgedIcon(originalIcon: NSImage, badgeVisual: BadgeVisual, badgeSize: NSSize) -> NSImage {
        badgeKitRenderer.renderPreview(
            baseIcon: originalIcon,
            badgeVisual: badgeVisual,
            configuration: currentBadgeConfiguration
        )
    }

    private func makeBadgedIcon(originalIcon: NSImage, badgeComposition: BadgeComposition, badgeSize: NSSize) -> NSImage {
        badgeKitRenderer.renderPreview(
            baseIcon: originalIcon,
            badgeComposition: badgeComposition,
            configuration: currentBadgeConfiguration
        )
    }

    @objc func removeBadge() {
        for item in items {
            let hadBadgeAppState = hasBadgeAppState(at: item.path)

            let removalResult = badgeRemovalService.removeBadge(
                at: item.path,
                hasBadgeAppState: hadBadgeAppState,
                restoreOriginalIconState: { [weak self] path in
                    self?.restoreOriginalIconStateIfAvailable(for: path) ?? false
                },
                restoreBadgeAppFolderVisualState: { [weak self] path in
                    self?.restoreBadgeAppFolderVisualStateIfAvailable(for: path) ?? false
                },
                fallbackCleaner: { [weak self] path in
                    self?.badgeRemovalService.clearFallbackIconState(at: path)
                    self?.badgeRemovalService.cleanAppliedBadgeMetadata(
                        at: path,
                        folderMetadataRemover: { [weak self] path in
                            self?.removeBadgeAppFolderMetadata(at: path)
                        },
                        badgeStateRemover: { [weak self] path in
                            self?.removeBadgeAppBadgeState(at: path)
                        },
                        backupIDRemover: { [weak self] path in
                            self?.removeBadgeAppBackupID(at: path)
                        }
                    )
                }
            )

            switch removalResult {
            case .restoredOriginal:
                refreshRestoredVisualState(for: item)
                reloadPreviewIconAfterRemoval(for: item)

            case .restoredCustomVisualState:
                refreshRestoredVisualState(for: item)

            case .clearedFallbackIconState:
                item.folderColorName = nil
                item.folderColor = nil
                item.folderSymbolName = nil
                item.folderSymbolText = nil
                item.icon = badgeBaseIconResolver.fallbackIcon(for: item.path)
                item.showsBadgePreview = true
                refreshCurrentVisualState(for: item, showsBadgePreview: false)

            case .unchanged:
                refreshCurrentVisualState(for: item)
                reloadPreviewIconAfterRemoval(for: item)
                
            @unknown default:
                assertionFailure("Unhandled BadgeRemovalResult case")
                refreshCurrentVisualState(for: item)
            }
        }

        dropZoneView.needsDisplay = true
    }

    @objc func resetFoldersForTest() {
        for item in items where isDirectory(at: item.path) {
            saveOriginalIconStateIfNeeded(for: item.path)
            resetFolderToPlainIconBeforeApplying(at: item.path)
            item.icon = badgeBaseIconResolver.fallbackIcon(for: item.path)
        }

        dropZoneView.needsDisplay = true
    }
    
    private func reloadPreviewIconAfterRemoval(for item: DroppedItem) {
        iconForPreviewingBadge(to: item.path) { [weak self, weak item] previewIcon, shouldShowBadgePreview in
            DispatchQueue.main.async {
                guard let self, let item else { return }
                guard self.items.contains(where: { $0 === item }) else { return }

                item.icon = previewIcon
                self.badgeItemVisualStateUpdater.setPreviewVisibility(
                    shouldShowBadgePreview,
                    for: item
                )
                self.dropZoneView.needsDisplay = true
            }
        }
    }
    
    private var currentBadgeConfiguration: BadgeConfiguration {
        BadgeConfiguration(
            size: CGSize(
                width: appDelegate.badgeSize,
                height: appDelegate.badgeSize
            ),
            offset: CGPoint(
                x: badgeOffsetX,
                y: badgeOffsetY
            )
        )
    }
}
