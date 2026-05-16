//
//  XattrStore.swift
//  BadgeApp
//
//  Created by David Vilches on 17/05/2026.
//

import Foundation

final class XattrStore {
    func names(at path: String) -> [String] {
        path.withCString { pathPointer in
            let size = listxattr(pathPointer, nil, 0, 0)
            guard size > 0 else { return [] }

            var buffer = [CChar](repeating: 0, count: size)
            let result = listxattr(pathPointer, &buffer, size, 0)
            guard result > 0 else { return [] }

            return String(
                bytes: buffer.map { UInt8(bitPattern: $0) },
                encoding: .utf8
            )?
            .split(separator: "\0")
            .map(String.init) ?? []
        }
    }

    func data(named name: String, at path: String) -> Data? {
        path.withCString { pathPointer in
            name.withCString { namePointer in
                let size = getxattr(pathPointer, namePointer, nil, 0, 0, 0)
                guard size > 0 else { return nil }

                var buffer = Data(count: size)
                let result = buffer.withUnsafeMutableBytes {
                    getxattr(pathPointer, namePointer, $0.baseAddress, size, 0, 0)
                }

                guard result == size else {
                    return nil
                }

                return buffer
            }
        }
    }

    func setData(_ data: Data, named name: String, at path: String) {
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }

            path.withCString { pathPointer in
                name.withCString { namePointer in
                    _ = setxattr(pathPointer, namePointer, baseAddress, buffer.count, 0, 0)
                }
            }
        }
    }

    func remove(named name: String, at path: String) {
        path.withCString { pathPointer in
            _ = removexattr(pathPointer, name, 0)
        }
    }
}
