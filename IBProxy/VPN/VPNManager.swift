//
//  File.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import NetworkExtension

protocol VPNManagerDelegate: NSObjectProtocol {
    func vpnStatusDidChange(_ status: VPNStatus)
}

class VPNManager {
    static let shared = VPNManager()

    weak var delegate: VPNManagerDelegate?
    var status: VPNStatus = .disconnected
    private var tunnelManager: NETunnelProviderManager = NETunnelProviderManager()

    private init() {
        setup()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VPNManager.VPNStatusDidChange(_:)),
                                               name: NSNotification.Name.NEVPNStatusDidChange,
                                               object: nil)
    }

    func setup() {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            guard let managers = managers else {
                return
            }

            if managers.count > 0 {
                self.tunnelManager = managers[0]
            } else {
                self.tunnelManager = NETunnelProviderManager()
            }

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.serverAddress = "Your Device"

            self.tunnelManager.localizedDescription = "Proxy"
            self.tunnelManager.protocolConfiguration = tunnelProtocol
            self.tunnelManager.isEnabled = true

            self.tunnelManager.saveToPreferences { (error) in
                if error == nil {
                    self.tunnelManager.loadFromPreferences { (error) in
                        if error == nil {
                            self.VPNStatusDidChange(nil)
                        }
                    }
                }
            }
        }
    }

    func start() {
        if tunnelManager.connection.status == .disconnected || tunnelManager.connection.status == .disconnecting {
            do {
                try tunnelManager.connection.startVPNTunnel()
            } catch {
                NSLog("Error enabling")
            }
        }
    }

    func stop() {
        if tunnelManager.connection.status == .connected || tunnelManager.connection.status == .connecting {
            tunnelManager.connection.stopVPNTunnel()
        }
    }

    @objc
    func VPNStatusDidChange(_ notification: Notification?) {
        status = VPNStatus(rawValue: tunnelManager.connection.status.rawValue) ?? .invalid
        delegate?.vpnStatusDidChange(status)
    }
}
