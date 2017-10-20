//
//  AppDelegate.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa
import CWXML

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ImportXSDDelegate {
    func getURLForXSD(fileName: String, suggessted: URL?) -> URL? {
        
        let openPanel = NSOpenPanel ()
        
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.directoryURL = suggessted
        
        openPanel.message = "Select directory that contains the schema " + fileName
        
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            return openPanel.url?.appendingPathComponent(fileName)
        }
        
        return nil
    }
    
    
    let data = SOAPExplorer2Data.instance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        soapExplorerData.importXSDDelegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func openDocument (_ sender: AnyObject) {
        let openPanel = NSOpenPanel ()
        
        openPanel.allowedFileTypes = ["wsdl"]
        
        if openPanel.runModal().rawValue == NSFileHandlingPanelOKButton {
            if let url = openPanel.url {
                if !reset () {
                    return
                }
                openWSDLDocument (url: url)
            }
        }
    }
    
    // openFile is called by File Open Recent
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if reset () {
            let url = URL (fileURLWithPath: filename)
            openWSDLDocument (url: url)
        }
        return true
    }
    
    private func reset () -> Bool {
        return true
    }
    
    private func openWSDLDocument (url: URL) {
        do {
            
            try data.loadWebService(url: url)
            
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            NotificationCenter.default.post(name: .onLoaded, object: nil)
    
        } catch (let e) {
            print (e)
        }
        
        
    }


    
}

