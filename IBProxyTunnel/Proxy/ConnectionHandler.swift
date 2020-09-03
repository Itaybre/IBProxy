//
//  ConnectionHandler.swift
//  IBProxyTunnel
//
//  Created by Itay Brenner on 8/17/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class ConnectionHandler: NSObject {
    let clientSocket: GCDAsyncSocket

    init(_ inSocket: GCDAsyncSocket) {
        self.clientSocket = inSocket
        super.init()

    }

    func handle() {

    }
}
