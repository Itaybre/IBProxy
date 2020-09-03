//
//  SocketError.swift
//  IBProxy
//
//  Created by Itay Brenner on 9/2/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

public enum SocketError: Error, Equatable {
    case socketCreationFailed(String)
    case socketSettingReUseAddrFailed(String)
    case bindFailed(String)
    case listenFailed(String)
    case writeFailed(String)
    case getPeerNameFailed(String)
    case getNameInfoFailed(String)
    case acceptFailed(String)
    case recvFailed(String)
    case getSockNameFailed(String)
}
