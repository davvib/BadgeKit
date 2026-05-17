//
//  FinderInfoStore.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class FinderInfoStore {
    private let finderInfoXattrName = "com.apple.FinderInfo"
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
}
