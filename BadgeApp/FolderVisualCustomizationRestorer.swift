//
//  FolderVisualCustomizationRestorer.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class FolderVisualCustomizationRestorer {
    private let xattrStore: XattrStore
    private let reader: FolderVisualCustomizationReader

    init(
        xattrStore: XattrStore,
        reader: FolderVisualCustomizationReader
    ) {
        self.xattrStore = xattrStore
        self.reader = reader
    }

    func removeVisualCustomizationXattrs(at path: String) {
        let names = reader.visualCustomizationXattrNames(
            from: xattrStore.names(at: path)
        )

        let url = URL(fileURLWithPath: path)
        try? (url as NSURL).setResourceValue([], forKey: .tagNamesKey)

        for name in names {
            xattrStore.remove(named: name, at: path)
        }
    }

    func restoreVisualCustomizationXattrs(_ xattrs: [String: Data]?, to path: String) {
        guard let xattrs else {
            return
        }

        for (name, data) in xattrs {
            xattrStore.setData(data, named: name, at: path)
        }
    }
}
