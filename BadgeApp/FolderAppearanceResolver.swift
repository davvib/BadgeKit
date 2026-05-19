//
//  FolderAppearanceResolver.swift
//  BadgeApp
//
//  Created by David Vilches on 19/05/2026.
//

import AppKit

final class FolderAppearanceResolver {
    private let visualCustomizationReader: FolderVisualCustomizationReader

    init(visualCustomizationReader: FolderVisualCustomizationReader) {
        self.visualCustomizationReader = visualCustomizationReader
    }
    
    func colorInfo(fromUserTagsData data: Data?) -> (name: String, color: NSColor)? {
        visualCustomizationReader.colorInfo(fromUserTagsData: data)
    }
    
    func folderColor(named name: String) -> NSColor? {
        visualCustomizationReader.folderColor(named: name)
    }
    
    func symbolXattrNames(from names: [String]) -> [String] {
        visualCustomizationReader.symbolXattrNames(from: names)
    }
    
    func symbolInfo(fromData data: Data?) -> FolderSymbolInfo? {
        visualCustomizationReader.symbolInfo(fromData: data)
    }
    
    func symbolXattrNames(
        at path: String,
        xattrNamesProvider: (String) -> [String]
    ) -> [String] {
        symbolXattrNames(from: xattrNamesProvider(path))
    }
    
    func symbolInfo(
        at path: String,
        backupVisualCustomizationXattrs: [String: Data]?,
        xattrNamesProvider: (String) -> [String],
        xattrDataProvider: (String, String) -> Data?
    ) -> FolderSymbolInfo {
        for name in symbolXattrNames(at: path, xattrNamesProvider: xattrNamesProvider) {
            if let symbolInfo = symbolInfo(
                fromData: xattrDataProvider(name, path)
            ) {
                return symbolInfo
            }
        }

        if let xattrs = backupVisualCustomizationXattrs {
            for name in symbolXattrNames(from: Array(xattrs.keys)) {
                if let symbolInfo = symbolInfo(fromData: xattrs[name]) {
                    return symbolInfo
                }
            }
        }

        return FolderSymbolInfo(systemName: nil, text: nil)
    }
    
    func colorInfo(
        at path: String,
        folderMetadata: BadgeAppFolderMetadata?,
        backupVisualCustomizationXattrs: [String: Data]?,
        xattrDataProvider: (String, String) -> Data?
    ) -> (name: String, color: NSColor)? {

        if let name = folderMetadata?.colorName,
           let color = folderColor(named: name) {
            return (name, color)
        }

        if let colorInfo = colorInfo(
            fromUserTagsData: xattrDataProvider(
                "com.apple.metadata:_kMDItemUserTags",
                path
            )
        ) {
            return colorInfo
        }

        if let data = backupVisualCustomizationXattrs?[
            "com.apple.metadata:_kMDItemUserTags"
        ] {
            return colorInfo(fromUserTagsData: data)
        }

        return nil
    }
    
    func visualCustomizationXattrs(
        at path: String,
        isDirectoryProvider: (String) -> Bool,
        xattrNamesProvider: (String) -> [String],
        xattrDataProvider: (String, String) -> Data?
    ) -> [String: Data] {
        guard isDirectoryProvider(path) else {
            return [:]
        }

        let names = visualCustomizationReader.visualCustomizationXattrNames(
            from: xattrNamesProvider(path)
        )

        return names.reduce(into: [String: Data]()) { result, name in
            result[name] = xattrDataProvider(name, path)
        }
    }
}

