//
//  FolderCustomizationPreparer.swift
//  BadgeKit
//
//  Created by David Vilches on 27/06/2026.
//

import Darwin
import Foundation

public final class FolderCustomizationPreparer {
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
            path.withCString { pathPointer in
                name.withCString { namePointer in
                    _ = removexattr(pathPointer, namePointer, 0)
                }
            }
        }
    }
    
    private func isDirectory(at path: String) -> Bool {
        var isDirectory: ObjCBool = false

        let exists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDirectory
        )

        return exists && isDirectory.boolValue
    }
}
