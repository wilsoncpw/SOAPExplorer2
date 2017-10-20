//
//  OperationsTableCellView.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 19/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class OperationsTableCellView: NSTableCellView {

    @IBOutlet weak var title: NSTextField!
    
    @IBOutlet weak var inputLabel: NSTextField!
    @IBOutlet weak var outputLabel: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func initialize () {
        guard let operation = objectValue as? BindingOperation else {
            title.stringValue = ""
            return
        }
        title.stringValue = operation.name
    }
    
}
