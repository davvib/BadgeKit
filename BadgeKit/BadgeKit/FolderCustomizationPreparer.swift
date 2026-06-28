//
//  FolderCustomizationPreparer.swift
//  BadgeKit
//
//  Created by David Vilches on 27/06/2026.
//

import Foundation
import AppKit

public final class FolderCustomizationPreparer {
    private let finderIconFileStore = FinderIconFileStore()
    private let xattrStore = XattrStore()
    
    public init() {
    }

    public func prepareFolderForCustomIcon(at path: String) {
        guard isDirectory(at: path) else {
            return
        }

        let names = [
            "com.apple.metadata:_kMDItemUserTags",
            "com.apple.icon.folder#S"
        ]

        for name in names {
            xattrStore.remove(named: name, at: path)
        }

        clearFinderIcon(at: path)

        finderIconFileStore.removeFolderIconFile(at: path)

        clearCustomIconState(at: path)

        notifyFinder(at: path)
    }
    
    private func isDirectory(at path: String) -> Bool {
        var isDirectory: ObjCBool = false

        let exists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDirectory
        )

        return exists && isDirectory.boolValue
    }
    
    private func clearCustomIconState(at path: String) {
        guard var finderInfo = finderInfoBytes(at: path) else {
            return
        }

        let hasCustomIconFlag: UInt16 = 0x0400

        var flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        flags &= ~hasCustomIconFlag

        finderInfo[8] = UInt8((flags >> 8) & 0xff)
        finderInfo[9] = UInt8(flags & 0xff)

        xattrStore.setData(
            Data(finderInfo),
            named: "com.apple.FinderInfo",
            at: path
        )
    }

    private func finderInfoBytes(at path: String) -> [UInt8]? {
        guard let data = xattrStore.data(
            named: "com.apple.FinderInfo",
            at: path
        ),
        data.count >= 32 else {
            return nil
        }

        return Array(data.prefix(32))
    }
    
    private func clearFinderIcon(at path: String) {
        _ = NSWorkspace.shared.setIcon(
            nil,
            forFile: path,
            options: []
        )
    }

    private func notifyFinder(at path: String) {
        NSWorkspace.shared.noteFileSystemChanged(path)

        let parentPath = (path as NSString).deletingLastPathComponent
        NSWorkspace.shared.noteFileSystemChanged(parentPath)
    }
}
