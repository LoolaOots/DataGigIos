//
//  KeychainService.swift
//  datagigios
//

import Foundation
import Security

// MARK: - Keychain Keys

extension KeychainService {
    enum Key {
        static let accessToken  = "datagigs.accessToken"
        static let refreshToken = "datagigs.refreshToken"
        static let userId       = "datagigs.userId"
    }
}

// MARK: - Errors

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case unexpectedData
}

// MARK: - KeychainService

struct KeychainService {

    func save(key: String, value: String) throws {
        let data = Data(value.utf8)

        // Delete any existing item first
        delete(key: key)

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       kCFBooleanTrue as Any,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrAccount:  key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
