//
//  NetworkUtils.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated final class NetworkUtils {
    static let shared = NetworkUtils()

    private init() {}

    func resolveHost(_ host: String, port: UInt16) throws -> sockaddr_in {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?

        let status = getaddrinfo(host, String(port), &hints, &result)
        guard status == 0, let addrList = result else {
            throw SocketError.DNSResolvingError(String(cString: gai_strerror(status)))
        }

        defer { freeaddrinfo(addrList) }

        var serverAddr = sockaddr_in()
        memcpy(&serverAddr, addrList.pointee.ai_addr, Int(addrList.pointee.ai_addrlen))

        return serverAddr
    }
}
