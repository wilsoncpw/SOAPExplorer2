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
            guard let wsdl = objectValue as? WSDL else {
                return
            }
            
            textField?.stringValue = wsdl.serviceName
            label.stringValue = wsdl.url?.lastPathComponent ?? "Unknown"
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
