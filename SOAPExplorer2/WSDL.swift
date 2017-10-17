//
//  WSDL.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 24/05/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation
import CWXML

public enum WSDLError : Error {
    case fileNotFound
    case missingRoot
    case notWSDL
    case missingTargetNamespace
    case missingServiceElement
    case moreThanOneServiceElement
    case missingTypesElement
    case moreThanOneTypesElement
}

let wsdlTypes = ["http://www.w3.org/ns/wsdl":"WSDL2", "http://schemas.xmlsoap.org/wsdl/" :"WSDL1.1"]

class WSDL: CWXMLDocument {

    private (set) var url: URL? = nil
    
    private (set) var wsdlType: String = ""
    private var serviceElement: CWXMLElement? = nil
    private var typesElement: CWXMLElement? = nil
    
    private var targetNamespaceURI  = ""
    
    required init() {
        super.init()
    }
    
    override func noteURL(url: URL?) {
        self.url = url
    }
    var serviceName: String {
        return serviceElement?.attribute (forName: "name") ?? "Unknown"
    }
    
    func parse () throws {
        
        
        
        guard let root = rootElement else {
            throw WSDLError.missingRoot
        }
        
        let rootName = root.name
        
        guard let rootNamespaceURI = root.resolveNamespace(forName: rootName) else {
            throw WSDLError.notWSDL
        }
        
        guard let wsdlType =  wsdlTypes [rootNamespaceURI] else {
            throw WSDLError.notWSDL
        }
        self.wsdlType = wsdlType
        
        guard let targetNamespaceURI = root.attribute(forName: "targetNamespace") else {
            throw WSDLError.missingTargetNamespace
        }
        self.targetNamespaceURI = targetNamespaceURI
        


        let serviceElements = root.elements(forLocalName: "service", uri: rootNamespaceURI)
        guard let serviceElement = serviceElements.first else {
            throw WSDLError.missingServiceElement
        }
        if serviceElements.count > 1 {
            throw WSDLError.moreThanOneServiceElement
        }
        self.serviceElement = serviceElement
        
        let typesElements = root.elements(forLocalName: "types", uri: rootNamespaceURI)
        guard let typesElement = typesElements.first else {
            throw WSDLError.missingTypesElement
        }
        if typesElements.count > 1 {
            throw WSDLError.moreThanOneTypesElement
        }
        self.typesElement = typesElement
        
        
        let messageElements = root.elements(forLocalName: "message", uri: rootNamespaceURI)
 

    }
}
