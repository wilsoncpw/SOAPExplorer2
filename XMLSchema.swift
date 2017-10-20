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
}

public class SchemaObject {
    public let xmlElement: CWXMLElement
    public let name: String?
    public let targetNamespace: String
    public var elements = [SchemaObject] ()
    
    
    public init (xmlElement: CWXMLElement, allowedChildren: Set <String>, targetNamespace: String) throws {
        self.xmlElement = xmlElement
        self.name = xmlElement.attribute(forName: "name")
        self.targetNamespace = targetNamespace
        
        if xmlElement.namespaceUri != XSDURI {
            throw SchemaError.notASchemaElement
        }
        
        if allowedChildren == ["*"] {
            return
        }
        
        guard let children = xmlElement.children else {
            return
        }
        
        for c in children {
            switch c.localName {
            case "any":
                continue;
            case "import":
                elements.append(try SchemaObject.importSchema (elem: c));
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
            default:
                print ("Unexpected ", c.name)
            }
        }
    }
    
    static func importSchema (elem: CWXMLElement) throws -> Schema {
        
        guard let delegate = soapExplorerData.importXSDDelegate else {
            throw SchemaError.missingSchemaLocation
        }
        
        guard let schemaLocation = elem.attribute(forName: "schemaLocation") else {
            throw SchemaError.missingSchemaLocation
        }
        
        guard let docURL = elem.document?.url else {
            throw SchemaError.missingSchemaLocation
        }
        
        guard var schemaURL = URL (string: schemaLocation) else {
            throw SchemaError.missingSchemaLocation
        }
        
        if let query = schemaURL.query {
            if var idx = query.index(of: "=") {
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
        
        let targetNamespace = rootElement.attribute(forName: "targetNamespace") ?? ""
        
        return try Schema (elem: rootElement, targetNamespace: targetNamespace)
    }
}
    
    public class SchemaElement: SchemaObject {
        public let type: String?
        public let ref: String?
        
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            type = elem.attribute(forName: "type")
            ref = elem.attribute(forName: "ref")
            
            try super.init(xmlElement: elem, allowedChildren: ["simpleType", "complexType"], targetNamespace: targetNamespace)
            
            if elem.parentElement?.name == "schema" {
                if elem.attribute(forName: "name") == nil {
                    throw SchemaError.missingNameAttribute
                }
            }
        }
    }

    public class Schema: SchemaObject {
        let targetNamespaceURI: String
        
        init (elem:CWXMLElement, targetNamespace: String) throws {
            
            if elem.localName != "schema" {
                throw SchemaError.notASchemaElement
            }
            
            targetNamespaceURI = targetNamespace
            
            try super.init(xmlElement: elem, allowedChildren: ["schema", "element", "complexType", "attribute", "simpleType"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaTypeBase: SchemaObject {
        
    }
    
    public class SchemaSimpleType: SchemaTypeBase {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["restriction", "union"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaComplexType: SchemaTypeBase {
        
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["complexContent", "sequence", "simpleContent", "attribute"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaSequence:SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["element", "sequence", "any"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaSimpleContent:SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["extension", "restriction"], targetNamespace: targetNamespace)
        }
    }
    
    
    public class SchemaComplexContent:SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["extension", "restriction"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaExtension:SchemaObject {
        public let base: String
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            guard let _base = elem.attribute(forName: "base") else {
                throw SchemaError.missingBaseAttribute
            }
            base = _base
            try super.init(xmlElement: elem, allowedChildren: ["attribute", "sequence"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaRestriction: SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["*"], targetNamespace: targetNamespace)
        }
    }
    
    public class SchemaAttribute:SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren: ["simpleType"], targetNamespace: targetNamespace)
        }
    }

    public class SchemaUnion: SchemaObject {
        public init (elem: CWXMLElement, targetNamespace: String) throws {
            try super.init(xmlElement: elem, allowedChildren:["simpleType"], targetNamespace: targetNamespace)
        }
    }

