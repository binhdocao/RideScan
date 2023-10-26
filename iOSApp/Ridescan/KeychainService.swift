//
//  KeychainService.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/25/23.
//

import Foundation
import Security

class KeychainService {
    static func save(key: String, data: Data) throws {
        
        // delete any preexisting items with same key
        do {
            try delete(key: key)
        } catch {
            print("Saving new keychain item. No need to delete.")
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
            throw KeychainError.unhandledError(status: status)
        }
    }

    static func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data {
            return data
        } else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

enum KeychainError: Error {
    case unhandledError(status: OSStatus)
}

