//
//  TLSConnection.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated final class TLSConnection {
    private let socket: Int32
    private let host: String
    private let context: SSLContext

    init(socket: Int32, host: String) throws {
        guard let context = SSLCreateContext(kCFAllocatorDefault, .clientSide, .streamType) else {
            throw Error.contextCreationFailed
        }

        self.host = host
        self.socket = socket
        self.context = context
        configureSSLContext()
    }

    deinit {
        SSLClose(context)
    }

    func handshake() throws {
        var status = SSLHandshake(context)

        var attempts = 0
        while status != errSecSuccess && attempts < Constants.retryCount {
            status = SSLHandshake(context)
            attempts += 1
        }

        guard status == errSecSuccess else {
            let errDesc = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            throw Error.handshakeFailed(errDesc)
        }
    }

    func read(into buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        var processed = 0
        let status = SSLRead(context, buffer, maxLength, &processed)

        switch status {
        case errSecSuccess:
           return processed
        case errSSLClosedGraceful, errSSLClosedAbort:
            return 0
        default:
            let errDesc = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            throw Error.readError(errDesc)
        }

    }

    func write(buffer: UnsafePointer<UInt8>, maxLength: Int) throws -> Int {
        var processed = 0
        let status = SSLWrite(context, buffer, maxLength, &processed)

        switch status {
        case errSecSuccess:
           return processed
        case errSSLClosedGraceful, errSSLClosedAbort:
            return 0
        default:
            let errDesc = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            throw Error.writeError(errDesc)
        }
    }

    private func configureSSLContext() {
        SSLSetIOFuncs(context, sslReadCallback, sslWriteCallback)
        SSLSetConnection(context, UnsafeMutablePointer(bitPattern: UInt(socket)))
        SSLSetPeerDomainName(context, host, host.utf8.count)
    }
}

private extension TLSConnection {
    nonisolated enum Constants {
        static let retryCount = 10
    }

    enum Error: Swift.Error {
        case contextCreationFailed
        case handshakeFailed(String)
        case readError(String)
        case writeError(String)
    }
}

nonisolated private func sslReadCallback(
    connection: SSLConnectionRef,
    data: UnsafeMutableRawPointer,
    dataLength: UnsafeMutablePointer<Int>
) -> OSStatus {
    let socket = Int32(UInt(bitPattern: connection))
    let totalBytesToRead = dataLength.pointee
    var totalBytesRead = 0
    let ptr = data.assumingMemoryBound(to: UInt8.self)
    
    while totalBytesRead < totalBytesToRead {
        let bytesRead = read(socket, ptr + totalBytesRead, totalBytesToRead - totalBytesRead)

        if bytesRead > 0 {
            totalBytesRead += bytesRead
        } else if bytesRead == 0 {
            dataLength.pointee = totalBytesRead
            return totalBytesRead > 0 ? errSecSuccess : errSSLClosedGraceful
        } else {
            let err = errno
            if err == EAGAIN || err == EWOULDBLOCK {
                dataLength.pointee = totalBytesRead
                return errSSLWouldBlock
            }
            dataLength.pointee = totalBytesRead
            return errSecIO
        }
    }

    dataLength.pointee = totalBytesRead
    return errSecSuccess
}

nonisolated private func sslWriteCallback(
    connection: SSLConnectionRef,
    data: UnsafeRawPointer,
    dataLength: UnsafeMutablePointer<Int>
) -> OSStatus {
    let socket = Int32(UInt(bitPattern: connection))
    let totalBytesToWrite = dataLength.pointee
    var totalBytesWritten = 0
    let ptr = data.assumingMemoryBound(to: UInt8.self)

    while totalBytesWritten < totalBytesToWrite {
        let bytesWritten = write(socket, ptr + totalBytesWritten, totalBytesToWrite - totalBytesWritten)

        if bytesWritten > 0 {
            totalBytesWritten += bytesWritten
        } else if bytesWritten == 0 {
            dataLength.pointee = totalBytesWritten
            return totalBytesWritten > 0 ? errSecSuccess : errSSLClosedGraceful
        } else {
            let err = errno
            if err == EAGAIN || err == EWOULDBLOCK {
                dataLength.pointee = totalBytesWritten
                return errSSLWouldBlock
            }
            dataLength.pointee = totalBytesWritten
            return errSecIO
        }
    }

    dataLength.pointee = totalBytesWritten
    return errSecSuccess
}
