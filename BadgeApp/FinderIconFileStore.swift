//
//  FinderIconFileStore.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class FinderIconFileStore {
    private let folderIconFileName = "Icon\r"
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func folderIconFileURL(for path: String) -> URL {
        URL(fileURLWithPath: path).appendingPathComponent(folderIconFileName)
    }

    func folderIconFileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: folderIconFileURL(for: path).path)
    }

    func removeFolderIconFile(at path: String) {
        try? fileManager.removeItem(at: folderIconFileURL(for: path))
    }
}
