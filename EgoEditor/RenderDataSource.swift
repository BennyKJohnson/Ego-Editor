//
//  RenderDataSource.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 15/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

// Scalar value to make data uniform. In a perfect world I would just be able to read stream directly into SceneKit. Thanks Codemasters for using Big Endian and Half Floats.
protocol Scalar {
    init (_ value: Int32)
    init (_ value: Float)
}
extension Float: Scalar {}
extension Int32: Scalar {}


enum RenderValueType: String {
    case Float = "float"
    case Half = "half"
    case UChar = "uchar"
    case UInt = "uint"
}

struct RenderDataType {
    let valueType: RenderValueType
    let componentCount: Int // Number of components
    
    init(typeString: String) {
        var valueTypeString = typeString
        // Special cases
        if typeString == "uint_color_argb" {
            componentCount = 4
            valueType = .UChar
        } else {
            // Extract the array length from string eg half4, get the 4 component from string
            if let componentCountMatch = typeString.rangeOfString("\\d$", options: .RegularExpressionSearch) {
                
                componentCount = Int(typeString.substringFromIndex(componentCountMatch.startIndex))!
                valueTypeString = typeString.substringToIndex(componentCountMatch.startIndex)
                
            } else {
                componentCount = 1
            }
            
            self.valueType = RenderValueType(rawValue: valueTypeString.lowercaseString)!
        }
    }
    
}

// A bit ridged considering there maybe values I miss however this will improve performance
enum PSSGRenderType {
    case Vertex             // Vertices that define the shape of the 3D model
    case SkinnableVertex    // Like Vertex but are attached to bones used for animation
    
    case Normal             // Direction of faces
    case SkinnableNormal    // Normals basically
    case Color
    
    case ST                 // UV coordinates, maybe multiple ST sets for a vertex
    case Tagent
    case Binormal
    
    case Unknown//(String)    // For unrecognise type that could appear, a lot easier to switch on a non optional type, plus bonus of additional info
    
    init(typeString: String) {
        switch(typeString) {
        case "Normal":
            self = .Normal
        case "ST":
            self = .ST
        case "Tangent":
            self = .Tagent
        case "Binormal":
            self = .Binormal
        case "Vertex":
            self = .Vertex
        case "Color":
            self = .Color
        default:
            self = .Unknown//(typeString)
        }
    }
}

class PSSGDataBlockStream {
    var renderType: PSSGRenderType!
    var dataType: RenderDataType!
    var elements: [[Scalar]] = []
    
    init?(dataBlockStreamNode: PSSGNode) {
        guard let type = dataBlockStreamNode.attributesDictionary["renderType"]?.formattedValue as? String, dataTypeString = dataBlockStreamNode.attributesDictionary["dataType"]?.formattedValue as? String  else {
            return nil
        }
        
        self.renderType = PSSGRenderType(typeString: type)
        dataType = RenderDataType(typeString: dataTypeString)
        
    }
    
}


struct PSSGRenderStream {
    
    let dataBlockID: String
    
    let subStream: Int
    
    let id: String
    
    init?(node renderStreamNode: PSSGNode) {
        guard let dataBlockID = renderStreamNode.attributesDictionary["dataBlock"]?.value as? String,
            subStream = renderStreamNode.attributesDictionary["subStream"]?.value as? Int,
            id = renderStreamNode.attributesDictionary["id"]?.value as? String else {
                // Not a RenderStream Node
                return nil
        }
        
        // Set properties
        self.dataBlockID = dataBlockID
        self.subStream = subStream
        self.id = id
        
        
    }
}

struct PSSGRenderDataSource {
    
    let streamCount: Int
    
    let id: String
    
    let renderStreams:[PSSGRenderStream]
    
    var renderIndexSource: PSSGNode
    
    init?(renderDataSourceNode: PSSGNode) {
        guard let streamCount = renderDataSourceNode.attributesDictionary["streamCount"]?.value as? Int,
            id = renderDataSourceNode.attributesDictionary["streamCount"]?.value as? String,
            renderIndexSourceNode = renderDataSourceNode.nodeWithName("RENDERINDEXSOURCE") else {
                // Not a RenderDataSource Node
                return nil
        }
        
        self.streamCount = streamCount
        self.id = id
        self.renderIndexSource = renderIndexSourceNode
        
        // Get Render Streams for data source
        let renderStreamNodes = renderDataSourceNode.nodesWithName("RENDERSTREAM")
        var tempRenderStreams: [PSSGRenderStream] = []
        
        for renderStreamNode in renderStreamNodes {
            if let renderStream = PSSGRenderStream(node: renderStreamNode) {
                tempRenderStreams.append(renderStream)
            }
        }
        
        renderStreams = tempRenderStreams
    }
}






// Manages the DataBlocks in a PSSG File
struct RenderInterfaceBound {
    var dataBlocks: [String: PSSGDataBlock] = [:]
    
    init(dataBlockNodes: [PSSGNode]) {
        for dataBlockNode in dataBlockNodes {
            if let dataBlock = PSSGDataBlock(dataBlockNode: dataBlockNode) {
                
                // Add to dictionary
                dataBlocks[dataBlock.id] = dataBlock
            }
          
        }
    }
    

    
}
