//
//  TunnelConfiguration.swift
//  IBProxyTunnel
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import NetworkExtension

class TunnelConfiguration {
    private struct Settings {
        static let mtu: NSNumber = 1400
        static let localhost = "127.0.0.1"
        static let proxyHost = "localhost"
        static let proxyHTTPPort = 12344
        static let proxyHTTPSPort = 12345
        static let ipv4IP = "192.168.255.255"
        static let subnetMask = "255.255.255.0"
        static let ipv6IP = "192.168.255.255"
    }

    static func getSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: Settings.localhost)
        settings.mtu = Settings.mtu

        settings.ipv4Settings = NEIPv4Settings(addresses: [Settings.ipv4IP], subnetMasks: [Settings.subnetMask])
        settings.ipv6Settings = NEIPv6Settings(addresses: [Settings.ipv6IP], networkPrefixLengths: [96])

        settings.proxySettings = NEProxySettings()
        settings.proxySettings?.excludeSimpleHostnames = true
        settings.proxySettings?.httpServer = NEProxyServer(address: Settings.proxyHost, port: Settings.proxyHTTPPort)
        settings.proxySettings?.httpEnabled = true
        settings.proxySettings?.httpsServer = NEProxyServer(address: Settings.proxyHost, port: Settings.proxyHTTPSPort)
        settings.proxySettings?.httpsEnabled = true
        settings.proxySettings?.matchDomains = [""]
        settings.proxySettings?.exceptionList = [
            "192.168.0.0/16",
            "10.0.0.0/8",
            "172.16.0.0/12",
            "127.0.0.1",
            "localhost",
            "*.local"
        ]

        return settings
    }
}
