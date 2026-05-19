//
//  BadgeItemLoadDependencies.swift
//  BadgeApp
//
//  Created by David Vilches on 19/05/2026.
//

import AppKit

struct BadgeItemLoadDependencies {
    let isDirectoryProvider: (String) -> Bool
    let colorInfoProvider: (String) -> (name: String, color: NSColor)?
    let symbolInfoProvider: (String) -> FolderSymbolInfo
    let badgeStateProvider: (String) -> BadgeAppBadgeState?
    let hasAppBadgeProvider: (String) -> Bool
    let hasCustomIconProvider: (String) -> Bool
    let hasVisualCustomizationProvider: (String) -> Bool
    let baseIconProvider: (String) -> NSImage?
}
