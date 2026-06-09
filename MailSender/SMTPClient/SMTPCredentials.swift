//
//  SMTPCredentials.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated struct SMTPCredentials {
    let host: String
    let proto: Proto
    let username: String
    let loadPassword: () throws -> Data

    var port: UInt16 { proto.port }

    init(
        host: String,
        proto: Proto = .smtps,
        username: String,
        loadPassword: @escaping () throws -> Data
    ) {
        self.host = host
        self.proto = proto
        self.username = username
        self.loadPassword = loadPassword
    }
}

extension SMTPCredentials {
    nonisolated enum Proto {
        case smtps
        case starttls

        var port: UInt16 {
            switch self {
            case .smtps:
                465
            case .starttls:
                587
            }
        }
    }
}
