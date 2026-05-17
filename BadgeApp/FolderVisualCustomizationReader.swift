//
//  FolderVisualCustomizationReader.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class FolderVisualCustomizationReader {
    private let xattrStore: XattrStore

    init(xattrStore: XattrStore) {
        self.xattrStore = xattrStore
    }
    
    func isVisualCustomizationXattr(_ name: String) -> Bool {
        name == "com.apple.metadata:_kMDItemUserTags" ||
        name.hasPrefix("com.apple.metadata:kMDLabel_") ||
        name.hasPrefix("com.apple.icon.")
    }
    
    func hasVisualCustomization(
        at path: String,
        xattrNames: [String]
    ) -> Bool {
        xattrNames.contains(where: isVisualCustomizationXattr)
    }
    
    func visualCustomizationXattrNames(
        from names: [String]
    ) -> [String] {
        names.filter(isVisualCustomizationXattr)
    }
}

