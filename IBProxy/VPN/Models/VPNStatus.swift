//
//  VPNStatus.swift
//  IBProxy
//
//  Created by Itay Brenner on 8/12/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

enum VPNStatus: Int {
    case invalid
    case disconnected
    case connecting
    case connected
    case reasserting
    case disconnecting
}
