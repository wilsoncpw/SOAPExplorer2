//
//  ServiceViewController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 16/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class ServiceViewController: NSViewController, NSComboBoxDelegate, NSComboBoxDataSource {
    
    @IBOutlet weak var servicePortsCombo: NSComboBox!
    
    var currentService: WebService? = nil {
        didSet {
            hasWebService = currentService != nil
        }
    }
    
    @objc dynamic var serviceName = ""
    @objc dynamic var wsdlName = ""
    @objc dynamic var hasWebService = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: .onLoaded, object: nil, queue: nil) {
            notification in
            self.selectService (webService: nil)
        }
        
        NotificationCenter.default.addObserver(forName: .onSelectService, object: nil, queue: nil) {
            notification in
            self.selectService(webService: notification.object as? WebService ?? nil)
        }
    }
    
    private func selectService (webService: WebService?) {
        currentService = webService
        if let webService = webService {
            serviceName = webService.serviceName
            wsdlName = webService.url?.path ?? ""
        } else {
            serviceName = ""
            wsdlName = ""
        }
        
        servicePortsCombo.reloadData()
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return currentService?.servicePortObjects.count ?? 0
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return currentService?.servicePortObjects [index].name
    }
    
}
