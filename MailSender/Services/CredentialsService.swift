//
//  CredentialsService.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

final class CredentialsService {
    static let shared = CredentialsService()
    private let passwordSecureStorage = PasswordSecureStorage()

    private let userDefaultsKey = "saved_user_credentials"

    private init() {}

    var password: Data {
        get throws {
            try passwordSecureStorage.password()
        }
    }

    var savedCredentials: UserCredentials? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(UserCredentials.self, from: data)
    }

    func save(credentials: UserCredentials, password: String) throws {
        let data = try JSONEncoder().encode(credentials)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        try passwordSecureStorage.saveOrUpdate(password: password)
    }

    func clear() throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        try passwordSecureStorage.clear()
    }
}
