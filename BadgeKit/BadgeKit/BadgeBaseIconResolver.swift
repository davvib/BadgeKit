//
//  BadgeBaseIconResolver.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

public final class BadgeBaseIconResolver {
    private let quickLookIconProvider: QuickLookIconProvider
    private let finderIconStateReader: FinderIconStateReader

    public init(
        quickLookIconProvider: QuickLookIconProvider,
        finderIconStateReader: FinderIconStateReader
    ) {
        self.quickLookIconProvider = quickLookIconProvider
        self.finderIconStateReader = finderIconStateReader
    }
    
    func defaultFolderIcon() -> NSImage {
        quickLookIconProvider.defaultFolderIcon()
    }
    
    func quickLookIcon(
        for path: String,
        fallbackIcon: NSImage,
        completion: @escaping (NSImage) -> Void
    ) {
        quickLookIconProvider.quickLookIcon(
            for: path,
            fallbackIcon: fallbackIcon,
            completion: completion
        )
    }
    
    func fallbackIcon(for path: String) -> NSImage {
        quickLookIconProvider.fallbackIcon(for: path)
    }
    
    func iconForPreviewingBadge(
        path: String,
        isDirectory: Bool,
        hasAppBadge: Bool,
        completion: @escaping (NSImage, Bool) -> Void
    ) {
        let fallbackIcon = fallbackIcon(for: path)

        if hasAppBadge {
            completion(fallbackIcon, false)
            return
        }

        if finderIconStateReader.hasCustomFinderIcon(at: path) {
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
    
    func iconForApplyingBadge(
        path: String,
        isDirectory: Bool,
        hasAppBadge: Bool,
        backedUpIconProvider: (String) -> NSImage?,
        completion: @escaping (NSImage) -> Void
    ) {
        let fallbackIcon = fallbackIcon(for: path)

        if let backedUpIcon = backedUpIconProvider(path) {
            completion(backedUpIcon)
            return
        }

        if hasAppBadge, isDirectory {
            completion(defaultFolderIcon())
            return
        }

        if hasAppBadge {
            quickLookIcon(for: path, fallbackIcon: fallbackIcon, completion: completion)
            return
        }

        if finderIconStateReader.hasCustomFinderIcon(at: path) {
            completion(fallbackIcon)
            return
        }

        if isDirectory {
            completion(fallbackIcon)
            return
        }

        quickLookIcon(for: path, fallbackIcon: fallbackIcon, completion: completion)
    }
}
