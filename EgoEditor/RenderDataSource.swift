//
//  RenderDataSource.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 15/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

// Scalar value to make data uniform. In a perfect world I would just be able to read stream directly into SceneKit. Thanks Codemasters for using Big Endian.
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
    
    func parseData(data: NSData) -> [Scalar] {
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes);
        let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        
        
        var values: [Scalar] = []
        
        for(var v = 0;v < componentCount;v++) {
            switch(valueType) {
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
        
        return values
    }
    
    
    
}

enum GeometrySourceSemantic {
    case Vertex
    case Normal
    case Color
    case TexCoord
    case VertexCrease
    case EdgeCrease
    case BoneWeights
    case BoneIndices
    
    var scnGeometrySourceSemantic: String? {
        switch(self) {
        case .Vertex:
            return SCNGeometrySourceSemanticVertex
        case .Normal:
            return SCNGeometrySourceSemanticNormal
        case .TexCoord:
            return SCNGeometrySourceSemanticTexcoord
        case .VertexCrease:
            return SCNGeometrySourceSemanticVertexCrease
        case .EdgeCrease:
            return SCNGeometrySourceSemanticEdgeCrease
        case .BoneWeights:
            return SCNGeometrySourceSemanticBoneWeights
        case .BoneIndices:
            return SCNGeometrySourceSemanticBoneIndices
        default:
            return nil
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
        case "SkinnableVertex":
            self = .SkinnableVertex
        case "SkinnableNormal":
            self = .SkinnableNormal
        case "Color":
            self = .Color
        default:
            self = .Unknown//(typeString)
        }
    }
    
    var geometrySourceSemantic: GeometrySourceSemantic? {
        switch(self) {
        case .Vertex, .SkinnableVertex:
            return .Vertex
        case .Normal, .SkinnableNormal:
            return .Normal
        case .Color:
            return .Color
        case .ST:
            return .TexCoord
            
        default:
            return nil
        }
    }
}

class PSSGDataBlockStream {
    var renderType: PSSGRenderType!
    var dataType: RenderDataType!
    var elements: [[Scalar!]] = []
    
    init?(dataBlockStreamNode: PSSGNode) {
        guard let type = dataBlockStreamNode.attributesDictionary["renderType"]?.formattedValue as? String, dataTypeString = dataBlockStreamNode.attributesDictionary["dataType"]?.formattedValue as? String  else {
            return nil
        }
        
        self.renderType = PSSGRenderType(typeString: type)
        dataType = RenderDataType(typeString: dataTypeString)
        
    }
    
}

extension PSSGDataBlockStream {
    
    func vectorDataFromStreamOffset(streamOffset:Int, count: Int) -> [SCNVector3]? {
        // Verify number of components
        guard dataType.componentCount > 2 else {
            // Incorrect component count, expecting 3 -> x,y,z
            return nil
        }
        
        var vertices: [SCNVector3] = []
        for(var i = streamOffset; i < streamOffset + count;i++) {
            let vertexData  = elements[i]
            // Get position components
            let x = vertexData[0] as! Float
            let y = vertexData[1] as! Float
            let z = vertexData[2] as! Float
            
            vertices.append(SCNVector3(x,y,z))
            
        }
        
        return vertices
    }
    
    func coordinateDataFromStreamOffset(streamOffset:Int, count: Int) -> [STCoordinate]? {
        
        guard dataType.componentCount > 1 else {
            return nil
        }
        var coordinates: [STCoordinate] = []
        for(var i = streamOffset; i < streamOffset + count;i++) {
            let coordinateData  = elements[i]
            // Get position components
            let x = coordinateData[0] as! Float
            let y = coordinateData[1] as! Float
            
            let coordinate = CGPoint(x: CGFloat(x), y: CGFloat(y))
            coordinates.append(coordinate)
            
        }
        
        return coordinates
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
        self.dataBlockID =  dataBlockID.stringByReplacingOccurrencesOfString("#", withString: "")
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
            id = renderDataSourceNode.attributesDictionary["id"]?.value as? String,
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
class RenderInterfaceBound {
    var dataBlockNodes: [String: PSSGNode] = [:]
    var dataBlocks: [String: PSSGDataBlock] = [:]
    
    // Lazy load data blocks when required
    func dataBlockForID(ID: String) -> PSSGDataBlock? {
        
        if let loadedDataBlock = dataBlocks[ID] {
            return loadedDataBlock
        } else if let dataBlockNode = dataBlockNodes[ID] {
            // Create processed DataBlock
            if let dataBlock = PSSGDataBlock(dataBlockNode: dataBlockNode) {
                // Add to dictionary
                dataBlocks[dataBlock.id] = dataBlock
                return dataBlock
            }
        }
        
        return nil
    }
    
    init(nodes: [PSSGNode]) {
        for dataBlockNode in nodes {
            guard let id = dataBlockNode.attributesDictionary["id"]?.formattedValue as? String else {
                // Doesn't have ID, not  valid
                break
            }
            
            dataBlockNodes[id] = dataBlockNode

        }
    
    }
    

    
}
