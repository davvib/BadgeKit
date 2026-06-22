//
//  FolderAppearanceMetadata.swift
//  BadgeKit
//
//  Created by David Vilches on 22/06/2026.
//

import Foundation

public struct FolderAppearanceMetadata {
    public let colorName: String?
    public let symbolName: String?
    public let symbolText: String?

    public init(
        colorName: String?,
        symbolName: String?,
        symbolText: String?
    ) {
        self.colorName = colorName
        self.symbolName = symbolName
        self.symbolText = symbolText
    }
}
