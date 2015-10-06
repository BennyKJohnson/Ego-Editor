//
//  PSSGSchema.swift
//  PSSGEditor
//
//  Created by Benjamin Johnson on 30/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

enum PSSGValueType {
    case Int
    case Int16
    case StringValue
    case Float // Single, Float
    case UInt16
    case UInt32
    case ByteArray
    case FloatArray
    case Unknown
    
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




class PSSGAttributeSchema: Equatable {
    var id: Int?
    
    var name: String
    
    var dataType: PSSGValueType = PSSGValueType.Unknown
    
    init( name: String) {
        
        self.name = name
    }
}

func ==(lhs: PSSGAttributeSchema, rhs: PSSGAttributeSchema) -> Bool {
    return lhs.name == rhs.name
}

class PSSGNodeSchema {
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
}

enum PSSGSchemaReadError: ErrorType {
    case FileNotFound
}

class PSSGSchema: NSObject {
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
        if elementName == "node" {
            isInNode = true
            guard let name = attributeDict["name"], dataType = attributeDict["dataType"] else {
                print("Invalid Node")
                return
            }
            let elementsPerRow = attributeDict["elementsPerRow"] as? Int
            let linkAttributeName = attributeDict["linkAttributeName"]
            let node = PSSGNodeSchema(name: name)
            node.elementsPerRow = elementsPerRow
            node.linkAttributeName = linkAttributeName
            node.valueType = PSSGValueType.fromTypeString(dataType)
            
            currentNode = node
            
        } else if elementName == "attribute" {
            guard let attributeName = attributeDict["name"], dataType = attributeDict["dataType"] else {
                return
            }
            let pssgValueType = PSSGValueType.fromTypeString(dataType)
            currentNode?.addAttribute(attributeName, dataType: pssgValueType)

            
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let node = currentNode where elementName == "node" {
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

