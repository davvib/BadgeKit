//
//  FileIdentityResolver.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

public final class FileIdentityResolver {
    public init() {
    }
    
    public func resolvedBookmark(
        from bookmarkData: Data,
        allowingStale: Bool = false
    ) -> (url: URL, isStale: Bool)? {
        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), allowingStale || !isStale {
            return (url, isStale)
        }

        isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), allowingStale || !isStale {
            return (url, isStale)
        }

        return nil
    }

    public func resourceIdentifier(for url: URL) -> (any NSCopying & NSSecureCoding & NSObjectProtocol)? {
        try? url.resourceValues(
            forKeys: [.fileResourceIdentifierKey]
        ).fileResourceIdentifier
    }

    public func resourceIdentifierString(for url: URL) -> String? {
        guard let identifier = resourceIdentifier(for: url) else {
            return nil
        }

        if let data = identifier as? Data {
            return data.base64EncodedString()
        }

        return String(describing: identifier as Any)
    }
}
