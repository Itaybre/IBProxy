//
//  ErrnoWrapper.swift
//  IBProxy
//
//  Created by Itay Brenner on 9/2/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

internal class ErrnoWrapper {
    public class func description() -> String {
        return String(cString: strerror(errno))
    }
}
