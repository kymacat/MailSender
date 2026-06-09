//
//  SMTPResponse.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated struct SMTPResponse {
    let code: Code
    let message: String

    var response: String {
        "\(code.rawValue) \(message)"
    }

    var challenge: ChallengeType? {
        guard code == .containingChallenge,
              let base64Data = Data(base64Encoded: message),
              let decodedString = String(data: base64Data, encoding: .utf8),
              let challenge = ChallengeType(rawValue: decodedString)
        else {
            return nil
        }

        return challenge
    }
}

extension SMTPResponse {
    enum Code: Int {
        case serviceReady = 220
        case connectionClosing = 221
        case authSucceeded = 235
        case commandOK = 250
        case willForward = 251
        case containingChallenge = 334
        case startMailInput = 354
    }

    enum ChallengeType: String {
        case username = "Username:"
        case password = "Password:"
    }
}
