//
//  IconBackupRecord.swift
//  BadgeApp
//
//  Created by David Vilches on 14/05/2026.
//

import Foundation

public struct IconBackupRecord: Codable {
    public init(
        id: String,
        originalPath: String,
        bookmarkData: Data,
        createdAt: Date?,
        originalResourceIdentifier: String?,
        hadCustomIcon: Bool,
        iconFileName: String?,
        previewIconFileName: String?,
        visualCustomizationXattrs: [String: Data]?,
        finderInfoData: Data?
    ) {
        self.id = id
        self.originalPath = originalPath
        self.bookmarkData = bookmarkData
        self.createdAt = createdAt
        self.originalResourceIdentifier = originalResourceIdentifier
        self.hadCustomIcon = hadCustomIcon
        self.iconFileName = iconFileName
        self.previewIconFileName = previewIconFileName
        self.visualCustomizationXattrs = visualCustomizationXattrs
        self.finderInfoData = finderInfoData
    }
    
    public let id: String
    public let originalPath: String
    public let bookmarkData: Data
    public let createdAt: Date?
    public let originalResourceIdentifier: String?
    public let hadCustomIcon: Bool
    public let iconFileName: String?
    public let previewIconFileName: String?
    public let visualCustomizationXattrs: [String: Data]?
    public let finderInfoData: Data?
}

