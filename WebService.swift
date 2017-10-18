//
//  WebService.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 17/10/2017.
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
    case missingPortTypeElement
    case moreThanOnePortTypeElement
    case missingNameAttribute
    case missingBindingInServicePort
    case invalidNamespace
}


class NamedWSDLObject {
    
    let targetNamespace: String
    let name: String
    let elem: CWXMLElement
    let namespace: String
    let localName: String
    
    init (targetNamespace: String, elem: CWXMLElement) throws {
        guard let attrName = elem.attribute(forName: "name") else {
            throw WSDLError.missingNameAttribute
        }
        self.name = attrName
        self.elem = elem
        self.targetNamespace = targetNamespace
        
        let qx = splitQName(qname: attrName)
        let _namespace = qx.prefix == "" ? targetNamespace : elem.namespace(forPrefix: qx.prefix)
        if _namespace == nil {
            throw WSDLError.invalidNamespace
        }
        namespace = _namespace!
        localName = qx.localName
    }
    
    func matchesQName (_ qname: String) -> Bool {
        let qx = splitQName(qname: qname)
        let _namespace = qx.prefix == "" ? targetNamespace : elem.namespace(forPrefix: qx.prefix)
        return qx.localName == localName && _namespace == namespace
    }
}

class BindingWSDLObject: NamedWSDLObject {
    
}

class ServicePortWSDLObject: NamedWSDLObject {
    let binding: BindingWSDLObject
    
    init (targetNamespace: String, elem: CWXMLElement, bindings: [BindingWSDLObject]) throws {
        guard let bindingName = elem.attribute(forName: "binding") else {
            throw WSDLError.missingBindingInServicePort
        }
        
        let _bindingObj = bindings.first {
            obj in
            return obj.matchesQName(bindingName)
        }
        
        guard let bindingObj = _bindingObj else {
            throw WSDLError.missingBindingInServicePort
        }
        
        binding = bindingObj
    
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
}



class WebService {
    
    let wsdlTypes = ["http://www.w3.org/ns/wsdl":"WSDL2", "http://schemas.xmlsoap.org/wsdl/" :"WSDL1.1"]
    
    let doc: CWXMLDocument
    let url: URL?
    
    let wsdlType: String
    let targetNamespaceURI: String
    let serviceElement: CWXMLElement
    let typesElement: CWXMLElement
    let messageElements: [CWXMLElement]
    let portTypeElement: CWXMLElement
    let operationElements: [CWXMLElement]
    let bindingObjects: [BindingWSDLObject]
    let servicePortObjects: [ServicePortWSDLObject]
    
    init (doc: CWXMLDocument, url: URL) throws {
        self.doc = doc
        self.url = url
        
        guard let root = doc.rootElement else {
            throw WSDLError.missingRoot
        }
        
        let rootName = root.name
        
        guard let wsdlUri = root.resolveNamespace(forName: rootName) else {
            throw WSDLError.notWSDL
        }
        
        guard let wsdlType =  wsdlTypes [wsdlUri] else {
            throw WSDLError.notWSDL
        }
        self.wsdlType = wsdlType
        
        guard let targetNamespaceURI = root.attribute(forName: "targetNamespace") else {
            throw WSDLError.missingTargetNamespace
        }
        self.targetNamespaceURI = targetNamespaceURI
        
        serviceElement = try WebService.getSingleChild(elem: root, localChildName: "service", uri: wsdlUri, missingErr: .missingServiceElement, moreThanOneErr: .moreThanOneServiceElement)
        typesElement = try WebService.getSingleChild(elem: root, localChildName: "types", uri: wsdlUri, missingErr: .missingTypesElement, moreThanOneErr: .moreThanOneTypesElement)

        
        messageElements = root.elements(forLocalName: "message", uri: wsdlUri)
        
        portTypeElement = try WebService.getSingleChild(elem: root, localChildName: "portType", uri: wsdlUri, missingErr: .missingPortTypeElement, moreThanOneErr: .moreThanOnePortTypeElement)
        operationElements = portTypeElement.elements(forLocalName: "operation", uri: wsdlUri)
        let _bindingObjects = try root.elements(forLocalName: "binding", uri: wsdlUri).map {
            elem in
            return try BindingWSDLObject.init(targetNamespace: targetNamespaceURI, elem: elem)
        }
        bindingObjects = _bindingObjects
        
        servicePortObjects = try serviceElement.elements(forLocalName: "port", uri: wsdlUri).map {
            elem in
            return try ServicePortWSDLObject.init(targetNamespace: targetNamespaceURI, elem: elem, bindings: _bindingObjects)
        }
    }
    
    private static func getSingleChild (elem: CWXMLElement, localChildName: String, uri: String, missingErr: WSDLError, moreThanOneErr: WSDLError) throws -> CWXMLElement {
        let elements = elem.elements(forLocalName: localChildName, uri: uri)
        
        guard let rv = elements.first else {
            throw missingErr
        }
        if elements.count > 1 {
            throw moreThanOneErr
        }
        return rv
    }
    
    var serviceName: String {
        return serviceElement.localName
    }
}
