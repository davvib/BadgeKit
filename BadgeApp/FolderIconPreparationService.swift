//
//  FolderIconPreparationService.swift
//  BadgeApp
//
//  Created by David Vilches on 20/05/2026.
//

import Foundation

final class FolderIconPreparationService {
    private let visualCustomizationRestorer: FolderVisualCustomizationRestorer
    private let finderIconApplier: FinderIconApplier
    private let finderIconFileStore: FinderIconFileStore
    private let finderInfoStore: FinderInfoStore

    init(
        visualCustomizationRestorer: FolderVisualCustomizationRestorer,
        finderIconApplier: FinderIconApplier,
        finderIconFileStore: FinderIconFileStore,
        finderInfoStore: FinderInfoStore
    ) {
        self.visualCustomizationRestorer = visualCustomizationRestorer
        self.finderIconApplier = finderIconApplier
        self.finderIconFileStore = finderIconFileStore
        self.finderInfoStore = finderInfoStore
    }
    
    func resetFolderToPlainIconBeforeApplying(
        at path: String,
        isDirectoryProvider: (String) -> Bool
    ) {
        guard isDirectoryProvider(path) else {
            return
        }

        visualCustomizationRestorer.removeVisualCustomizationXattrs(at: path)
        _ = finderIconApplier.clearIcon(at: path)
        finderIconFileStore.removeFolderIconFile(at: path)
        finderInfoStore.clearCustomIconState(at: path)

        finderIconApplier.notifyFileAndParentChanged(at: path)
    }
}
