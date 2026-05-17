//
//  FinderInfoStore.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class FinderInfoStore {
    private let finderInfoXattrName = "com.apple.FinderInfo"
    let hasCustomIconFlag: UInt16 = 0x0400
    let extendedFlagsAreInvalidFlag: UInt16 = 0x8000
    
    private let xattrStore: XattrStore
    
    init(xattrStore: XattrStore) {
        self.xattrStore = xattrStore
    }

    func bytes(at path: String) -> [UInt8]? {
        guard let data = xattrStore.data(named: finderInfoXattrName, at: path),
              data.count >= 32 else {
            return nil
        }

        return Array(data.prefix(32))
    }

    func setBytes(_ finderInfo: [UInt8], at path: String) -> Bool {
        guard finderInfo.count == 32 else {
            return false
        }

        let data = Data(finderInfo)
        xattrStore.setData(data, named: finderInfoXattrName, at: path)
        return true
    }

    func restore(_ data: Data?, to path: String) {
        guard let data else {
            xattrStore.remove(named: finderInfoXattrName, at: path)
            return
        }

        xattrStore.setData(data, named: finderInfoXattrName, at: path)
    }
    
    func data(at path: String) -> Data? {
        xattrStore.data(named: finderInfoXattrName, at: path)
    }
    
    func hasCustomIcon(at path: String) -> Bool {
        guard let finderInfo = bytes(at: path),
              finderInfo.count >= 10 else {
            return false
        }

        let flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        return (flags & hasCustomIconFlag) != 0
    }

    func forceCustomIconState(at path: String) {
        var finderInfo = bytes(at: path) ?? [UInt8](repeating: 0, count: 32)

        var flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        flags |= hasCustomIconFlag
        finderInfo[8] = UInt8((flags >> 8) & 0xff)
        finderInfo[9] = UInt8(flags & 0xff)

        var extendedFlags = (UInt16(finderInfo[24]) << 8) | UInt16(finderInfo[25])
        extendedFlags &= ~extendedFlagsAreInvalidFlag
        finderInfo[24] = UInt8((extendedFlags >> 8) & 0xff)
        finderInfo[25] = UInt8(extendedFlags & 0xff)

        _ = setBytes(finderInfo, at: path)
    }

    func clearCustomIconState(at path: String) {
        guard var finderInfo = bytes(at: path) else {
            return
        }

        var flags = (UInt16(finderInfo[8]) << 8) | UInt16(finderInfo[9])
        flags &= ~hasCustomIconFlag
        finderInfo[8] = UInt8((flags >> 8) & 0xff)
        finderInfo[9] = UInt8(flags & 0xff)

        _ = setBytes(finderInfo, at: path)
    }
}
