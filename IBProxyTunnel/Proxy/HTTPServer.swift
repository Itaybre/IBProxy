//
//  HTTPServer.swift
//  IBProxyTunnel
//
//  Created by Itay Brenner on 8/17/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class HTTPProxy: NSObject {
    let dispatchQueue: DispatchQueue
    let listener: GCDAsyncSocket
    let port: Int

    init(port: Int) {
        self.port = port
        self.dispatchQueue = DispatchQueue(label: "httpServer")
        self.listener = GCDAsyncSocket(delegate: nil, delegateQueue: self.dispatchQueue)
        super.init()
        self.listener.delegate = self
    }

    func startAccepting() {
        do {
            try listener.accept(onPort: UInt16(port))
            NSLog("\(String(describing: self)) on port: \(port)")
        } catch {
            NSLog("Error on Accept")
        }
    }

    func stop() {
        listener.setDelegate(nil, delegateQueue: nil)
        listener.disconnect()
    }
}

extension HTTPProxy: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        NSLog("New HTTP Connection")
    }
}
