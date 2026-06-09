//
//  SocketError.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

/// Socket-related errors with localized descriptions
nonisolated enum SocketError: LocalizedError {
    /// Failed to create socket
    case creationFailed(errno: Int32)
    /// Failed to connect socket to address
    case connectFailed(errno: Int32)
    /// Failed to read data from socket
    case readFailed(errno: Int32)
    /// Read operation timed out
    case readTimeout
    /// Failed to write data to socket
    case writeFailed(errno: Int32)
    /// Write operation timed out
    case writeTimeout
    /// DNS resolving error
    case DNSResolvingError(String)

    var errorDescription: String? {
        switch self {
        case .creationFailed(let err):
            return "Socket creation failed: \(String(cString: strerror(err)))"
        case .connectFailed(let err):
            return "Connect failed: \(String(cString: strerror(err)))"
        case .readFailed(let err):
            return "Listen failed: \(String(cString: strerror(err)))"
        case .readTimeout:
            return "Read timeout"
        case .writeFailed(let err):
            return "Write failed: \(String(cString: strerror(err)))"
        case .writeTimeout:
            return "Write timeout"
        case .DNSResolvingError(let err):
            return "DNS resolving failed: \(err)"
        }
    }
}
