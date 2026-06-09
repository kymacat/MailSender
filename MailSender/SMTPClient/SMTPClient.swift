//
//  SMTPClient.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

actor SMTPClient {
    private let credentials: SMTPCredentials
    private let connection: TCPConnection

    init(credentials: SMTPCredentials) {
        self.credentials = credentials
        self.connection = TCPConnection(host: credentials.host, port: credentials.port)
    }

    func send(email: SMTPMail) throws {
        defer { connection.finish() }

        try connect()
        
        let fromResponse = try sendRequest(.mailFrom(email.from))
        guard fromResponse.code == .commandOK else {
            throw Error.sendEmailError(fromResponse.response)
        }
        print(fromResponse.response)

        for mail in [email.to] + email.cc {
            do {
                let toResponse = try sendRequest(.rcptTo(mail))
                print(toResponse.response)
            } catch {
                print("Failed setting \(mail) as recipient: \(error)")
            }
        }

        let dataResponse = try sendRequest(.data)
        guard dataResponse.code == .startMailInput else {
            throw Error.sendEmailError(dataResponse.response)
        }
        print(dataResponse.response)

        let dataEndResponse = try sendRequest(.mailMessage(email.message))
        guard dataEndResponse.code == .commandOK else {
            throw Error.sendEmailError(dataEndResponse.response)
        }
        print(dataEndResponse.response)

        try sendRequest(.quit)
    }

    private func connect() throws {
        try connection.connect()

        if credentials.proto == .smtps {
            try connection.tlsHandshake()
        }

        let statusData = try connection.read(while: endMessageCondition)
        let status = try parseResponse(statusData)

        guard status.code == .serviceReady else {
            throw Error.serverNotReady(status.response)
        }
        print(status.response)

        let helloResponse = try sendRequest(.ehlo)
        guard helloResponse.code == .commandOK else {
            throw Error.serverNotReady(helloResponse.response)
        }

        if credentials.proto == .starttls {
            let starttlsResponse = try sendRequest(.starttls)
            guard starttlsResponse.code == .serviceReady else {
                throw Error.serverNotReady(starttlsResponse.response)
            }

            try connection.tlsHandshake()

            let hello2Response = try sendRequest(.ehlo)
            guard hello2Response.code == .commandOK else {
                throw Error.serverNotReady(hello2Response.response)
            }
        }

        let usernameResponse = try sendRequest(.auth)
        guard usernameResponse.challenge == .username else {
            throw Error.authError(usernameResponse.response)
        }

        let passwordResponse = try sendRequest(.authUsername(credentials.username))
        guard passwordResponse.challenge == .password else {
            throw Error.authError(passwordResponse.response)
        }

        let passwordData = try credentials.loadPassword()
        let authResponse = try sendRequest(.authPassword(passwordData))
        guard authResponse.code == .authSucceeded else {
            throw Error.authError(authResponse.response)
        }
        print(authResponse.response)
    }

    @discardableResult
    private func sendRequest(_ request: SMTPRequest) throws -> SMTPResponse {
        try connection.write(data: request.requestData)
        let responseData = try connection.read(while: endMessageCondition)
        return try parseResponse(responseData)
    }

    private func parseResponse(_ data: Data) throws -> SMTPResponse {
        guard let response = String(data: data, encoding: .utf8) else {
            throw Error.parseError(nil)
        }

        guard response.count > 4 else {
            throw Error.parseError(response)
        }

        guard let code = Int(String(response.prefix(3))),
              let smtpCode = SMTPResponse.Code(rawValue: code)
        else {
            throw Error.parseError(response)
        }

        let message = String(response.suffix(response.count - 4)).replacingOccurrences(of: Constants.CRLF, with: "")
        return SMTPResponse(code: smtpCode, message: message)
    }

    private func endMessageCondition(data: Data) -> Bool {
        guard let string = String(data: data, encoding: .utf8),
              let lastRow = string.split(separator: Constants.CRLF).last,
              lastRow.count > 3
        else {
            return false
        }

        return lastRow[lastRow.index(lastRow.startIndex, offsetBy: 3)] == " "
    }
}

private extension SMTPClient {
    nonisolated enum Constants {
        static let CRLF = "\r\n"
    }

    enum Error: Swift.Error {
        case parseError(String?)
        case requestError(String)
        case serverNotReady(String)
        case authError(String)
        case sendEmailError(String)
    }
}
