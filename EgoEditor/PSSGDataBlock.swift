//
//  PSSGDataBlock.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 17/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

struct PSSGDataBlock {
    
    let id: String
    
    let elementCount: Int
    
    var streams: [PSSGDataBlockStream] = []
    
    init?(dataBlockNode: PSSGNode) {
        guard let streamCount = dataBlockNode.attributesDictionary["streamCount"]?.formattedValue as? Int, elementCount = dataBlockNode.attributesDictionary["elementCount"]?.formattedValue as? Int, id = dataBlockNode.attributesDictionary["id"]?.formattedValue as? String else {
            // Not a valid data block node
            return nil
        }
        
        self.id = id
        self.elementCount = elementCount
        
        let dataBlockStreamNodes = dataBlockNode.nodesWithName("DATABLOCKSTREAM")
        if dataBlockStreamNodes.count != streamCount {
            // Not enough streams
            return nil
        }
        
        for dataBlockStreamNode in dataBlockStreamNodes {
            // Create Data Block stream
            if let dataBlockStream = PSSGDataBlockStream(dataBlockStreamNode: dataBlockStreamNode) {
                // Add to data blocks stream, order matters, if incorrect order reading data won't work
                streams.append(dataBlockStream)
            } else {
                // If unable to parse a data block stream, then can't proceed
                return nil
            }
        }
        
        // Get data
        guard let dataBlockData = dataBlockNode.nodeWithName("DATABLOCKDATA")?.data as? NSData else {
            // Missing data
            return nil
        }
        
        let dataPointer = UnsafeMutablePointer<UInt8>(dataBlockData.bytes);
        let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: dataBlockData.length, freeOnDeinit: false)
        
        
        // For each element
        for(var i = 0; i < elementCount;i++) {
            
            // For each DataBlockStream, each element is made up of multiple streams
            
            for  dataBlockStream in streams {
                // Each stream can be made up of multiple values, vertex has 3 floats, UV has 2 floats
                var values: [Scalar] = []
                
                for(var v = 0;v < dataBlockStream.dataType.componentCount;v++) {
                    switch(dataBlockStream.dataType.valueType) {
                    case .Float:
                        values.append(dataBuffer.getFloat32())
                    case .UChar:
                        values.append(Int32(dataBuffer.getUInt8()))
                    case .Half:
                        values.append(dataBuffer.readHalf()!)
                    case .UInt:
                        let value = dataBuffer.getUInt32()
                        values.append(Int32(value))
                    }
                }
                
                dataBlockStream.elements.append(values)
            }
        }
        print("\(streams[0].elements.count)")
        
        
    }
    
    
    func streamForRenderType(renderType: PSSGRenderType) -> PSSGDataBlockStream? {
        let streamsWithType = streams.filter { (stream) -> Bool in stream.renderType == renderType }
        return streamsWithType.first
    }
}

extension PSSGDataBlock {
    
    var vertexStream: PSSGDataBlockStream? {
        // Convenient function to get the vertex stream (If available) without worrying about type
        if let standardVertexStream = streamForRenderType(.Vertex) {
            return standardVertexStream
        } else if let skinnableVertexStream = streamForRenderType(.SkinnableVertex) {
            return skinnableVertexStream
        }
        
        return nil
    }
    
    var normalStream: PSSGDataBlockStream? {
        // Convenient function to get the normal stream (If available) without worrying about skinnable types
        if let standardNormal = streamForRenderType(.Normal) {
            return standardNormal
        } else if let skinnableNormalStream = streamForRenderType(.SkinnableNormal) {
            return skinnableNormalStream
        }
        
        return nil
    }
    
    // Some more convenient functions
    func verticesFromOffset(streamOffset: Int, elementCount: Int) -> [SCNVector3]? {
        return []
    }
    
    func normalsFromOffset(streamOffset: Int, elementCount: Int) -> [SCNVector3]? {
        return []
    }
    
    
}

