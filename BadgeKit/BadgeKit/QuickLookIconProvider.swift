//
//  QuickLookIconProvider.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa
import QuickLookThumbnailing
import UniformTypeIdentifiers

public final class QuickLookIconProvider {
    public init() {
    }
    
    public func fallbackIcon(for path: String) -> NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }

    public func defaultFolderIcon() -> NSImage {
        NSWorkspace.shared.icon(for: UTType.folder)
    }

    public func quickLookIcon(
        for path: String,
        fallbackIcon: NSImage,
        completion: @escaping (NSImage) -> Void
    ) {
        let url = URL(fileURLWithPath: path)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 1024, height: 1024),
            scale: 1.0,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, _ in
            completion(thumbnail?.nsImage ?? fallbackIcon)
        }
    }
}
