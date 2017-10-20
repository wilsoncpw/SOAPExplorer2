//
//  Notifications.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let onLoaded = Notification.Name ("loaded")
    static let onSelectService = Notification.Name ("selectService")
    static let onSelectServicePort = Notification.Name ("selectServicePort")
}
