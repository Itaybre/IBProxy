//
//  HomePresenter.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

class HomePresenter: NSObject, VPNManagerDelegate {
    weak private var homeViewDelegate: HomeViewDelegate?

    override init() {
        super.init()
        VPNManager.shared.delegate = self
    }

    func setViewDelegate(_ delegate: HomeViewDelegate) {
        homeViewDelegate = delegate
    }

    func vpnSwitchChanged(_ newValue: Bool) {
        if newValue {
            VPNManager.shared.start()
        } else {
            VPNManager.shared.stop()
        }
    }

    func vpnStatusDidChange(_ status: VPNStatus) {
        homeViewDelegate?.updateVPNStatus(status)
    }
}
