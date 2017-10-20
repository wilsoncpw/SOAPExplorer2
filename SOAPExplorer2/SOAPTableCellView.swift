//
//  SOAPTableCellView.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 25/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class SOAPTableCellView: NSTableCellView {
    
    @IBOutlet weak var label: NSTextField!
    override var objectValue: Any? {
        didSet {
            guard let webService = objectValue as? WebService else {
                return
            }
            
            textField?.stringValue = webService.service.name
            label.stringValue = webService.url?.lastPathComponent ?? "Unknown"
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
