//
//  SOAPTableViewController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 25/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class SOAPTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    let data = SOAPExplorer2Data.instance

    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: .onLoaded, object: nil, queue: nil) {
            notification in
            self.tableView.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.wsdls.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var rv : NSView? = nil
        if let id = tableColumn?.identifier, let view = tableView.makeView(withIdentifier: id, owner: tableView) as? SOAPTableCellView {
            
            view.objectValue = data.wsdls [row]
            rv = view
        }
        
        return rv
    }
    
    @IBAction func tableViewAction(_ sender: Any) {
        selectService (idx: tableView.selectedRow)
    }
    
    private func selectService (idx: Int) {
        guard idx >= 0 && idx < data.wsdls.count else {
            NotificationCenter.default.post(name: .onSelectService, object: nil)
            return
        }
        NotificationCenter.default.post(name: .onSelectService, object: data.wsdls [idx])
    }
}
