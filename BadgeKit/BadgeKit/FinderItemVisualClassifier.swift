//
//  FinderItemVisualClassifier.swift
//  BadgeKit
//
//  Created by David Vilches on 10/07/2026.
//

import Foundation

public final class FinderItemVisualClassifier {
    private let finderIconStateReader: FinderIconStateReader
    private let folderVisualCustomizationReader: FolderVisualCustomizationReader
    private let xattrStore: XattrStore

    public init(
        finderIconStateReader: FinderIconStateReader,
        folderVisualCustomizationReader: FolderVisualCustomizationReader,
        xattrStore: XattrStore
    ) {
        self.finderIconStateReader = finderIconStateReader
        self.folderVisualCustomizationReader = folderVisualCustomizationReader
        self.xattrStore = xattrStore
    }

    public func visualKind(
        at path: String,
        isDirectory: Bool
    ) -> FinderItemVisualKind {
        guard isDirectory else {
            return .file
        }

        let xattrNames = xattrStore.names(at: path)

        let hasColor = folderVisualCustomizationReader
            .colorInfo(
                fromUserTagsData: xattrStore.data(
                    named: "com.apple.metadata:_kMDItemUserTags",
                    at: path
                )
            ) != nil

        let hasSymbol = !folderVisualCustomizationReader
            .symbolXattrNames(from: xattrNames)
            .isEmpty

        if hasColor && hasSymbol {
            return .finderColoredSymbolFolder
        }

        if hasColor {
            return .finderColoredFolder
        }

        if finderIconStateReader.hasCustomFinderIcon(at: path) {
            return .customFolderIcon
        }

        return .normalFolder
    }
}
