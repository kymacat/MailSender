//
//  SMTPMail.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated struct SMTPMail {
    let from: String
    let to: String
    let cc: [String]
    let subject: String
    let body: String

    init(
        from: String,
        to: String,
        cc: [String] = [],
        subject: String,
        body: String
    ) {
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
    }

    var message: String {
        let cc = cc.isEmpty ? "" : "\r\nCc: \(cc.joined(separator: ","))"
        let subjectBase64 = subject.data(using: .utf8)?.base64EncodedString() ?? ""

        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let formattedDate = formatter.string(from: date)

        return """
        From: \(from)
        To: \(to)\(cc)
        Subject: =?utf-8?B?\(subjectBase64)?=
        Date: \(formattedDate)
        MIME-Version: 1.0
        Content-Type: text/plain; charset=utf-8
        Content-Transfer-Encoding: 8bit
        X-Mailer: SMTPSwift Client 1.0
        Message-Id: \(UUID().uuidString)
        
        \(body)\r\n.\r\n
        """
    }
}
