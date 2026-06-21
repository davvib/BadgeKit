//
//  FolderSymbolInfo.swift
//  BadgeKit
//
//  Created by David Vilches on 21/06/2026.
//

import Foundation

public struct FolderSymbolInfo {
    public let systemName: String?
    public let text: String?

    public init(systemName: String?, text: String?) {
        self.systemName = systemName
        self.text = text
    }
}
