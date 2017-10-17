//
//  SOAPExplorer2Data.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation

class SOAPExplorer2Data {
    static let instance = SOAPExplorer2Data ()
    
    private (set) var wsdls = [WSDL] ()
    
    private init () {
        
    }
    
    func addWSDL (wsdl: WSDL) {
        wsdls.append(wsdl)
    }
}
