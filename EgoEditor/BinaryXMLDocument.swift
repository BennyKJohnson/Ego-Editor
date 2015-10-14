//
//  BinaryXMLDocument.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 9/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

struct BinaryXMLElement {
    let elementNameID: Int      // The id (index) of the stringValue for the element name
    let elementValueID: Int     // The id (index) if the stringValue for the element data
    let attributeCount: Int     // Number of attributes for node
    let attributeStartID: Int
    let childElementCount: Int
    let childElementStartID: Int
    
    init(fileHandle: FileHandle) {
        elementNameID = fileHandle.readInt32()!
        elementValueID = fileHandle.readInt32()!
        attributeCount = fileHandle.readInt32()!
        attributeStartID = fileHandle.readInt32()!
        childElementCount = fileHandle.readInt32()!
        childElementStartID = fileHandle.readInt32()!
    }
    
    var childElementEndID: Int {
        return childElementStartID + childElementCount
    }
    
    var attributeEndID: Int {
        return attributeStartID + attributeCount
    }
}

struct BinaryXMLAttribute {
    let nameID: Int
    let valueID: Int
    
}

class XMLFile {
    
    var xmlStrings: [String] = []
    var binaryXMLAttributes: [BinaryXMLAttribute] = []
    var binaryXMLElements: [BinaryXMLElement] = []
    var xmlDocument: NSXMLDocument!
    
    init(data: NSData) {
        do {
            let testXMLDocument = try NSXMLDocument(data: data, options: 0)
            self.xmlDocument = testXMLDocument
            return
        } catch {
            print("Not text xml")
        }
        
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes);
        let fileHandle = ByteBuffer(order: LittleEndian(), data: dataPointer, capacity: Int(data.length), freeOnDeinit: false)
        let type = fileHandle.readBytes(1)?.first!
        if(type == 0x00) {
            
        } else if (type == 0x01) {
            // BXMLLittle;
        } else {
            // Binary XML
        }
        fileHandle.seekToFileOffset(0)
        
        // Check if fileHandle is
        fileHandle.readBytes(1);
        fileHandle.readBytes(3); // Read Magic
        let size = fileHandle.readInt32()!;
        assert(size > 0, "Read file size of 0, this is not expected. Is this a BXML or other file?")
        
        // Section 2
        fileHandle.readBytes(1)
        fileHandle.readBytes(3);
        let dataSize = fileHandle.readInt32()
        assert(dataSize > 0, "Read main data size of 0, this is not expected. Is this a BXML or other file?")
        
        xmlStrings = readXMLString(fileHandle)
        
        // Node Information
        fileHandle.readInt32()
        let xmlElementStride = 24
        let xmlElementLength = fileHandle.readInt32()!
        let xmlElementCount = xmlElementLength / xmlElementStride
        
        for(var i = 0; i < xmlElementCount;i++) {
            binaryXMLElements.append(BinaryXMLElement(fileHandle: fileHandle))
        }
        
        // Attribute Information
        fileHandle.readInt32()
        let binaryXMLStride = 8
        let binaryXMLLength = fileHandle.readInt32()!
        let binaryXMLAttributeCount = binaryXMLLength / binaryXMLStride
        
        for(var i = 0; i < binaryXMLAttributeCount;i++) {
            let binaryXMLAttribute = BinaryXMLAttribute(nameID: fileHandle.readInt32()!, valueID: fileHandle.readInt32()!)
            binaryXMLAttributes.append(binaryXMLAttribute)
        }
        
        // Create XML Document
        let rootElement = xmlElementForBinaryXMLElement(binaryXMLElements.first!)
        let xmlDoc = NSXMLDocument(rootElement: rootElement)
        xmlDoc.version = "1.0"
        xmlDoc.characterEncoding = "UTF-8"
        
        xmlDocument = xmlDoc
    }
    
    func attributeForBinaryXMLAttribute(binaryAttribute: BinaryXMLAttribute) -> NSXMLNode {
        return NSXMLNode.attributeWithName(xmlStrings[binaryAttribute.nameID], stringValue: xmlStrings[binaryAttribute.valueID]) as! NSXMLNode
    }
    
    func xmlElementForBinaryXMLElement(binaryElement: BinaryXMLElement) -> NSXMLElement {
        let element = NSXMLElement(name: xmlStrings[binaryElement.elementNameID])
        element.attributes = []
        
        // Get attributes for the binary XML element
        for(var i = binaryElement.attributeStartID; i < binaryElement.attributeEndID;i++) {
            let binaryAttribute = binaryXMLAttributes[i]
            element.addAttribute(attributeForBinaryXMLAttribute(binaryAttribute))
        }
        // Get child nodes for binary XML element
        for(var i = binaryElement.childElementStartID; i < binaryElement.childElementEndID; i++) {
            element.addChild(xmlElementForBinaryXMLElement(binaryXMLElements[i]))
        }
        // Get node data (String value) for binary xml element
        if(binaryElement.elementValueID > 0 && binaryElement.childElementCount == 0) {
            element.stringValue = xmlStrings[binaryElement.elementValueID]
        }
        
        return element
        
    }
    
    func readXMLString(fileHandle: FileHandle) -> [String] {
        let _ = fileHandle.readInt32()
        let length = fileHandle.readInt32()!
        // Offset for where strings have finished being defined
        let endPosition = UInt64(length) + fileHandle.offsetInFile
        
        // Array to hold readed string values
        var stringValues: [String] = []
        // Read Strings until endPosition is reached
        while(fileHandle.offsetInFile < endPosition) {
            // Read null terminated string and append to string array
            let stringValue = fileHandle.readCString()!
            stringValues.append(stringValue)
        }
        
        fileHandle.readInt32()
        let length2 = UInt64(fileHandle.readInt32()!)
        fileHandle.seekToFileOffset(fileHandle.offsetInFile + length2)
        return stringValues
    }
}