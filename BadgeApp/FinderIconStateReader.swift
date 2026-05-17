//
//  FinderIconStateReader.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class FinderIconStateReader {
    private let finderInfoStore: FinderInfoStore
    private let finderIconFileStore: FinderIconFileStore

    init(
        finderInfoStore: FinderInfoStore,
        finderIconFileStore: FinderIconFileStore
    ) {
        self.finderInfoStore = finderInfoStore
        self.finderIconFileStore = finderIconFileStore
    }

    func hasCustomFinderIcon(at path: String) -> Bool {
        finderInfoStore.hasCustomIcon(at: path)
    }

    func hasFinderIconFile(at path: String) -> Bool {
        finderIconFileStore.folderIconFileExists(at: path)
    }
    
    func hasCustomVisualState(at path: String) -> Bool {
        hasCustomFinderIcon(at: path) ||
        hasFinderIconFile(at: path)
    }
}
