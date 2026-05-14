//
//  IconBackupRecord.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Foundation

struct IconBackupRecord: Codable {
    let id: String
    let originalPath: String
    let bookmarkData: Data
    let createdAt: Date?
    let originalResourceIdentifier: String?
    let hadCustomIcon: Bool
    let iconFileName: String?
    let previewIconFileName: String?
    let visualCustomizationXattrs: [String: Data]?
    let finderInfoData: Data?
}

