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
    
    var currentServicePort: ServicePort? = nil {
        didSet {
            servicePortAddress = currentServicePort?.url ?? ""
            
            NotificationCenter.default.post(name: .onSelectServicePort, object: currentServicePort)
        }
    }
    
    @objc dynamic var serviceName = ""
    @objc dynamic var wsdlName = ""
    @objc dynamic var hasWebService = false
    @objc dynamic var servicePortAddress = ""
    
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
            serviceName = webService.service.name
            wsdlName = webService.url?.path ?? ""
        } else {
            serviceName = ""
            wsdlName = ""
        }
        
        servicePortsCombo.reloadData()
        servicePortsCombo.selectItem(at: 0)
        setServicePort (idx: 0)
    }
    
    private func setServicePort (idx: Int) {
        guard let currentService = currentService, idx < currentService.service.servicePorts.count else {
            currentServicePort = nil
            return
        }
        
        currentServicePort = currentService.service.servicePorts [idx]
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return currentService?.service.servicePorts.count ?? 0
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return currentService?.service.servicePorts [index].name
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        setServicePort (idx: servicePortsCombo.indexOfSelectedItem)
    }
    
}
