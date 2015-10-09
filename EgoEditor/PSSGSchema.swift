//
//  PSSGSchema.swift
//  PSSGEditor
//
//  Created by Benjamin Johnson on 30/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

enum PSSGValueType: String {
    case Int = "int"
    case Int16 = "short"
    case StringValue = "string"
    case Float = "float"// Single, Float
    case UInt16 = "unsignedShort"
    case UInt32 = "unsignedInt"
    case ByteArray = "byteArray"
    case FloatArray = "floatArray"
    case Unknown = "anyType"
    
    static func fromTypeString(type:String) -> PSSGValueType
    {
        let typeString = type.stringByReplacingOccurrencesOfString("System.", withString: "")
        switch(typeString) {
        case "String":
            return PSSGValueType.StringValue
        case "Byte[]":
            return PSSGValueType.ByteArray
        case "UInt32":
            return PSSGValueType.UInt32
        case "Single":
            return PSSGValueType.Float
        default:
            return Unknown
            
        }
    }
}




class PSSGAttributeSchema: Equatable, XMLSerialization {
    var id: Int?
    
    var name: String
    
    var dataType: PSSGValueType = PSSGValueType.Unknown
    
    init( name: String) {
        
        self.name = name
    }
 
    func xmlElement() -> NSXMLElement? {
        let attributeSchema = NSXMLElement(name: "xs:attribute")
        attributeSchema.addAttribute("name", stringValue: self.name)
        attributeSchema.addAttribute("type", stringValue: "xs::\(self.dataType.rawValue)")
        
        return attributeSchema
    }
}

func ==(lhs: PSSGAttributeSchema, rhs: PSSGAttributeSchema) -> Bool {
    return lhs.name == rhs.name
}

extension XMLSerialization {
    func generateXMLDocument() -> NSXMLDocument? {
        return nil
    }
}

extension NSXMLElement {
    func addAttribute(name: String, stringValue:String) {
        self.addAttribute(NSXMLNode.attributeWithName(name, stringValue: stringValue) as! NSXMLNode)
    }
}


class PSSGNodeSchema: XMLSerialization {
    var referenceID: Int? // Identifier used to reference this node in the file
    
    var name: String
    
    var elementsPerRow: Int!
    
    var linkAttributeName: String!
    
    var attributes: [PSSGAttributeSchema] = []
    
    var valueType: PSSGValueType = PSSGValueType.Unknown
    
    init(name: String) {
     //   self.id = id
        self.name = name
    }
    
    func attributeWithName(attributeName: String) -> PSSGAttributeSchema? {
        if let attribute = attributes.filter({ $0.name == attributeName}).first {
            return attribute
        }
        return nil
    }
    
    func addAttribute(attributeName: String, dataType: PSSGValueType) {
        if let existingAttribute = attributeWithName(attributeName) {
            
            existingAttribute.dataType = dataType
        }
        let newAttribute = PSSGAttributeSchema(name: attributeName)
        newAttribute.dataType = dataType
        
        attributes.append(newAttribute)
    }
    
    func xmlElement() -> NSXMLElement? {
        // Create Element for node
        let nodeElement = NSXMLElement(name: "xs:element")
        nodeElement.addAttribute("name", stringValue: self.name)
        for attribute in attributes {
            if let attributeSchema = attribute.xmlElement() {
                nodeElement.addChild(attributeSchema)
            }
        }
        
        return nodeElement
    }
}

enum PSSGSchemaReadError: ErrorType {
    case FileNotFound
}

class PSSGSchema: NSObject, XMLSerialization {
    var entries: [String: PSSGNodeSchema] = [:]
    
    init(pssgFile: FileHandle, schemaURL: NSURL?) {
        
        super.init()
        
        if let schemaURL = schemaURL {
            // Load Assist Schema
            do {
                let schemaParser = PSSGSchemaParser()
                try schemaParser.loadSchema(schemaURL)
                entries = schemaParser.nodesDictionary
            } catch {
                
            }
        }
        
        let attributeInfoCount = pssgFile.readInt32()
        let noteInfoCount = pssgFile.readInt32()
        
        for(var i = 0;i < noteInfoCount;i++) {
            let nodeID = pssgFile.readInt32()!
            let nodeName = pssgFile.readString()!
            let node = PSSGNodeSchema(name: nodeName)
            node.referenceID = nodeID
            if let existingNode = entries[nodeName] {
                existingNode.referenceID = node.referenceID
            } else {
                addNode(node)
            }
            
            let subAttributeInfoCount = pssgFile.readInt32()
            for(var j = 0; j < subAttributeInfoCount;j++) {
                
                let attributeID = pssgFile.readInt32()!
                let attributeName = pssgFile.readString()!
                
                let attribute = PSSGAttributeSchema(name: attributeName)
                attribute.id = attributeID
                if let attr = findAttribute(node.name, attributeName: attribute.name) {
                    attr.id = attribute.id
                } else {
                    // Check if attribute doesn't already exist
                    if node.attributes.filter({ $0.name == attribute.name }).first == nil {
                        node.attributes.append(attribute)
                    }
                }
                
                
            }
        }
    }
    
    func addNode(node:PSSGNodeSchema) -> PSSGNodeSchema {
        entries[node.name] = node
        return entries[node.name]!
    }
    
    func addNode(nodeName:String) -> PSSGNodeSchema {
        let node = PSSGNodeSchema(name: nodeName)
        entries[nodeName] = node
        return entries[node.name]!
    }
    
 
    func nodeWithID(id: Int) -> PSSGNodeSchema? {
        for (_, node) in entries {
            if node.referenceID == id {
                return node
            }
        }
        return nil
    }
    
    func attributeithID(id: Int) -> PSSGAttributeSchema? {
        for (_,node) in entries {
            for attribute in node.attributes {
                if attribute.id == id {
                    return attribute
                }
            }
        }

        return nil
    }
    
    func findAttribute(nodeName: String, attributeName: String) -> PSSGAttributeSchema? {
        if let existingNode = entries[nodeName] {
            for attribute in existingNode.attributes {
                if attribute.name == attributeName {
                    return attribute
                }
            }
        }
        
        return nil
    }
    
    func xmlElement() -> NSXMLElement? {
        // Create root schema element
        let rootSchema = NSXMLElement(name: "xs:schema")
        
        rootSchema.addAttribute("targetNamespace", stringValue: "EgoEditor")
        rootSchema.addAttribute("elementFormDefault", stringValue: "qualified")
        rootSchema.addAttribute("xmlns", stringValue: "EgoEditor")
        rootSchema.addAttribute("xmlns:xs", stringValue: "http://www.w3.org/2001/XMLSchema")

        
        for (_, nodeSchema) in entries {
            if let nodeSchemaXML = nodeSchema.xmlElement() {
                rootSchema.addChild(nodeSchemaXML)
            }
        }
        
        return rootSchema
    }
    
    func generateXMLDocument() -> NSXMLDocument? {

        guard let rootNode = self.xmlElement() else {
            return nil
        }
        
        let xmlSchemaDoc = NSXMLDocument(rootElement: rootNode)
        xmlSchemaDoc.version = "1.0"
        xmlSchemaDoc.characterEncoding = "UTF-8"
        
        return xmlSchemaDoc
    }
    
}

class PSSGSchemaParser: NSObject, NSXMLParserDelegate {
    var isInNode = false
    var currentNode: PSSGNodeSchema?
    var nodesDictionary: [String: PSSGNodeSchema] = [:]
    func loadSchema(fileURL: NSURL) throws {
        if let parser = NSXMLParser(contentsOfURL: fileURL) {
            parser.delegate = self
            parser.parse()
        } else {
            throw PSSGSchemaReadError.FileNotFound
        }
    }
    
    func parserDidStartDocument(parser: NSXMLParser) {
        
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "xs:element" {
            isInNode = true
            guard let name = attributeDict["name"] else {
                print("Invalid Node")
                return
            }
            if name == "MATRIXPALETTEBUNDLENODE" {
                print("Found node")
            }
         
            let node = PSSGNodeSchema(name: name)
            node.elementsPerRow = -1
            node.linkAttributeName = ""
            node.valueType = PSSGValueType.fromTypeString("")
            
            currentNode = node
            
        } else if elementName == "xs:attribute" {
            guard let attributeName = attributeDict["name"], dataType = attributeDict["type"]?.componentsSeparatedByString("::").last! else {
                return
            }
            
            print(dataType)
            
            let pssgValueType = PSSGValueType(rawValue: dataType)!
            currentNode?.addAttribute(attributeName, dataType: pssgValueType)

            
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let node = currentNode where elementName == "xs:element" {
            // Add node to system
            nodesDictionary[node.name] = node
        }
    }
    
}

class PSSGXMLParser:NSObject, NSXMLParserDelegate {
    func loadFile(url: NSURL) {
        if let parser = NSXMLParser(contentsOfURL: url) {
            parser.delegate = self
            parser.parse()
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
      
        
        
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        // Set node data
    }
    
    
}

