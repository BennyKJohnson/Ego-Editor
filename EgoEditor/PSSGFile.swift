//
//  PSSGFile.swift
//  PSSGEditor
//
//  Created by Benjamin Johnson on 30/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

protocol PSSGBinarySerialization {
    init(fileHandler: NSFileHandle) throws
}

protocol XMLSerialization {
    func generateXMLDocument() -> NSXMLDocument?
    func xmlElement() -> NSXMLElement?
}


// Collection of properties to make the PSSG reading more flexible
struct PSSGReadAttributes {
    let shouldUseExplictedNameCheckForDataNode: Bool
}

// Different PSSG Types
enum PSSGType {
    case Geometry
    case Texture
    case Animation
    case Data
}

class PSSGFile {
    var rootNode: PSSGNode!
    var pssgType: PSSGType = PSSGType.Data
    var schema: PSSGSchema!
    
    convenience init(file: FileHandle, schemaURL: NSURL) throws {
        guard let fileType = PSSGFile.PSSGFileTypeForFile(file) else {
            throw PSSGReadError.InvalidFile(reason: "Could not recognise file type")
        }
        
        switch(fileType) {
        case .Binary:
            try self.init(pssgFile: file, schemaURL: schemaURL)
        case .CompressedBinary:
            // Create NSData for object
            let compressedData = file.availableData // Get all available data
      
            let uncompressData = try compressedData.gunzippedData() // attempt to uncompress data

            let dataPointer = UnsafeMutablePointer<UInt8>(uncompressData.bytes); // Get pointer to file bytes
            let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: uncompressData.length, freeOnDeinit: false) // Create buffer that will be used to read data from data pointer
            
            dataBuffer.readString(4) // Read Magic, already used so don't store it
            
            try self.init(pssgFile: dataBuffer, schemaURL: schemaURL)

        case .XML:
            try self.init(xmlFile: file)
        }
    }
    
    func getPSSGType() -> PSSGType {
        if rootNode.nodeWithName("MATRIXPALETTEBUNDLENODE") != nil {
            return PSSGType.Geometry
        }
        return PSSGType.Data
    }
    
    init(pssgFile: FileHandle, schemaURL: NSURL) throws {
        let size = pssgFile.readInt32()!
        schema = PSSGSchema(pssgFile: pssgFile, schemaURL: schemaURL)
     
  
        
        let positionForData = pssgFile.offsetInFile
        let readAttributes = PSSGReadAttributes(shouldUseExplictedNameCheckForDataNode: true)
        
        rootNode = try PSSGNode(file: pssgFile, schema: schema, parentNode: nil, readAttributes: readAttributes)
        
        if(Int(pssgFile.offsetInFile) < size) {
            pssgFile.seekToFileOffset(positionForData)
            rootNode = try PSSGNode(file: pssgFile, schema: schema, parentNode: nil, readAttributes: PSSGReadAttributes(shouldUseExplictedNameCheckForDataNode: false))
            pssgType = getPSSGType()
        }
    }
    
    init(xmlFile: FileHandle) throws {
  
        print("XML File")
    }
    
    
    class func PSSGFileTypeForFile(file: FileHandle) -> PSSGDataType? {
       
       
        if let header = file.readData(4){
            // create an array of Uint8
            var headerData = [UInt8](count: 4, repeatedValue: 0)
            
            // copy bytes into array
            header.getBytes(&headerData, length:4 * sizeof(UInt8))
            

            if let magic = String(data: header, encoding: NSUTF8StringEncoding) {
                if magic == "PSSG" {
                    return PSSGDataType.Binary

                } else if (magic.containsString("<")) {
                    file.seekToFileOffset(0)
                    return PSSGDataType.XML
                }
            }  else if (headerData[0] == 31 && headerData[1] == 139  && headerData[2] == 8 && headerData[3] == 0) {
                file.seekToFileOffset(0)

                return PSSGDataType.CompressedBinary
            }
            
        }
   
        return nil
    }
    

    
    
}

class PSSGNode {
    var id: Int!
    var attributes: [PSSGAttribute] = []
    var attributesDictionary: [String: PSSGAttribute] = [:]
    var childNodes: [PSSGNode] = []
    var nodeSchema: PSSGNodeSchema!
    var isDataNode: Bool = false
    var size: Int = 0
    var attributeSize: Int = 0
    var data: AnyObject?
    var dataType: PSSGValueType! = PSSGValueType.Unknown
    weak var parentNode: PSSGNode?
   // weak var parentNode:PSSGNode?
    
    
    var name: String {
        return nodeSchema.name
    }
    
    var isLeaf: Bool {
        return childNodes.count == 0
    }
    
    var childCount: Int {
        return childNodes.count
    }
    
    func getValueType() {
        if(!nodeSchema.linkAttributeName.isEmpty)  {
            let char1: Character = "^"
            if(nodeSchema.linkAttributeName.characters.first! == char1) {
                
                
            }

        }
    }
    
    func nodeWithID(nodeID: String) -> PSSGNode? {
        if let attributeValue = self.attributesDictionary["id"]?.value as? String {
            if attributeValue == nodeID {
                return self
            }
        }
        
        for childNode in self.childNodes {
           
            
            if(childNode.childNodes.count > 0) {
                let found = childNode.nodeWithID(nodeID)
                if found != nil {
                    return found
                }
            }
            

        }
        
       return nil
    }
    
    func nodesWithAttribute(attributeName: String, value: String?) {


    }
    
    // Search for node with name
    func nodesWithName(nodeName: String) -> [PSSGNode] {
        var results: [PSSGNode] = []
        if(name == nodeName) {
          results.append(self)
        }
        
        for childNode in childNodes {
            results += childNode.nodesWithName(nodeName)
        }
        
        return results
    }
    
    func nodeWithName(nodeName: String) -> PSSGNode? {
        return nodesWithName(nodeName).first
    }
    
    var ancestorNodes: [PSSGNode] {
        var ancestors: [PSSGNode] = []
        var currentAncestor = self.parentNode
        while let ancestor = currentAncestor {
            ancestors.insert(ancestor, atIndex: 0)
            // Get next parent
            currentAncestor = ancestor.parentNode
        }
        return ancestors
    }
    
    init(file: FileHandle, schema: PSSGSchema, parentNode: PSSGNode?, readAttributes: PSSGReadAttributes) throws {
        
        
        guard let identifier = file.readInt32() else {
            throw PSSGReadError.InvalidNode(readError: PSSGNodeReadError.NoIdentifier)
        }
        
        guard let nodeSchema = schema.nodeWithID(identifier) else  {
            throw PSSGReadError.InvalidNode(readError: PSSGNodeReadError.NoSchema)
        }
        
        if nodeSchema.name == "SHADERINPUT" {
            print("Found shader input");
        }
        
        id = identifier
        self.nodeSchema = nodeSchema
        self.size = file.readInt32()!
        let end = Int(file.offsetInFile) + size
        
       // let nodeEndOffset = Int(file.offsetInFile) + size
        attributeSize = file.readInt32()!
        let attributeEnd = Int(file.offsetInFile) + attributeSize
        
        // Exception checking
        
        while(Int(file.offsetInFile) < attributeEnd) {
            do {
                let attribute = try PSSGAttribute(file: file, schema: schema)
                attribute.node = self
                attributes.append(attribute)
                attributesDictionary[attribute.key] = attribute
            } catch {
                throw PSSGReadError.InvalidNode(readError: PSSGNodeReadError.InvalidAttribute(readError: error as! PSSGAttributeReadError))
            }
        }
        
        isDataNode = isDataNodeBasedOnName
        if(isDataNode == false) {
            
            isDataNode = PSSGNode.isDataNode(file, end: end, parentNode: parentNode)
        }
        
        if(isDataNode) {
         //   print("Is data node")
            let nodeDataSize = end - Int(file.offsetInFile)
            data = PSSGAttribute.valueForAttributeType(nodeSchema.valueType, size: nodeDataSize, file: file)
        } else {
            
            // Get child nodes
            while(Int(file.offsetInFile) < end) {
                
                let childNode = try PSSGNode(file: file, schema: schema, parentNode: self, readAttributes: readAttributes)
                childNode.parentNode = self
                childNodes.append(childNode)
                
            }
        }
        
    }
    
    
    
}

extension PSSGFile: XMLSerialization {
    
    func generateXMLDocument() -> NSXMLDocument? {
        let root = NSXMLElement(name: "PSSGFILE")
        root.addAttribute(NSXMLNode.attributeWithName("version", stringValue: "1.0.0.0") as! NSXMLNode)
        
       
        if let rootElement = rootNode.xmlElement() {
            root.addChild(rootElement)
        }
        
        let xmlDoc = NSXMLDocument(rootElement: root)
        return xmlDoc
    }
    
    func xmlElement() -> NSXMLElement? {
        return nil
    }

}

extension PSSGNode: XMLSerialization {
    
    func generateXMLDocument() -> NSXMLDocument? {
        return nil
    }
    
    func xmlElement() -> NSXMLElement? {
        // Create Element for node
        let nodeElement:NSXMLElement
        if let _ = self.data {
            nodeElement = NSXMLElement(name: name, stringValue: self.toString())
        } else {
            nodeElement = NSXMLElement(name: name)
            for childNode in childNodes {
                if let childElement = childNode.xmlElement() {
                    nodeElement.addChild(childElement)
                }
            }
        }
        
        for attribute in attributes {
            nodeElement.addAttribute(NSXMLNode.attributeWithName(attribute.key, stringValue: "\(attribute.value!)") as! NSXMLNode)
        }
        
     
        return nodeElement
    }
    
    
    func toString() -> String {
        
        if let data = self.data as? NSData where dataType == PSSGValueType.Unknown  {
            return data.hexadecimalString as String
        }
        return "\(data!)"
    }

}


extension PSSGNode {
    // Not really sure if passing the schema around like this is a good idea.
 
    
    
    static func isDataNode(file:FileHandle, end: Int, parentNode: PSSGNode?) -> Bool {
        let startPosition = file.offsetInFile
        
        // Reset the file offset back to original position upon exit
        defer {
            file.seekToFileOffset(startPosition)
        }
        
        while(Int(file.offsetInFile) < end) {
            let idForNextNode = file.readInt32()!
            if idForNextNode < 0 {
                return true
            } else {
                let nodeSize = file.readInt32()!
                if Int(file.offsetInFile) + nodeSize > end || nodeSize == 0 && idForNextNode == 0 || nodeSize < 0 {
                    return true
                } else if (Int(file.offsetInFile) + nodeSize == end) {
                    break
                } else {
                    file.seekToFileOffset(file.offsetInFile + UInt64(nodeSize))
                }
            }
        }
        
        return false
    }
    
    var isDataNodeBasedOnName: Bool {
        switch(name) {
        case "BOUNDINGBOX","DATA","DATABLOCKDATA","DATABLOCKBUFFERED","INDEXSOURCEDATA","INVERSEBINDMATRIX","MODIFIERNETWORKINSTANCEUNIQUEMODIFIERINPUT","NeAnimPacketData_B1", "NeAnimPacketData_B4","RENDERINTERFACEBOUNDBUFFERED","SHADERINPUT","TEXTUREIMAGEBLOCKDATA","TRANSFORM":
            return true
        default:
            return false
        }

    }
}

extension PSSGNode {
    // Method to extract the shaderinputdefinition, maybe useful for other nodes
    func subNodeForNodeWithIdentifier(id: String, parameterID: Int) -> PSSGNode? {
        // Get node with id
        if let node = self.nodeWithID(id) where node.childNodes.count > parameterID {
            // Get subnodes
            let subNodes = node.childNodes;
            return subNodes[parameterID]
        }
        return nil
    }
}


class PSSGAttribute {
    var key: String!
    var value: AnyObject?
    var valueType: PSSGValueType!
    var size: Int!
    weak var node: PSSGNode? // Weak reference for owner node
    
    var isReferenceID: Bool {
        if let stringValue = value as? String where stringValue.firstCharacter == "#" {
            
            return true
        }
        return false
    }

    
    var formattedValue: AnyObject? {
        if let valueData =  value as? NSData where valueType == .Unknown {
            let dataPointer = UnsafeMutablePointer<UInt8>(valueData.bytes);
            let byteBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: valueData.length, freeOnDeinit: false)
            
            if size > 4 {
                
                let stringLength = Int(byteBuffer.getInt32())
                if size - 4 == stringLength {
                    // Must be a PSSG String
                    return byteBuffer.readString(stringLength)
                } else {
                    byteBuffer.position -= 4
                }
            // Assume the value is an int
            } else if byteBuffer.capacity == 4 {
                return Int(byteBuffer.getInt32())
            }
        }
        
        return value
    }
    
    init(file: FileHandle, schema: PSSGSchema) throws {
        guard let id = file.readInt32() else {
            throw PSSGAttributeReadError.NoKey
        }
        
        guard let attributeSchema = schema.attributeithID(id) else {
            throw PSSGAttributeReadError.NoSchema
        }
        
        key = attributeSchema.name
        
        size = file.readInt32()!
        valueType = attributeSchema.dataType
        
        value = PSSGAttribute.valueForAttributeType(valueType, size: size, file: file)
    }
    
}


extension PSSGAttribute {
    static func valueForAttributeType(valueType: PSSGValueType,size: Int, file: FileHandle) -> AnyObject? {
        switch(valueType) {
        case .StringValue:
            return file.readString()
            
        case .Int:
            return file.readInt32()
            
        case .Float:
            return file.readFloat()
            
        case .UInt16:
            return file.readUInt16()
            
        case .UInt32:
            return file.readUInt32()
            
        case .ByteArray:
            return file.readData(size)
            
        case .FloatArray:
            let floatCount = size / 4
            var floatArray: [Float] = []
            for(var i = 0; i < floatCount;i++) {
                floatArray.append(file.readFloat()!)
            }
            return floatArray
            
        default:
            // Read data specified by length
            return file.readData(size)
        }
            
    }
}

