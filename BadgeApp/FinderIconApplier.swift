//
//  FinderIconApplier.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class FinderIconApplier {
    func applyIcon(_ icon: NSImage, to path: String) -> Bool {
        NSWorkspace.shared.setIcon(icon, forFile: path, options: [])
    }

    func clearIcon(at path: String) -> Bool {
        NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
    }

    func notifyFileSystemChanged(at path: String) {
        NSWorkspace.shared.noteFileSystemChanged(path)
    }

    func notifyFileAndParentChanged(at path: String) {
        NSWorkspace.shared.noteFileSystemChanged(path)
        NSWorkspace.shared.noteFileSystemChanged((path as NSString).deletingLastPathComponent)
    }
}
