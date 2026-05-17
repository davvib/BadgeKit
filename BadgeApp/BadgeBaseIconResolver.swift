//
//  BadgeBaseIconResolver.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class BadgeBaseIconResolver {
    private let quickLookIconProvider: QuickLookIconProvider
    private let finderIconStateReader: FinderIconStateReader

    init(
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
}
