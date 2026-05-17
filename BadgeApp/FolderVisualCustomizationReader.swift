//
//  FolderVisualCustomizationReader.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Cocoa

final class FolderVisualCustomizationReader {
    private let xattrStore: XattrStore

    init(xattrStore: XattrStore) {
        self.xattrStore = xattrStore
    }
    
    func isVisualCustomizationXattr(_ name: String) -> Bool {
        name == "com.apple.metadata:_kMDItemUserTags" ||
        name.hasPrefix("com.apple.metadata:kMDLabel_") ||
        name.hasPrefix("com.apple.icon.")
    }
    
    func hasVisualCustomization(
        at path: String,
        xattrNames: [String]
    ) -> Bool {
        xattrNames.contains(where: isVisualCustomizationXattr)
    }
    
    func visualCustomizationXattrNames(
        from names: [String]
    ) -> [String] {
        names.filter(isVisualCustomizationXattr)
    }
    
    func colorInfo(fromUserTagsData data: Data?) -> (name: String, color: NSColor)? {
        guard let data,
              let tags = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] else {
            return nil
        }

        for tag in tags {
            let name = tag
                .components(separatedBy: .newlines)
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let name, let color = folderColor(named: name) {
                return (name, color)
            }
        }

        return nil
    }

    func folderColor(named name: String) -> NSColor? {
        switch name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) {
        case "roja", "rojo", "red":
            return NSColor(red: 1.00, green: 0.32, blue: 0.28, alpha: 1)
        case "naranja", "orange":
            return NSColor(red: 1.00, green: 0.58, blue: 0.24, alpha: 1)
        case "amarilla", "amarillo", "yellow":
            return NSColor(red: 1.00, green: 0.84, blue: 0.14, alpha: 1)
        case "verde", "green":
            return NSColor(red: 0.30, green: 0.82, blue: 0.42, alpha: 1)
        case "azul", "blue":
            return NSColor(red: 0.18, green: 0.61, blue: 0.95, alpha: 1)
        case "azul claro", "azulclaro", "light blue", "lightblue", "cyan":
            return NSColor(red: 0.38, green: 0.76, blue: 0.92, alpha: 1)
        case "violeta", "morada", "morado", "purpura", "purple", "violet":
            return NSColor(red: 0.78, green: 0.28, blue: 0.93, alpha: 1)
        case "rosa", "pink":
            return NSColor(red: 1.00, green: 0.32, blue: 0.48, alpha: 1)
        case "gris", "gray", "grey":
            return NSColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)
        default:
            return nil
        }
    }
    
    func isEmojiFolderSymbol(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 8 else {
            return false
        }

        return trimmed.unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation ||
            scalar.properties.isEmojiModifier ||
            scalar.properties.isEmojiModifierBase ||
            scalar.properties.isJoinControl ||
            scalar.value == 0xfe0f
        }
    }
    
    func symbolXattrNames(from names: [String]) -> [String] {
        let preferred = ["com.apple.icon.folder#S"]
        let iconNames = names
            .filter { $0.hasPrefix("com.apple.icon.folder") }
            .sorted()

        return preferred + iconNames.filter { !preferred.contains($0) }
    }
    
    func symbolInfo(fromData data: Data?) -> FolderSymbolInfo? {
        guard let data else {
            return nil
        }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let stringValues = object.values.compactMap { $0 as? String }

            if let symbolName = object["sym"] as? String,
               NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil {
                return FolderSymbolInfo(systemName: symbolName, text: nil)
            }

            if let emoji = stringValues.first(where: isEmojiFolderSymbol) {
                return FolderSymbolInfo(systemName: nil, text: emoji)
            }

            if let symbolName = stringValues.first(where: {
                NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil
            }) {
                return FolderSymbolInfo(systemName: symbolName, text: nil)
            }
        }

        if let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           isEmojiFolderSymbol(text) {
            return FolderSymbolInfo(systemName: nil, text: text)
        }

        return nil
    }
}

