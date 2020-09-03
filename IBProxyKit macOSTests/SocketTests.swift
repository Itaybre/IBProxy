//
//  SocketTests.swift
//  IBProxyKit macOSTests
//
//  Created by Itay Brenner on 9/2/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import XCTest
@testable import IBProxyKit

class SocketTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testPeernameInvalidSocket() throws {
        let socket = Socket(socketFileDescriptor: -1)
        var thrownError: Error?

        XCTAssertThrowsError(try socket.peername()) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError is SocketError)
        XCTAssertEqual(thrownError as? SocketError, SocketError.getPeerNameFailed("Bad file descriptor"))
    }

    func testPeernameSocketNotConnected() throws {
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)

        let socket = Socket(socketFileDescriptor: socketFileDescriptor)
        var thrownError: Error?

        XCTAssertThrowsError(try socket.peername()) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError is SocketError)
        XCTAssertEqual(thrownError as? SocketError, SocketError.getPeerNameFailed("Socket is not connected"))
    }

    func testListenSocketTwice() throws {
        let socket1 = try Socket.listenSocket(8081, "127.0.0.1")
        var thrownError: Error?

        XCTAssertThrowsError(try Socket.listenSocket(8081, "127.0.0.1")) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError is SocketError)
        XCTAssertEqual(thrownError as? SocketError, SocketError.bindFailed("Address already in use"))

        socket1.close()
    }

    func testListenSocketPermissions() throws {
        var thrownError: Error?

        XCTAssertThrowsError(try Socket.listenSocket(1, "127.0.0.1")) {
            thrownError = $0
        }
        XCTAssertTrue(thrownError is SocketError)
        XCTAssertEqual(thrownError as? SocketError, SocketError.bindFailed("Permission denied"))
    }

    func testAcceptConnection() throws {
        let exp = expectation(description: "Wait socket connect")

        let socket = try Socket.listenSocket(5051)
        var acceptedSocket: Socket?

        DispatchQueue.global(qos: .background).async {
            acceptedSocket = try? socket.acceptClientSocket()

            if acceptedSocket != nil {
                exp.fulfill()
            }
        }

        _ = connectSocket(5051, 8082)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(acceptedSocket)

        let peerName = try acceptedSocket?.peername() ?? ""
        let serverPort = try acceptedSocket?.port()
        XCTAssertEqual(peerName, "127.0.0.1:8082")
        XCTAssertEqual(serverPort, 5051)

        acceptedSocket?.close()
        socket.close()
    }

    func testSendAndReceiveString() throws {
        let exp = expectation(description: "Wait socket connect")

        let socket = try Socket.listenSocket(5052)
        var acceptedSocket: Socket?

        DispatchQueue.global(qos: .background).async {
            acceptedSocket = try? socket.acceptClientSocket()

            if acceptedSocket != nil {
                exp.fulfill()
            }
        }

        let client = connectSocket(5052, 8083)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(acceptedSocket)
        let message = "Example Message\r\n"
        try acceptedSocket?.writeData(message.data(using: .ascii)!)

        let received = try client.readLine()
        XCTAssertEqual(received, "Example Message")

        acceptedSocket?.close()
        socket.close()
    }

    func testSendAndReceiveData() throws {
        let exp = expectation(description: "Wait socket connect")

        let socket = try Socket.listenSocket(5052)
        var acceptedSocket: Socket?

        DispatchQueue.global(qos: .background).async {
            acceptedSocket = try? socket.acceptClientSocket()

            if acceptedSocket != nil {
                exp.fulfill()
            }
        }

        let client = connectSocket(5052, 8083)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(acceptedSocket)

        let message = "Example"
        try acceptedSocket?.writeData(message.data(using: .ascii)!)

        let receivedData = try client.read(length: 7)
        let string = String(data: Data(receivedData), encoding: .ascii)
        XCTAssertEqual(string, message)

        acceptedSocket?.close()
        socket.close()
    }

    private func connectSocket(_ port: in_port_t, _ socketPort: in_port_t) -> Socket {
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        var value: Int32 = 1
        setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in(
            sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
            sin_family: UInt8(AF_INET),
            sin_port: socketPort.bigEndian,
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))

        _ = withUnsafePointer(to: &addr) {
            Darwin.bind(socketFileDescriptor,
                    UnsafePointer<sockaddr>(OpaquePointer($0)),
                    socklen_t(MemoryLayout<sockaddr_in>.size))
        }

        var targetAddr = sockaddr_in(
            sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
            sin_family: UInt8(AF_INET),
            sin_port: port.bigEndian,
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))

        _ = withUnsafePointer(to: &targetAddr) {
            connect(socketFileDescriptor,
                    UnsafePointer<sockaddr>(OpaquePointer($0)),
                    socklen_t(MemoryLayout<sockaddr_in>.size))
        }

        return Socket(socketFileDescriptor: socketFileDescriptor)
    }
}
