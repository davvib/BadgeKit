//
//  BadgeItemLoadService.swift
//  BadgeApp
//
//  Created by David Vilches on 19/05/2026.
//

import AppKit

final class BadgeItemLoadService {
    
    func makeLoadResult(
        path: String,
        isDirectory: Bool,
        colorInfo: (name: String, color: NSColor)?,
        symbolInfo: FolderSymbolInfo,
        badgeState: BadgeAppBadgeState?,
        hasAppBadge: Bool,
        hasCustomIcon: Bool,
        hasVisualCustomization: Bool,
        baseIcon: NSImage?
    ) -> BadgeItemLoadResult {
        let badgeStatus = buildBadgeStatus(
            badgeState: badgeState,
            hasAppBadge: hasAppBadge,
            hasCustomIcon: hasCustomIcon,
            hasVisualCustomization: hasVisualCustomization,
            hasCleanBaseIcon: baseIcon != nil
        )

        return BadgeItemLoadResult(
            isDirectory: isDirectory,
            colorName: colorInfo?.name,
            folderColor: colorInfo?.color,
            symbolName: symbolInfo.systemName,
            symbolText: symbolInfo.text,
            badgeState: badgeState,
            badgeStatus: badgeStatus,
            hasAppBadge: hasAppBadge,
            hasCustomIcon: hasCustomIcon,
            hasVisualCustomization: hasVisualCustomization,
            baseIconForPreview: baseIcon
        )
    }
    
    func buildBadgeStatus(
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
    
    func apply(
        _ loadResult: BadgeItemLoadResult,
        to item: DroppedItem,
        visualStateUpdater: BadgeItemVisualStateUpdater
    ) {
        item.badgeStatus = loadResult.badgeStatus
        item.baseIconForPreview = loadResult.baseIconForPreview

        item.folderColorName = loadResult.colorName
        item.folderColor = loadResult.folderColor

        item.folderSymbolName = loadResult.symbolName
        item.folderSymbolText = loadResult.symbolText

        visualStateUpdater.invalidatePreviewCache(for: item)
    }
    
    func loadResult(
        for path: String,
        isDirectoryProvider: (String) -> Bool,
        colorInfoProvider: (String) -> (name: String, color: NSColor)?,
        symbolInfoProvider: (String) -> FolderSymbolInfo,
        badgeStateProvider: (String) -> BadgeAppBadgeState?,
        hasAppBadgeProvider: (String) -> Bool,
        hasCustomIconProvider: (String) -> Bool,
        hasVisualCustomizationProvider: (String) -> Bool,
        baseIconProvider: (String) -> NSImage?
    ) -> BadgeItemLoadResult {
        let isDirectory = isDirectoryProvider(path)
        let colorInfo = isDirectory ? colorInfoProvider(path) : nil
        let symbolInfo = isDirectory
            ? symbolInfoProvider(path)
            : FolderSymbolInfo(systemName: nil, text: nil)
        let badgeState = badgeStateProvider(path)
        let hasAppBadge = hasAppBadgeProvider(path)
        let hasCustomIcon = hasCustomIconProvider(path)
        let hasVisualCustomization = isDirectory && hasVisualCustomizationProvider(path)
        let baseIcon = baseIconProvider(path)

        return makeLoadResult(
            path: path,
            isDirectory: isDirectory,
            colorInfo: colorInfo,
            symbolInfo: symbolInfo,
            badgeState: badgeState,
            hasAppBadge: hasAppBadge,
            hasCustomIcon: hasCustomIcon,
            hasVisualCustomization: hasVisualCustomization,
            baseIcon: baseIcon
        )
    }
}
