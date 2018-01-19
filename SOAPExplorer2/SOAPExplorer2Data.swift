//
//  SOAPExplorer2Data.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation
import CWXML

let soapExplorerData = SOAPExplorer2Data.instance

protocol ImportXSDDelegate: NSObjectProtocol {
    func getURLForXSD (fileName: String, suggessted: URL?) -> URL?
}

class SOAPExplorer2Data {
    weak var importXSDDelegate : ImportXSDDelegate?
    
    static let instance = SOAPExplorer2Data ()
    
    private (set) var webServices = [WebService] ()
    
    private init () {
        
    }
    
    func loadWebService (url: URL) throws {
        let doc = try CWXMLParser.init(url: url).parse()
        let webService = try WebService.init(doc: doc, url: url)
        webServices.append (webService)
    }
    
    
}
