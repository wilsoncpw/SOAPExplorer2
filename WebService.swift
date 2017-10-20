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
    case notWSDL
    case missingTargetNamespace
    case noSingleServiceElement
    case noSingleTypesElement
    case noSinglePortTypeElement
    case missingNameAttribute
    case missingBindingInServicePort
    case noSingleAddressInServicePort
    case invalidNamespace
    case missingTypeInBinding
    case noSingleBindingInBinding
    case missingOperationForBinding
}

class WSDLObject {
    let targetNamespace: String
    let elem: CWXMLElement
    
    init (targetNamespace: String, elem: CWXMLElement) throws {
        self.elem = elem
        self.targetNamespace = targetNamespace
    }
}


class NamedWSDLObject: WSDLObject {
    
    let name: String
    let namespace: String
    let localName: String
    
    override init (targetNamespace: String, elem: CWXMLElement) throws {
        guard let attrName = elem.attribute(forName: "name") else {
            throw WSDLError.missingNameAttribute
        }
        self.name = attrName

        let qx = splitQName(qname: attrName)
        let _namespace = qx.prefix == "" ? targetNamespace : elem.namespace(forPrefix: qx.prefix)
        if _namespace == nil {
            throw WSDLError.invalidNamespace
        }
        namespace = _namespace!
        localName = qx.localName
        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
    
    func matchesQName (_ qname: String) -> Bool {
        let qx = splitQName(qname: qname)
        let _namespace = qx.prefix == "" ? targetNamespace : elem.namespace(forPrefix: qx.prefix)
        return qx.localName == localName && _namespace == namespace
    }
}

class MessagePart : NamedWSDLObject {
    
}

class Message: NamedWSDLObject {
    let messageParts : [MessagePart]
    
    init(targetNamespace: String, elem: CWXMLElement, wsdlUri: String) throws {
        let messagePartElements = elem.elements(forLocalName: "part", namespaceUri: wsdlUri)
        
        messageParts = try messagePartElements.map() {
            elem in
            return try MessagePart (targetNamespace: targetNamespace, elem: elem)
        }
        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
    
}

class PortTypeOperation : NamedWSDLObject {
    
}

class BindingOperation: NamedWSDLObject {
    
    let portTypeOperation: PortTypeOperation
    
    init (targetNamespace: String, elem: CWXMLElement, portType:PortType) throws {
        
        guard let attrName = elem.attribute(forName: "name") else {
            throw WSDLError.missingNameAttribute
        }
        
        guard let portTypeOperation = portType.findOperation(name: attrName) else {
            throw WSDLError.missingOperationForBinding
        }
    
        self.portTypeOperation = portTypeOperation
        try super.init (targetNamespace: targetNamespace, elem: elem)
    }
}

class Binding : NamedWSDLObject {
    
    let type: String
    let bindingOperations: [BindingOperation]
    
    init (targetNamespace: String, elem: CWXMLElement, portType: PortType) throws {
        
        guard let _type = elem.attribute(forName: "type") else {
            throw WSDLError.missingTypeInBinding
        }
        type = _type
        
/*
         let binding = try WebService.getSingleChild(elem: elem, localChildName: "binding", uri: nil, missingErr: .missingBindingInBinding, moreThanOneErr: .moreThanOneBindingInBinding)
        
        binding.prefix
 */
        
        let operationElements = elem.elements(forLocalName: "operation", namespaceUri: elem.namespaceUri)
        bindingOperations = try operationElements.map () {
            elem in
            return try BindingOperation (targetNamespace: targetNamespace, elem: elem, portType: portType)
        }
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
}

class ServicePort: NamedWSDLObject {
    let binding: Binding
    let url: String
    
    init (targetNamespace: String, elem: CWXMLElement, bindings: [Binding]) throws {
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
        
        let addressElem = try WebService.getSingleChild (elem: elem, localChildName: "address", uri: nil, error: .noSingleAddressInServicePort)
        
        guard let location = addressElem.attribute(forName: "location") else {
            throw WSDLError.noSingleAddressInServicePort
        }
        url = location
        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
}

class PortType: NamedWSDLObject {
    let operations: [PortTypeOperation]
    
    init (targetNamespace: String, elem: CWXMLElement, wsdlUri: String) throws {
        let operationElements = elem.elements(forLocalName: "operation", namespaceUri: wsdlUri)
        let _portTypeOperations = try operationElements.map () {
            elem in
            return try PortTypeOperation (targetNamespace: targetNamespace, elem: elem)
        }
        operations = _portTypeOperations
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
    
    func findOperation (name: String) -> PortTypeOperation? {
        return operations.first () {
            op in
            return op.name == name
        }
    }
}

class Service: NamedWSDLObject {
    let servicePorts: [ServicePort]
    
    init(targetNamespace: String, elem: CWXMLElement, wsdlUri: String, bindings: [Binding]) throws {
        
        servicePorts = try elem.elements(forLocalName: "port", namespaceUri: wsdlUri).map {
            elem in
            return try ServicePort.init(targetNamespace: targetNamespace, elem: elem, bindings: bindings)
        }
        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
}

class Types: WSDLObject {
    let schemas: [Schema]
    
    override init (targetNamespace: String, elem: CWXMLElement) throws {
        
        let schemaElements = elem.elements(forLocalName: "schema", namespaceUri: XSDURI)
        schemas = try Types.mapSchemaElementsToSchemas(schemaElements: schemaElements, targetNamespace: targetNamespace)
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
    
    static func mapSchemaElementsToSchemas (schemaElements: [CWXMLElement], targetNamespace: String) throws ->[Schema] {
        return try schemaElements.map() {
            elem in
            return try Schema (elem: elem, targetNamespace: targetNamespace)
        }
    }
}



class WebService {
    
    let wsdlTypes = ["http://www.w3.org/ns/wsdl":"WSDL2", "http://schemas.xmlsoap.org/wsdl/" :"WSDL1.1"]
    
    let doc: CWXMLDocument
    let url: URL?
    
    let wsdlType: String
    let targetNamespaceURI: String
    let service: Service
    let types: Types
    let messages: [Message]
    let portType: PortType
    let bindings: [Binding]
    
    init (doc: CWXMLDocument, url: URL) throws {
        self.doc = doc
        self.url = url
        
        guard let root = doc.rootElement else {
            throw WSDLError.notWSDL
        }
        
        guard let wsdlUri = root.resolveNamespace(forName: root.name) else {
            throw WSDLError.notWSDL
        }
        
        guard let _wsdlType =  wsdlTypes [wsdlUri] else {
            throw WSDLError.notWSDL
        }
        self.wsdlType = _wsdlType
        
        guard let _targetNamespaceURI = root.attribute(forName: "targetNamespace") else {
            throw WSDLError.notWSDL
        }
        self.targetNamespaceURI = _targetNamespaceURI
        
        
        let typesElement = try WebService.getSingleChild(elem: root, localChildName: "types", uri: wsdlUri, error: .noSingleTypesElement)
        types = try Types (targetNamespace: targetNamespaceURI, elem: typesElement)
        
        let messageElements = root.elements(forLocalName: "message", namespaceUri: wsdlUri)
        messages = try WebService.mapMessageElementsToMessages(elements: messageElements, targetNamespace: targetNamespaceURI, wsdlUri: wsdlUri)
        
        let portTypeElement = try WebService.getSingleChild(elem: root, localChildName: "portType", uri: wsdlUri, error: .noSinglePortTypeElement)
        portType = try PortType(targetNamespace: targetNamespaceURI, elem: portTypeElement, wsdlUri: wsdlUri)
        
        let bindingElements = root.elements(forLocalName: "binding", namespaceUri: wsdlUri)
        bindings = try WebService.mapBindingElementsToBindings(elements: bindingElements, targetNamespace: targetNamespaceURI, portType: portType)
        
        let serviceElement = try WebService.getSingleChild(elem: root, localChildName: "service", uri: wsdlUri, error: .noSingleServiceElement)
        service = try Service (targetNamespace: targetNamespaceURI, elem: serviceElement, wsdlUri: wsdlUri, bindings: bindings)
    }
    
    static fileprivate func getSingleChild (elem: CWXMLElement, localChildName: String, uri: String?, error: WSDLError) throws -> CWXMLElement {
        let elements = elem.elements(forLocalName: localChildName, namespaceUri: uri)
        
        guard let rv = elements.first else {
            throw error
        }
        if elements.count > 1 {
            throw error
        }
        return rv
    }
    
    static private func mapBindingElementsToBindings (elements: [CWXMLElement], targetNamespace: String, portType : PortType) throws -> [Binding] {
        return try elements.map () {
            elem in
            return try Binding (targetNamespace: targetNamespace, elem: elem, portType: portType)
        }
    }
    
    static private func mapMessageElementsToMessages (elements: [CWXMLElement], targetNamespace: String, wsdlUri: String) throws -> [Message] {
        return try elements.map () {
            elem in
            return try Message (targetNamespace: targetNamespace, elem: elem, wsdlUri: wsdlUri)
        }
    }
}
