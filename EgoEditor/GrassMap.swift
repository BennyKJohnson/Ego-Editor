//
//  GrassMap.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 20/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

struct GrassInstanceGroup {
    let values: [Float]
    let id:Int
    let boundsMin: SCNVector3
    let boundsMax: SCNVector3
    let elementCount: Int
    
}

struct GrassSection {
    let positions: [SCNVector3]
    let unknownValues: [Float]
}


struct GrassTypeGroup {
    var names: [String] = []
    
}

struct GrassMap {
    var grassSections: [GrassSection] = []
    
    init(data: NSData) {
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes); // Get pointer to file bytes
        let stream = ByteBuffer(order: LittleEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        
        let version = stream.readInt32()!
        let typeCount = stream.readInt32()!
        let instanceGroupCount = stream.readInt32()!
        stream.readInt32()!
        
        // Read Float Section
        for(var i = 0; i < typeCount;i++) {
            let positions = stream.readVectors(12);
            let unknownValues = stream.getFloat32(12);
            grassSections.append(GrassSection(positions: positions, unknownValues: unknownValues))
        }
        
        stream.seekToFileOffset(2416)
        // Read Type Group
        for(var i = 0; i < typeCount;i++) {
            let ptr = stream.position
            let tailOffset = 128
            stream.seekToFileOffset(UInt64(ptr + tailOffset))
            let subTypeCount = stream.readInt32()!
            stream.seekToFileOffset(UInt64(ptr))
            
            // Read subtypes
            var subTypes: [String] = []
            for(var t = 0;t < subTypeCount;t++) {
                subTypes.append(stream.readCString()!)
                // Padding
                stream.getUInt8()
                stream.getInt32(2)
            }
            
            // Get remaining padding
            let remainingSlots = 8 - subTypeCount
            stream.getInt32(remainingSlots * 4);
            stream.getInt32()
            let unknownValue = stream.getFloat32()
            stream.readCString()
            stream.getInt32(2)
            
        }
        
        stream.seekToFileOffset(3632);
        let numberOfSections = stream.getInt32()
        
        var smallestSection = -1
        var smallestSectionCount = 100000
        
        var instanceGroups: [GrassInstanceGroup] = []
        
        // Read Sections
        for(var i = 0; i < instanceGroupCount;i++) {
            let startOffset = stream.getInt32()
            let currentOffset = stream.position
            var endOffset = stream.getInt32()
            if endOffset == 0 {
                endOffset = Int32(data.length)
            }
            
            let floatCount = (((endOffset - startOffset) / 4) - 10) * 2
            
         
            stream.seekToFileOffset(UInt64(startOffset))
            let someNum = stream.getInt16()
            let elementCount = stream.readInt32()!
            let someNum2 = stream.getInt16()
            stream.getInt32(2)
            
            let minBounds = stream.readVector()
            let maxBounds = stream.readVector()
            
            let values = stream.getFloat16(Int(floatCount))
            if endOffset < Int32(data.length) {
                stream.getInt32(2)
            }
    
            
            stream.seekToFileOffset(UInt64(currentOffset))
            
            if Int(someNum) < smallestSectionCount {
                    smallestSection = i
                    smallestSectionCount = Int(someNum)
            }
            
            let instanceGroup = GrassInstanceGroup(values: values, id: i, boundsMin: minBounds, boundsMax: maxBounds, elementCount: elementCount)
            instanceGroups.append(instanceGroup)
            
        }
        let sortedInstanceGroups = instanceGroups.sort { (lhs, rhs) -> Bool in
            return lhs.elementCount < rhs.elementCount
        }
        
        
        print("Smallest Section \(sortedInstanceGroups.first!.elementCount)")
        
        
        
    }
    
   
    
    
}