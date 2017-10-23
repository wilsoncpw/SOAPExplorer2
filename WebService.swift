//
//  WebService.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 17/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation
import CWXML

struct WebServiceError: Error {
    let message: String
    init (_ message: String) {
        self.message = message
    }
    
    var localizedDescription: String {
        return message
    }
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
            throw WebServiceError ("Named Object \(elem.name) missing name attribute")
        }
        self.name = attrName

        let qx = splitQName(qname: attrName)
        let _namespace = qx.prefix == "" ? targetNamespace : elem.namespace(forPrefix: qx.prefix)
        if _namespace == nil {
            throw WebServiceError ("Undefined namespace in name attribute for \(elem.name)")
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
    let inputMessage: Message
    let outputMessage: Message?
    
    init(targetNamespace: String, elem: CWXMLElement, wsdlUri: String, messages: [Message]) throws {
        
        let inputMessageElement = try WebService.getSingleChild(elem: elem, localChildName: "input", uri: wsdlUri, error: "Expecting single input message in Port Type")
        guard let messageName = inputMessageElement.attribute(forName: "message") else {
            throw WebServiceError ("Input message for Port Type has no 'message' attribute")
        }
        let im = messages.first(where:) {
            message in
            return message.matchesQName(messageName)
        }
        guard let imx = im else {
            throw WebServiceError ("Undefined input message \(messageName) in Port Type")
        }
        inputMessage = imx
        
        let outputElements = elem.elements(forLocalName: "output", namespaceUri: wsdlUri)
        if let outputElement = outputElements.first {
            guard let messageName = outputElement.attribute(forName: "message") else {
                throw WebServiceError ("Output message name not defined for Port Type")
            }
            
            let om = messages.first(where:) {
                message in
                return message.matchesQName(messageName)
            }
            guard let omx = om else {
                throw WebServiceError ("Undefined output mesage \(messageName) for Port Type")
            }
            outputMessage = omx
        } else {
            outputMessage = nil
        }

        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
    
}

class BindingOperation: NamedWSDLObject {
    
    let portTypeOperation: PortTypeOperation
    
    init (targetNamespace: String, elem: CWXMLElement, portType:PortType) throws {
        
        guard let attrName = elem.attribute(forName: "name") else {
            throw WebServiceError ("Binding Operation for Port Type \(portType.name) missing name attribute")
        }
        
        guard let portTypeOperation = portType.findOperation(name: attrName) else {
            throw WebServiceError ("Undefined operation \(attrName) in Binding Operation for PortType \(portType.name)")
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
            throw WebServiceError ("Binding messaging 'type' atribute")
        }
        type = _type
        
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
            throw WebServiceError ("Service Port missing 'binding' attribute")
        }
        
        let _bindingObj = bindings.first {
            obj in
            return obj.matchesQName(bindingName)
        }
        
        guard let bindingObj = _bindingObj else {
            throw WebServiceError ("Undefined binding \(bindingName) in Service Port")
        }
        
        binding = bindingObj
        
        let addressElem = try WebService.getSingleChild (elem: elem, localChildName: "address", uri: nil, error: "Single 'address' element expected in Service Port definition")
        
        guard let location = addressElem.attribute(forName: "location") else {
            throw WebServiceError ("Address element in Service Port definition requires 'location' attribute")
        }
        url = location
        
        try super.init(targetNamespace: targetNamespace, elem: elem)
    }
}

class PortType: NamedWSDLObject {
    let operations: [PortTypeOperation]
    
    init (targetNamespace: String, elem: CWXMLElement, wsdlUri: String, messages: [Message]) throws {
        let operationElements = elem.elements(forLocalName: "operation", namespaceUri: wsdlUri)
        let _portTypeOperations = try operationElements.map () {
            elem in
            return try PortTypeOperation (targetNamespace: targetNamespace, elem: elem, wsdlUri: wsdlUri, messages: messages)
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
        guard let root = doc.rootElement, let wsdlUri = root.resolveNamespace(forName: root.name) else {
            throw WebServiceError ("Not a web service document")
        }
        
        guard let _wsdlType =  wsdlTypes [wsdlUri] else {
            throw WebServiceError ("Unsupported web service format \(wsdlUri)")
        }
        
        self.doc = doc
        self.url = url
        self.wsdlType = _wsdlType
        self.targetNamespaceURI = root.attribute(forName: "targetNamespace") ?? ""
        
        let typesElement = try WebService.getSingleChild(elem: root, localChildName: "types", uri: wsdlUri, error: "Single 'types' element expected")
        types = try Types (targetNamespace: targetNamespaceURI, elem: typesElement)
        
        let messageElements = root.elements(forLocalName: "message", namespaceUri: wsdlUri)
        messages = try WebService.mapElementsToMessages(elements: messageElements, targetNamespace: targetNamespaceURI, wsdlURI: wsdlUri)
        
        let portTypeElement = try WebService.getSingleChild(elem: root, localChildName: "portType", uri: wsdlUri, error: "Single 'portType' element expected")
        portType = try PortType(targetNamespace: targetNamespaceURI, elem: portTypeElement, wsdlUri: wsdlUri, messages: messages)
        
        let bindingElements = root.elements(forLocalName: "binding", namespaceUri: wsdlUri)
        bindings = try WebService.mapElementsToBindings(elements: bindingElements, targetNamespace: targetNamespaceURI, portType: portType)
        
        let serviceElement = try WebService.getSingleChild(elem: root, localChildName: "service", uri: wsdlUri, error: "Single 'service' element expected")
        service = try Service (targetNamespace: targetNamespaceURI, elem: serviceElement, wsdlUri: wsdlUri, bindings: bindings)
    }
    
    static private func mapElementsToMessages (elements: [CWXMLElement], targetNamespace: String, wsdlURI : String) throws -> [Message] {
        return try elements.map() {
            elem in
            return try Message (targetNamespace: targetNamespace, elem: elem, wsdlUri: wsdlURI)
        }
    }
    
    static private func mapElementsToBindings (elements: [CWXMLElement], targetNamespace: String, portType: PortType) throws -> [Binding] {
        return try elements.map() {
            elem in
            return try Binding (targetNamespace: targetNamespace, elem: elem, portType: portType)
        }
    }
    
    static fileprivate func getSingleChild (elem: CWXMLElement, localChildName: String, uri: String?, error: String) throws -> CWXMLElement {
        let elements = elem.elements(forLocalName: localChildName, namespaceUri: uri)
        
        guard let rv = elements.first else {
            throw WebServiceError (error)
        }
        if elements.count > 1 {
            throw WebServiceError (error)
        }
        return rv
    }
}
