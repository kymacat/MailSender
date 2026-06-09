//
//  TCPConnection.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

nonisolated final class TCPConnection {
    private let host: String
    private let port: UInt16

    private var currentSocket: Int32 = -1
    private var tlsConnection: TLSConnection?

    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    deinit {
        if currentSocket != -1 {
            close(currentSocket)
        }
    }

    func connect() throws {
        currentSocket = socket(AF_INET, SOCK_STREAM, 0)

        guard currentSocket >= 0 else {
            throw SocketError.creationFailed(errno: errno)
        }

        var rcvTimeoutStruct = timeval()
        rcvTimeoutStruct.tv_sec = Constants.receiveTimeout
        rcvTimeoutStruct.tv_usec = 0
        setsockopt(
            currentSocket,
            SOL_SOCKET,
            SO_RCVTIMEO,
            &rcvTimeoutStruct,
            socklen_t(MemoryLayout<timeval>.size)
        )

        var sndTimeoutStruct = timeval()
        sndTimeoutStruct.tv_sec = Constants.sendTimeout
        sndTimeoutStruct.tv_usec = 0
        setsockopt(
            currentSocket,
            SOL_SOCKET,
            SO_SNDTIMEO,
            &sndTimeoutStruct,
            socklen_t(MemoryLayout<timeval>.size)
        )

        var serverAddr = try NetworkUtils.shared.resolveHost(host, port: port)

        let connectResult = withUnsafePointer(to: &serverAddr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                Darwin.connect(currentSocket, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard connectResult >= 0 else {
            throw SocketError.connectFailed(errno: errno)
        }
    }

    func tlsHandshake() throws {
        let tlsConnection = try TLSConnection(socket: currentSocket, host: host)
        try tlsConnection.handshake()
        self.tlsConnection = tlsConnection
    }

    func read(while condition: (Data) -> Bool) throws -> Data {
        guard currentSocket > 0 else { throw Error.needToConnect }

        var accumulatedData = Data()
        var tempBuffer = [UInt8](repeating: 0, count: Constants.chunkSize)

        while !condition(accumulatedData) {
            let bytesRead: Int

            if let tlsConnection {
                bytesRead = try tlsConnection.read(into: &tempBuffer, maxLength: Constants.chunkSize)
            } else {
                bytesRead = Darwin.read(currentSocket, &tempBuffer, Constants.chunkSize)
            }

            if bytesRead > 0 {
                accumulatedData.append(contentsOf: tempBuffer.prefix(bytesRead))
            } else if bytesRead == 0 {
                return accumulatedData
            } else {
                if errno == EINTR {
                    continue
                }

                if errno == EAGAIN || errno == EWOULDBLOCK {
                    throw SocketError.readTimeout
                }

                throw SocketError.readFailed(errno: errno)
            }
        }

        return accumulatedData
    }

    func write(data: Data) throws {
        guard currentSocket > 0 else { throw Error.needToConnect }

        var attempts = 0
        var totalBytesWritten = 0

        while totalBytesWritten < data.count && attempts < Constants.maxWriteAttempts {
            let chunk = data[totalBytesWritten..<min(totalBytesWritten + Constants.chunkSize, data.count)]

            let bytesWritten: Int
            if let tlsConnection {
                bytesWritten = try tlsConnection.write(buffer: Array(chunk), maxLength: chunk.count)
            } else {
                bytesWritten = Darwin.write(currentSocket, Array(chunk), chunk.count)
            }

            if bytesWritten < 0 {
                if errno == EINTR {
                    continue
                }

                if errno == EAGAIN || errno == EWOULDBLOCK {
                    attempts += 1
                    continue
                }

                throw SocketError.writeFailed(errno: errno)
            } else {
                totalBytesWritten += bytesWritten
                attempts = 0
            }
        }

        if totalBytesWritten < data.count {
            throw SocketError.writeTimeout
        }
    }

    func finish() {
        close(currentSocket)
        tlsConnection = nil
        currentSocket = -1
    }
}

private extension TCPConnection {
    enum Error: Swift.Error {
        case needToConnect
    }

    nonisolated enum Constants {
        static let receiveTimeout = 10
        static let sendTimeout = 10
        static let chunkSize = 1024 * 10
        static let maxWriteAttempts = 3
    }
}
