//
//  HomeViewController.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import UIKit

protocol HomeViewDelegate: NSObjectProtocol {
    func updateVPNStatus(_ status: VPNStatus)
}

class HomeViewController: UIViewController, HomeViewDelegate {

    @IBOutlet weak var vpnToggle: UISwitch!
    @IBOutlet weak var vpnLabel: UILabel!
    private let presenter = HomePresenter()

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.setViewDelegate(self)

        title = "IBProxy"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @IBAction func vpnToggleChanged(_ sender: Any) {
        presenter.vpnSwitchChanged(vpnToggle.isOn)
    }

    // MARK: - HomeViewDelegate

    func updateVPNStatus(_ status: VPNStatus) {
        vpnToggle.isOn = status == .connected || status == .connecting

        let statusLabel = [
            VPNStatus.connected: "Connected",
            VPNStatus.connecting: "Connecting",
            VPNStatus.disconnected: "Disconnected",
            VPNStatus.disconnecting: "Disconnecting",
            VPNStatus.invalid: "Invalid",
            VPNStatus.reasserting: "Reasserting"
        ]

        vpnLabel.text = statusLabel[status]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
