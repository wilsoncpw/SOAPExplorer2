//
//  SOAPFunctionCallViewController.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 28/11/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Cocoa
import CWXML
import CWPrettyXML

class SOAPFunctionCallViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    var minRequestCellWidth: CGFloat = 0
    var minResponseCellWidth: CGFloat = 0
    var currentRequestDoc: CWXMLDocument?
    var currentResponseDoc: CWXMLDocument?
    var currentWebService: WebService?
    var currentRequestPrettyNodeMap: PrettyNodeMap? = nil {
        didSet {
            SOAPRequestXMLTable.reloadData()
        }
    }
    
    var currentResponsePrettyNodeMap: PrettyNodeMap? = nil {
        didSet {
            SOAPResponseXMLTable.reloadData()
        }
    }

    @IBOutlet weak var SOAPRequestXMLTable: NSTableView!
    @IBOutlet weak var SOAPResponseXMLTable: NSTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .onSelectOperation, object: nil, queue: nil) {
            notification in
            
            let op: BindingOperation? = notification.object as? BindingOperation ?? nil
            self.setBindingOperation (op)
        }
        
        NotificationCenter.default.addObserver(forName: .onSelectService, object: nil, queue: nil) {
            notification in
            self.selectService(webService: notification.object as? WebService ?? nil)
        }
    }
    
    func selectService (webService: WebService?) {
        currentRequestPrettyNodeMap = nil
        currentResponsePrettyNodeMap = nil
        currentWebService = webService
    }
    
    func setBindingOperation (_ op: BindingOperation?) {
        if let operation = op, let webService = currentWebService {
            let inputMessage = operation.portTypeOperation.inputMessage
            let outputMessage = operation.portTypeOperation.outputMessage
            
            let requestDoc = CWXMLDocument ()
            do {
                let requestElem = CWXMLElement (name: "Body") //, attributes: ["xmlns": inputMessage.namespace])
                try requestDoc.setRootElement(elem: requestElem)

                
                for part in inputMessage.messageParts {
                    guard let schemaElem = part.schemaObj as? SchemaElement else {
                        currentRequestDoc = nil
                        return
                    }
                    
                    if let stubElems = schemaElem.generateXMLStub (types: webService.types) {
                        
                        for se in stubElems {
                            try requestElem.appendChildElement(elem: se)
                        }
                    }
                }
            } catch {
            }
            currentRequestDoc = requestDoc
            
            if let outputMessage = outputMessage {
                let responseDoc = CWXMLDocument ()
                do {
                    let responseElem = CWXMLElement (name: "Body") //, attributes: ["xmlns": outputMessage.namespace])
                    try responseDoc.setRootElement(elem: responseElem)
                    
                    
                    for part in outputMessage.messageParts {
                        guard let schemaElem = part.schemaObj as? SchemaElement else {
                            currentResponseDoc = nil
                            return
                        }
                        
                        if let stubElems = schemaElem.generateXMLStub (types: webService.types) {
                            
                            for se in stubElems {
                                try responseElem.appendChildElement(elem: se)
                            }
                        }
                    }
                } catch {
                }
                currentResponseDoc = responseDoc
            } else {
                currentResponseDoc = nil
            }
        } else {
            currentResponseDoc = nil
        }
        
        if let rootElement = currentRequestDoc?.rootElement {
            let p = PrettyNodeMap ()
            p.mapXMLElement(elem: rootElement)
            currentRequestPrettyNodeMap = p
        } else {
            currentRequestPrettyNodeMap = nil
        }
        
        if let rootElement = currentResponseDoc?.rootElement {
            let p = PrettyNodeMap ()
            p.mapXMLElement(elem: rootElement)
            currentResponsePrettyNodeMap = p
        } else {
            currentResponsePrettyNodeMap = nil
        }
        
        minRequestCellWidth = 0
        minResponseCellWidth = 0
    }
    
    private func getPrettyNodeMapForTable (table: NSTableView) -> PrettyNodeMap? {
        let rv: PrettyNodeMap?
        
        if table == SOAPRequestXMLTable {
            rv = currentRequestPrettyNodeMap
        } else if table == SOAPResponseXMLTable {
            rv = currentResponsePrettyNodeMap
        } else {
            rv = nil
        }
        return rv
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let nodeMap = getPrettyNodeMapForTable(table: tableView) else {
            return 0
        }
        return nodeMap.prettyNodeCount
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let nodeMap = getPrettyNodeMapForTable(table: tableView) else {
            return nil
        }
        
        if let ps = nodeMap.prettyNodeString(idx: row) {
            let rv: NSAttributedString
            
            if ps.level == 0 {
                rv = ps.st
            } else {
                let s = NSMutableAttributedString (string: String(repeating: " ", count: ps.level * 3))
                s.append (ps.st)
                rv = s
            }
            
            let w = rv.size ().width + CGFloat (rv.string.count) // Goodness knows why we need to add the string length (!)
            
            if tableView === SOAPRequestXMLTable {
                if w > minRequestCellWidth {
                    minRequestCellWidth = w
                    tableColumn?.width = w
                }
            } else {
                if w > minResponseCellWidth {
                    minResponseCellWidth = w
                    tableColumn?.width = w
                }
            }
            return rv
        } else {
            return "??"
        }
    }
}
