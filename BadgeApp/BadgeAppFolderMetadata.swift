//
//  BadgeAppFolderMetadata.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

struct BadgeAppFolderMetadata: Codable {
    let version: Int
    let colorName: String?
    let symbolName: String?
    let symbolText: String?
}
