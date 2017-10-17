//
//  MainWindowController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.setFrameAutosaveName(NSWindow.FrameAutosaveName ("SoapExplorer2")) // Doesn't work if you set it in IB (!)
    }
}
