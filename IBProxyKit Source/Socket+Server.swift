//
//  Socket+Server.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/31/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

extension Socket {
    public class func listenSocket(_ port: in_port_t,
                                   _ listenAddress: String? = nil) throws -> Socket {

        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)

        if socketFileDescriptor == -1 {
            throw SocketError.socketCreationFailed(ErrnoWrapper.description())
        }

        var value: Int32 = 1
        if setsockopt(socketFileDescriptor,
                      SOL_SOCKET, SO_REUSEADDR,
                      &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            let details = ErrnoWrapper.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.socketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)

        var bindResult: Int32 = -1
        var addr = sockaddr_in(
            sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
            sin_family: UInt8(AF_INET),
            sin_port: port.bigEndian,
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        if let address = listenAddress {
            if address.withCString({ cstring in inet_pton(AF_INET, cstring, &addr.sin_addr) }) == 1 {
                print("\(address) is converted to \(addr.sin_addr).")
            } else {
                print("\(address) is not converted.")
            }
        }
        bindResult = withUnsafePointer(to: &addr) {
            bind(socketFileDescriptor,
                 UnsafePointer<sockaddr>(OpaquePointer($0)),
                 socklen_t(MemoryLayout<sockaddr_in>.size))
        }

        if bindResult == -1 {
            let details = ErrnoWrapper.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.bindFailed(details)
        }

        if listen(socketFileDescriptor, SOMAXCONN) == -1 {
            let details = ErrnoWrapper.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.listenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }

    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.acceptFailed(ErrnoWrapper.description())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
}
