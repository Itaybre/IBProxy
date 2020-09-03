//
//  PacketTunnelProvider.swift
//  IBProxyTunnel
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    var httpProxy: HTTPProxy!
    var httpsProxy: HTTPProxy!

    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        httpProxy = HTTPProxy(port: 12344)
        httpsProxy = HTTPProxy(port: 12345)

        httpProxy.startAccepting()
        httpsProxy.startAccepting()

        let settings = TunnelConfiguration.getSettings()

        setTunnelNetworkSettings(settings) { error in
            if let err = error {
                NSLog("Settings error %@", err.localizedDescription)
                completionHandler(err)
            } else {
                completionHandler(nil)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        httpProxy.stop()
        httpsProxy.stop()
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        httpProxy.stop()
        httpsProxy.stop()
        completionHandler()
    }

    override func wake() {
        httpProxy.startAccepting()
        httpsProxy.startAccepting()
    }
}
