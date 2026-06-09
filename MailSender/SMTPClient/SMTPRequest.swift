//
//  SMTPRequest.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

enum SMTPRequest {
    case helo
    case ehlo
    case starttls
    case auth
    case authUsername(String)
    case authPassword(Data)
    case mailFrom(String)
    case rcptTo(String)
    case data
    case mailMessage(String)
    case quit
}

extension SMTPRequest {
    nonisolated var requestData: Data {
        get throws {
            var data: Data?

            switch self {
            case .helo:
                data = "HELO \(Constants.clientName)\r\n".data(using: .utf8)
            case .ehlo:
                data = "EHLO \(Constants.clientName)\r\n".data(using: .utf8)
            case .starttls:
                data = "STARTTLS\r\n".data(using: .utf8)
            case .auth:
                data = "AUTH LOGIN\r\n".data(using: .utf8)
            case let .authUsername(username):
                guard let base64 = username.data(using: .utf8)?.base64EncodedString() else {
                    data = nil
                    break
                }

                data = "\(base64)\r\n".data(using: .utf8)
            case let .authPassword(password):
                let base64 = password.base64EncodedString()
                data = "\(base64)\r\n".data(using: .utf8)
            case let .mailFrom(mail):
                data = "MAIL FROM:<\(mail)>\r\n".data(using: .utf8)
            case let .rcptTo(mail):
                data = "RCPT TO:<\(mail)>\r\n".data(using: .utf8)
            case .data:
                data = "DATA\r\n".data(using: .utf8)
            case let .mailMessage(message):
                data = message.data(using: .utf8)
            case .quit:
                data = "QUIT\r\n".data(using: .utf8)
            }

            guard let data else {
                throw Error.invalidData("Error: invalid data for command \(self)")
            }

            return data
        }
    }
}

private extension SMTPRequest {
    nonisolated enum Constants {
        static let clientName = "swift-smtp.client"
    }

    nonisolated enum Error: Swift.Error {
        case invalidData(String)
    }
}
