//
//  OperationsTableViewController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 19/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa
import CWXML

class OperationsTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    var currentOperation: BindingOperation? = nil {
        didSet {
            NotificationCenter.default.post(name: .onSelectOperation, object: currentOperation)
        }
    }
    
    @IBOutlet weak var operationsTableView: NSTableView!
    
    var currentServicePort: ServicePort? {
        didSet {
          operationsTableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .onSelectServicePort, object: nil, queue: nil) {
            notification in
            self.selectServicePort (notification.object as? ServicePort ?? nil)
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let servicePort = currentServicePort else {
            return 0
        }
        
        return servicePort.binding.bindingOperations.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let servicePort = currentServicePort else {
            return nil
        }
        let view = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self)
        
        if let v = view as? OperationsTableCellView {
            let bindingOp = servicePort.binding.bindingOperations [row]
            v.objectValue = bindingOp
            v.initialize ()
        }
        return view
    }
    
    private func selectServicePort (_ servicePort: ServicePort?) {
        currentServicePort = servicePort
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let servicePort = currentServicePort else {
            currentOperation = nil
            return
        }
        let row = operationsTableView.selectedRow
        currentOperation = row == -1 ? nil : servicePort.binding.bindingOperations [row]
    }
    
    
    
}
