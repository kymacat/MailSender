//
//  PasswordSecureStorage.swift
//  MailSender
//
//  Created by Yandola Vladislav on 09.05.2026.
//

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case unexpectedData
    case unhandledError(status: OSStatus)
    case itemNotFound
    case duplicateItem
    case invalidInput
}


final class PasswordSecureStorage {
    private let serviceName = Bundle.main.bundleIdentifier ?? "com.yandola.mail-sender"

    func password() throws -> Data {
        try retrievePassword()
    }

    func saveOrUpdate(password: String) throws {
        do {
            _ = try retrievePassword()
            try update(password: password)
        } catch KeychainError.itemNotFound {
            try save(password: password)
        }
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    private func save(password: String) throws {
        guard !password.isEmpty else {
            throw KeychainError.invalidInput
        }

        let passwordData = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: Constants.passwordKey,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    private func retrievePassword() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: Constants.passwordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    private func update(password: String) throws {
        guard !password.isEmpty else {
            throw KeychainError.invalidInput
        }

        let passwordData = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: Constants.passwordKey
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

private extension PasswordSecureStorage {
    enum Constants {
        static let passwordKey = "password"
    }
}
