//
//  XMLSchema.swift
//  SOAPExplorer2
//
//  Created by Colin Wilson on 20/10/2017.
//  Copyright © 2017 Colin Wilson. All rights reserved.
//

import Foundation
import CWXML

public let XSDURI = "http://www.w3.org/2001/XMLSchema"
public let XSDIURI = "http://www.w3.org/2001/XMLSchema-instance"

public enum SchemaError : Error {
    case notASchemaElement
    case unexpectedElementInSchema
    case missingNameAttribute
    case missingBaseAttribute
    case missingSchemaLocation
    case missingEnumerationValue
}

private class RestrictionStubElement: CWXMLElement {
}

public class SchemaObject {
    public let xmlElement: CWXMLElement
    public let name: String?
    public let targetNamespace: String?
    public var elements = [SchemaObject] ()
    
    public init (xmlElement: CWXMLElement, allowedChildren: Set <String>, targetNamespace: String?) throws {
        self.xmlElement = xmlElement
        self.name = xmlElement.attribute(forName: "name")
        self.targetNamespace = targetNamespace
        
        if xmlElement.namespaceUri != XSDURI {
            throw SchemaError.notASchemaElement
        }
        
        if allowedChildren == ["*"] {
            return
        }
        
        guard let children = xmlElement.childElements else {
            return
        }
        
        for c in children {
            switch c.localName {
            case "any":
                continue;
            case "import":
                if let impElem = try SchemaObject.importSchema(elem: c) {
                    elements.append(impElem)
                }
                continue
            case "annotation":
                continue
            default:
                break
            }
            
            if !allowedChildren.contains(c.localName) {
                throw SchemaError.unexpectedElementInSchema
            }
            
            switch c.localName {
            case "schema":
                try elements.append(Schema (elem:c, targetNamespace: targetNamespace))
            case "element":
                try elements.append(SchemaElement (elem:c, targetNamespace: targetNamespace))
            case "complexType":
                try elements.append(SchemaComplexType (elem:c, targetNamespace: targetNamespace))
            case "simpleContent":
                try elements.append(SchemaSimpleContent (elem:c, targetNamespace: targetNamespace))
            case "complexContent":
                try elements.append(SchemaComplexContent (elem:c, targetNamespace: targetNamespace))
            case "extension":
                try elements.append(SchemaExtension (elem:c, targetNamespace: targetNamespace))
            case "restriction":
                try elements.append(SchemaRestriction (elem:c, targetNamespace: targetNamespace))
            case "sequence":
                try elements.append(SchemaSequence (elem:c, targetNamespace: targetNamespace))
            case "attribute":
                try elements.append(SchemaAttribute (elem:c, targetNamespace: targetNamespace))
            case "simpleType":
                try elements.append(SchemaSimpleType (elem:c, targetNamespace: targetNamespace))
            case "union":
                try elements.append(SchemaUnion (elem:c, targetNamespace: targetNamespace))
            case "enumeration":
                if let r = self as? SchemaRestriction {
                    try elements.append(SchemaEnumeration (elem: c, targetNamespace: targetNamespace, baseType: r.base))
                }
            default:
                print ("Unexpected ", c.name)
            }
        }
    }
    
    func generateXMLStub (types: Types)-> [CWXMLElement]? {
        var rv = [CWXMLElement] ()
        for e in elements {
            if let eStub = e.generateXMLStub(types: types) {
                for es in eStub {
                    rv.append(es)
                }
            }
        }
        
        return rv.count == 0 ? nil : rv
    }
    
    static func importSchema (elem: CWXMLElement) throws -> Schema? {
        
        guard let schemaLocation = elem.attribute(forName: "schemaLocation") else {
            return nil
        }
        
        guard let docURL = elem.document?.url else {
            throw SchemaError.missingSchemaLocation
        }
        
        guard var schemaURL = URL (string: schemaLocation) else {
            throw SchemaError.missingSchemaLocation
        }
        
        guard let delegate = soapExplorerData.importXSDDelegate else {
            throw SchemaError.missingSchemaLocation
        }
        
        if let query = schemaURL.query {
            if var idx = query.firstIndex(of: "=") {
                idx = query.index(idx, offsetBy: 1)
                let ext = String (query [idx...])
                schemaURL.deletePathExtension()
                schemaURL.appendPathExtension(ext)
            }
        }
        
        let fileName = schemaURL.lastPathComponent;

        var importURL = docURL.deletingLastPathComponent().appendingPathComponent(fileName)
        
        var data = try? Data (contentsOf:importURL)
        
        while data == nil {
            guard let newURL = delegate.getURLForXSD(fileName: fileName, suggessted: docURL.deletingLastPathComponent()) else {
                throw SchemaError.missingSchemaLocation
            }
            importURL = newURL
            data = try? Data (contentsOf: importURL)
        }
                
        let schemaDoc = try CWXMLParser (data: data!).parse ();
        schemaDoc.noteURL(url: importURL)
        
        guard let rootElement = schemaDoc.rootElement else {
            throw SchemaError.missingSchemaLocation
        }
        
        let targetNamespace = rootElement.attribute(forName: "targetNamespace")
        
        return try Schema (elem: rootElement, targetNamespace: targetNamespace)
    }
    
    // nb - can't currently say 'if x is y' in Swift where y is a type variable.  So this
    // grubby function - overwritten in SchemaElement and SchemaTypeBase is required
    func isInstanceOf (type: SchemaObject.Type)->Bool {
        return type == SchemaObject.self
    }
}
    
public class SchemaElement: SchemaObject {
    public let type: String?
    public let ref: String?
    
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        type = elem.attribute(forName: "type")
        ref = elem.attribute(forName: "ref")
        
        try super.init(xmlElement: elem, allowedChildren: ["simpleType", "complexType"], targetNamespace: targetNamespace)
        
        if elem.parentElement?.name == "schema" {
            if elem.attribute(forName: "name") == nil {
                throw SchemaError.missingNameAttribute
            }
        }
    }
    
    override func generateXMLStub (types: Types)->[CWXMLElement]? {
        guard let name = name else {
            return super.generateXMLStub(types: types)
        }
        
        let e = CWXMLElement (name: name, attributes: ["xmlns": self.targetNamespace!])
        
        if let type = self.type {
            debugPrint("GenerateXMLStub for ", name, ":", type)

            
            
            let s = splitQName(qname: type)
            
            guard let typeNSURI = xmlElement.namespace(forPrefix: s.prefix) else {
                return super.generateXMLStub(types: types)
            }
            
            if typeNSURI == XSDURI {
                if let t = XSDTypes (rawValue: s.localName) {
                    e.text = "- " + t.rawValue + " -"
                } else {
                    e.text = "? " + s.localName + " ?"
                }
            } else {
                if let typeSchema = types.findObjectInSchema(name: s.localName, namespace: typeNSURI, type: SchemaTypeBase.self) as? SchemaTypeBase {
                    if let typeStubs = typeSchema.generateXMLStub(types: types) {
                        for typeStub in typeStubs {
                            do {
                                if let restriction = typeStub as? RestrictionStubElement {
                                   e.text = restriction.stringValue
                                } else {
                                    try e.appendChildElement(elem: typeStub)
                                }
                            } catch {
                            }
                        }
                    }
                }
            }
        }
        
        if let s = super.generateXMLStub(types: types) {
            for stub in s {
                do {
                    try e.appendChildElement(elem: stub)
                } catch {
                }
            }
        }
        
        var rv = [CWXMLElement] ()
        rv.append(e)
        return rv
    }
    
    override func isInstanceOf (type: SchemaObject.Type)->Bool {
        return type == SchemaElement.self ? true : super.isInstanceOf(type: type)
    }
}

public class Schema: SchemaObject {
    
    init (elem:CWXMLElement, targetNamespace: String?) throws {
        
        if elem.localName != "schema" {
            throw SchemaError.notASchemaElement
        }
        
        try super.init(xmlElement: elem, allowedChildren: ["schema", "element", "complexType", "attribute", "simpleType"], targetNamespace: targetNamespace)
    }
    
    func findObject (name: String, namespace: String?, type: SchemaObject.Type?) -> SchemaObject? {
        
        var rv: SchemaObject? = nil
        for element in elements where rv == nil {
            
            switch element {
            case let schemaElement as SchemaElement where schemaElement.name == name && schemaElement.targetNamespace == namespace:
                if type == nil || schemaElement.isInstanceOf(type: type!) {
                    rv = schemaElement
                }
            case let complexType as SchemaComplexType where complexType.name == name && complexType.targetNamespace == namespace:
                if type == nil || complexType.isInstanceOf(type: type!) {
                    rv = complexType
                }
            case let simpleType as SchemaSimpleType where simpleType.name == name && simpleType.targetNamespace == namespace:
                if type == nil || simpleType.isInstanceOf(type: type!) {
                    rv = simpleType
                }
            case let schema as Schema:
                rv = schema.findObject (name: name, namespace: namespace, type: type)
                
            default: break;
            }
        }
        return rv
    }
}

public class SchemaTypeBase: SchemaObject {
    override func isInstanceOf (type: SchemaObject.Type)->Bool {
        return type == SchemaTypeBase.self ? true : super.isInstanceOf(type: type)
    }
}

public class SchemaSimpleType: SchemaTypeBase {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["restriction", "union"], targetNamespace: targetNamespace)
    }
}

public class SchemaComplexType: SchemaTypeBase {
    
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["complexContent", "sequence", "simpleContent", "attribute"], targetNamespace: targetNamespace)
    }
}

public class SchemaSequence:SchemaObject {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["element", "sequence", "any"], targetNamespace: targetNamespace)
    }
}

public class SchemaSimpleContent:SchemaObject {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["extension", "restriction"], targetNamespace: targetNamespace)
    }
}


public class SchemaComplexContent:SchemaObject {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["extension", "restriction"], targetNamespace: targetNamespace)
    }
}

public class SchemaExtension:SchemaObject {
    public let base: String
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        guard let _base = elem.attribute(forName: "base") else {
            throw SchemaError.missingBaseAttribute
        }
        base = _base
        try super.init(xmlElement: elem, allowedChildren: ["attribute", "sequence"], targetNamespace: targetNamespace)
    }
}

public class SchemaRestriction: SchemaObject {
    public let base : String
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        guard let _base = elem.attribute(forName: "base") else {
            throw SchemaError.missingBaseAttribute
        }
        
        self.base = _base
        
        try super.init(xmlElement: elem, allowedChildren: ["enumeration", "pattern", "fractionDigits", "length", "maxExclusive", "maxInclusive", "maxLength", "minExclusive", "minInclusive", "minLength", "totalDigits", "whitespace"], targetNamespace: targetNamespace)
    }
    
    override func generateXMLStub (types: Types)->[CWXMLElement]? {
        
        let s = splitQName(qname: base)
        
        guard let typeNSURI = xmlElement.namespace(forPrefix: s.prefix) else {
            return super.generateXMLStub(types: types)
        }
        
        let e = RestrictionStubElement (name: "restriction")
        
        if typeNSURI == XSDURI {
            if let t = XSDTypes (rawValue: s.localName) {
                var st = t.rawValue + " ("
                
                var b = false
                for s in self.elements {
                    if let ex = s as? SchemaEnumeration {
                        if b {
                            st.append(",")
                        }
                        st.append(ex.value)
                        b = true
                    }
                }
                st.append(")")
                e.text = "- " + st + " -"
            } else {
                e.text = "? " + s.localName + " ?"
            }
        }
        
        var rv = [CWXMLElement] ()
        rv.append(e)
        return rv
    }
}

public class SchemaAttribute:SchemaObject {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren: ["simpleType"], targetNamespace: targetNamespace)
    }
}

public class SchemaUnion: SchemaObject {
    public init (elem: CWXMLElement, targetNamespace: String?) throws {
        try super.init(xmlElement: elem, allowedChildren:["simpleType"], targetNamespace: targetNamespace)
    }
}

public class SchemaEnumeration: SchemaObject {
    let baseType: String
    let value: String
    public init (elem: CWXMLElement, targetNamespace: String?, baseType: String) throws {
        self.baseType = baseType
        guard let _value = elem.attribute(forName: "value") else {
            throw SchemaError.missingEnumerationValue
        }
        self.value = _value
        try super.init(xmlElement: elem, allowedChildren: [], targetNamespace: targetNamespace)
    }
}

