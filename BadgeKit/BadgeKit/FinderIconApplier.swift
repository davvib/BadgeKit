//
//  FinderIconApplier.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

public final class FinderIconApplier {
    public init(){
    }
    
    public func applyIcon(_ icon: NSImage, to path: String) -> Bool {
        NSWorkspace.shared.setIcon(icon, forFile: path, options: [])
    }

    public func clearIcon(at path: String) -> Bool {
        NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
    }

    public func notifyFileSystemChanged(at path: String) {
        NSWorkspace.shared.noteFileSystemChanged(path)
    }

    public func notifyFileAndParentChanged(at path: String) {
        NSWorkspace.shared.noteFileSystemChanged(path)
        NSWorkspace.shared.noteFileSystemChanged((path as NSString).deletingLastPathComponent)
    }
}
