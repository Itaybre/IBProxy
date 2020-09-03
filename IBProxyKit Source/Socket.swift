//
//  Socket.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/31/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

class Socket {
    let socketFileDescriptor: Int32
    private var shutdown = false

    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }

    deinit {
        close()
    }

    public func close() {
        if shutdown {
            return
        }
        shutdown = true
        Socket.close(self.socketFileDescriptor)
    }

    public func port() throws -> in_port_t {
        var addr = sockaddr_in()
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(ErrnoWrapper.description())
            }
            let sinPort = pointer.pointee.sin_port
            return Int(OSHostByteOrder()) != OSLittleEndian ? sinPort.littleEndian : sinPort.bigEndian
        }
    }

    public func writeData(_ data: Data) throws {
        try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) -> Void in
            if let baseAddress = body.baseAddress, body.count > 0 {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                try self.writeBuffer(pointer, length: data.count)
            }
        }
    }

    private func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            let result = write(self.socketFileDescriptor, pointer + sent, Int(length - sent))
            if result <= 0 {
                throw SocketError.writeFailed(ErrnoWrapper.description())
            }
            sent += result
        }
    }

    /// Read a single byte off the socket. This method is optimized for reading
    /// a single byte. For reading multiple bytes, use read(length:), which will
    /// pre-allocate heap space and read directly into it.
    ///
    /// - Returns: A single byte
    /// - Throws: SocketError.recvFailed if unable to read from the socket
    open func read() throws -> UInt8 {
        var byte: UInt8 = 0

        let count = Darwin.read(self.socketFileDescriptor as Int32, &byte, 1)

        guard count > 0 else {
            throw SocketError.recvFailed(ErrnoWrapper.description())
        }
        return byte
    }

    /// Read up to `length` bytes from this socket
    ///
    /// - Parameter length: The maximum bytes to read
    /// - Returns: A buffer containing the bytes read
    /// - Throws: SocketError.recvFailed if unable to read bytes from the socket
    open func read(length: Int) throws -> [UInt8] {
        var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: length)

        let bytesRead = try read(into: &buffer, length: length)

        let returnArray = [UInt8](buffer[0..<bytesRead])
        buffer.deallocate()
        return returnArray
    }

    /// Read up to `length` bytes from this socket into an existing buffer
    ///
    /// - Parameter into: The buffer to read into (must be at least length bytes in size)
    /// - Parameter length: The maximum bytes to read
    /// - Returns: The number of bytes read
    /// - Throws: SocketError.recvFailed if unable to read bytes from the socket
    func read(into buffer: inout UnsafeMutableBufferPointer<UInt8>, length: Int) throws -> Int {
        var offset = 0
        guard let baseAddress = buffer.baseAddress else { return 0 }

        while offset < length {
            // Compute next read length in bytes. The bytes read is never more than kBufferLength at once.
            let readLength = offset + Constants.bufferLength < length ? Constants.bufferLength : length - offset

            let bytesRead = Darwin.read(self.socketFileDescriptor as Int32, baseAddress + offset, readLength)

            guard bytesRead > 0 else {
                throw SocketError.recvFailed(ErrnoWrapper.description())
            }

            offset += bytesRead
        }

        return offset
    }

    public func readLine() throws -> String {
        var characters: String = ""
        var index: UInt8 = 0
        repeat {
            index = try self.read()
            if index > Constants.carriageReturn { characters.append(Character(UnicodeScalar(index))) }
        } while index != Constants.newLine
        return characters
    }

    public func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.getPeerNameFailed(ErrnoWrapper.description())
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var portBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count),
                       &portBuffer, socklen_t(portBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) != 0 {
            throw SocketError.getNameInfoFailed(ErrnoWrapper.description())
        }
        return "\(String(cString: hostBuffer)):\(String(cString: portBuffer))"
    }

    public class func setNoSigPipe(_ socket: Int32) {
        // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
        var noSigPipe: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
    }

    public class func close(_ socket: Int32) {
        _ = Darwin.close(socket)
    }
}
