//
//  ServiceViewController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 16/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class ServiceViewController: NSViewController {
    
    @objc dynamic var serviceName = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: .onLoaded, object: nil, queue: nil) {
            notification in
            self.selectService (wsdl: nil)
        }
        
        NotificationCenter.default.addObserver(forName: .onSelectService, object: nil, queue: nil) {
            notification in
            self.selectService(wsdl: notification.object as? WSDL ?? nil)
        }
    }
    
    private func selectService (wsdl: WSDL?) {
        if let wsdl = wsdl {
            serviceName = wsdl.serviceName
        } else {
            serviceName = ""
        }
    }
    
}
