//
//  FinderIconStateReader.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

public final class FinderIconStateReader {
    private let finderInfoStore: FinderInfoStore
    private let finderIconFileStore: FinderIconFileStore

    public init(
        finderInfoStore: FinderInfoStore,
        finderIconFileStore: FinderIconFileStore
    ) {
        self.finderInfoStore = finderInfoStore
        self.finderIconFileStore = finderIconFileStore
    }

    public func hasCustomFinderIcon(at path: String) -> Bool {
        finderInfoStore.hasCustomIcon(at: path)
    }

    public func hasFinderIconFile(at path: String) -> Bool {
        finderIconFileStore.folderIconFileExists(at: path)
    }
    
    public func hasCustomVisualState(at path: String) -> Bool {
        hasCustomFinderIcon(at: path) ||
        hasFinderIconFile(at: path)
    }
}
