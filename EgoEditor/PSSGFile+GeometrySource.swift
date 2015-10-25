//
//  PSSGFile+GeometrySource.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

extension NSData
{
    var byteBuffer : UnsafeMutablePointer<UInt8> { get { return UnsafeMutablePointer<UInt8>(self.bytes) }}
}

extension SCNGeometrySource {
    convenience init(data: NSData, renderType: String, vectorCount: Int, dataType: String, offset: Int, stride: Int) {
        let semantic: String
        var componentsPerVector:Int = 3
        var floatComponents = true
        var bytesPerComponent = sizeof(Float)
        
        switch(renderType) {
        case "Vertex":
            semantic =  SCNGeometrySourceSemanticVertex
            
        case "Color":
            semantic =  SCNGeometrySourceSemanticColor
            componentsPerVector = 4
            floatComponents = false
            bytesPerComponent = sizeof(UInt8)
            
            // Modify the data
            
        case "Normal":
            semantic =  SCNGeometrySourceSemanticNormal
        default:
            fatalError("Unsupported render type \(renderType)")
        }
        
        self.init(data: data, semantic: semantic, vectorCount: vectorCount, floatComponents: floatComponents, componentsPerVector: componentsPerVector, bytesPerComponent: bytesPerComponent, dataOffset: dataOffset, dataStride: dataStride)
    }
}

typealias STCoordinate = CGPoint

struct GeometryDataSource {
    
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var geometrySources: [SCNGeometrySource] = []
    
    static func renderTypeToSourceSemantic(renderType:String) -> String? {
        switch(renderType) {
        case "Vertex":
            return SCNGeometrySourceSemanticVertex
        case "Color":
            return SCNGeometrySourceSemanticColor
        case "Normal":
            return SCNGeometrySourceSemanticNormal
        default:
            return nil
        }
    }
    
    static func getSTData(dataBlock: PSSGNode, renderDataSourceInfo: RenderDataSourceInfo) -> [STCoordinate] {
        let dataBlockStreams = dataBlock.nodesWithName("DATABLOCKSTREAM")
        let firstStream = dataBlockStreams.first!
        
        // Get stride
        let stride = firstStream.attributesDictionary["stride"]?.formattedValue as! Int
        
        let startOffset = renderDataSourceInfo.streamOffset * stride
        let length = stride * renderDataSourceInfo.elementCountFromOffset
        
        // Prepare data
        let rawData = dataBlock.nodeWithName("DATABLOCKDATA")!.data as! NSData
        
        let data = rawData.subdataWithRange(NSMakeRange(startOffset, length));
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes);
        
        // Create a buffer that holds the bytes so we can read in big endian
        let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        var stCoordinates: [STCoordinate] = []
        // For each vector
        for(var i = 0; i < renderDataSourceInfo.elementCountFromOffset;i++) {
            // UV xy
            let x = CGFloat(dataBuffer.readHalf()!)
            let y = CGFloat(dataBuffer.readHalf()!)
            stCoordinates.append(STCoordinate(x: x, y: y))
            
            // Not sure what these values are, x,y
            let _ = dataBuffer.getInt16()
            let _ = dataBuffer.getInt16()
            
            // Tangent - offset 8
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            
            // Binormal - offset 16
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            dataBuffer.getInt16()
            
            if stride == 28 {
                // Additional ST, not sure what this is
                dataBuffer.getInt16()
                dataBuffer.getInt16()
            }
            
        }
        return stCoordinates
    }
    
    init(dataBlock: PSSGDataBlock, transform: SCNMatrix4, renderDataSourceInfo: RenderDataSourceInfo) {
        //let size = dataBlock.attributesDictionary["size"]!.value as! Int
        
        let elementCount = renderDataSourceInfo.elementCountFromOffset
        let streamOffset = renderDataSourceInfo.streamOffset
        
        // Get Vertex Data
        let vertexStream = dataBlock.streamForRenderType(.Vertex)!
        let verticeData = vertexStream.elements//[streamOffset...streamOffset + elementCount]
        print("Vertex Count in \(dataBlock.id) \(elementCount) / \(dataBlock.elementCount)")
        for(var i = streamOffset; i < streamOffset + elementCount;i++) {
            let vertexData  = vertexStream.elements[i]
            // Get position components
            let x = vertexData[0] as! Float
            let y = vertexData[1] as! Float
            let z = vertexData[2] as! Float
            
            vertices.append(SCNVector3(x,y,z))
            
        }
        
        let normalStream = dataBlock.streamForRenderType(.Normal)!
        let normalElements = normalStream.elements//[streamOffset...streamOffset + elementCount]
        for(var i = streamOffset; i < streamOffset + elementCount;i++) {
            let normalData  = normalElements[i]
            // Get position components
            let x = normalData[0] as! Float
            let y = normalData[1] as! Float
            let z = normalData[2] as! Float
            
            normals.append(SCNVector3(x,y,z))
            
        }
        
        /*
        
        let data = rawData.subdataWithRange(NSMakeRange(startOffset, length));
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes);
        
        // Create a buffer that holds the bytes so we can read in big endian
        let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        //dataBuffer.flip()
        
        // Convert Data
        let validData = NSMutableData(capacity: size)!
        
        //  var normals: [F;pat]
        for(var i = 0; i < renderDataSourceInfo.elementCountFromOffset;i++) {
        
        let x = dataBuffer.getFloat32()
        let y = dataBuffer.getFloat32()
        let z = dataBuffer.getFloat32()
        
        let vertex = [x,y ,z]
        vertices.append(SCNVector3(x,y,z))
        validData.appendData(NSData(bytes: vertex, length: 12))
        
        let color = [dataBuffer.getUInt8(),dataBuffer.getUInt8(), dataBuffer.getUInt8(), dataBuffer.getUInt8()]
        validData.appendData(NSData(bytes: color, length: color.count * sizeof(UInt8)))
        
        let normal = SCNVector3(dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32()) //[dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32()]
        normals.append(normal)
        //    validData.appendData(NSData(bytes: normal, length: normal.count * sizeof(Float)))
        
        }
        */
        let verticeSource = SCNGeometrySource(vertices: &vertices, count: vertices.count)
        geometrySources.append(verticeSource)
        
        let normalSource = SCNGeometrySource(normals: &normals, count: normals.count)
        geometrySources.append(normalSource)
        
        
        /*
        for dataBlockStream in dataBlock.nodesWithName("DATABLOCKSTREAM") {
        let renderType = dataBlockStream.attributesDictionary["renderType"]?.value as! String
        let stride = dataBlockStream.attributesDictionary["stride"]!.value as! Int
        let offset = dataBlockStream.attributesDictionary["offset"]!.value as! Int
        let dataType = dataBlockStream.attributesDictionary["renderType"]?.value as! String
        print("\(renderType) stride: \(stride) offset: \(offset)")
        
        // Create Geometry Source
        let geometrySource = SCNGeometrySource(data: validData, renderType: renderType, vectorCount: elementCount, dataType: dataType, offset: offset, stride: stride)
        
        geometrySources.append(geometrySource)
        
        }
        */
        /*
        for(var i = 0; i < size;i += stride) {
        // Create vertex for x,y,z position
        let vertice = SCNVector3(dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32())
        vertices.append(vertice)
        
        // Get Colour of vertex
        let color = dataBuffer.getInt32()
        
        // Get normal value for vertex
        let normal = SCNVector3(dataBuffer.getFloat32(),dataBuffer.getFloat32(),dataBuffer.getFloat32())
        normals.append(normal)
        
        }
        */
    }
    
    
    
    
    init(renderDataSource: PSSGNode, dataBlock: PSSGNode, transform: SCNMatrix4, renderDataSourceInfo: RenderDataSourceInfo) {
        let size = dataBlock.attributesDictionary["size"]!.value as! Int
        
        let elementCount = dataBlock.attributesDictionary["elementCount"]?.value as! Int
        // Finally we get to the actual vertex data
        let rawData = dataBlock.nodeWithName("DATABLOCKDATA")!.data as! NSData
        let stride = 28
        let startOffset = renderDataSourceInfo.streamOffset * stride
        let length = 28 * renderDataSourceInfo.elementCountFromOffset
        
        
        let data = rawData.subdataWithRange(NSMakeRange(startOffset, length));
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes);
        
        // Create a buffer that holds the bytes so we can read in big endian
        let dataBuffer = ByteBuffer(order: BigEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        //dataBuffer.flip()
        
        // Convert Data
        let validData = NSMutableData(capacity: size)!
        
        //  var normals: [F;pat]
        for(var i = 0; i < renderDataSourceInfo.elementCountFromOffset;i++) {
            
            let x = dataBuffer.getFloat32()
            let y = dataBuffer.getFloat32()
            let z = dataBuffer.getFloat32()
            
            let vertex = [x,y ,z]
            vertices.append(SCNVector3(x,y,z))
            validData.appendData(NSData(bytes: vertex, length: 12))
            
            let color = [dataBuffer.getUInt8(),dataBuffer.getUInt8(), dataBuffer.getUInt8(), dataBuffer.getUInt8()]
            validData.appendData(NSData(bytes: color, length: color.count * sizeof(UInt8)))
            
            let normal = SCNVector3(dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32()) //[dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32()]
            normals.append(normal)
            //    validData.appendData(NSData(bytes: normal, length: normal.count * sizeof(Float)))
            
        }
        
        let verticeSource = SCNGeometrySource(vertices: &vertices, count: vertices.count)
        geometrySources.append(verticeSource)
        
        let normalSource = SCNGeometrySource(normals: &normals, count: normals.count)
        geometrySources.append(normalSource)
        
        
        /*
        for dataBlockStream in dataBlock.nodesWithName("DATABLOCKSTREAM") {
        let renderType = dataBlockStream.attributesDictionary["renderType"]?.value as! String
        let stride = dataBlockStream.attributesDictionary["stride"]!.value as! Int
        let offset = dataBlockStream.attributesDictionary["offset"]!.value as! Int
        let dataType = dataBlockStream.attributesDictionary["renderType"]?.value as! String
        print("\(renderType) stride: \(stride) offset: \(offset)")
        
        // Create Geometry Source
        let geometrySource = SCNGeometrySource(data: validData, renderType: renderType, vectorCount: elementCount, dataType: dataType, offset: offset, stride: stride)
        
        geometrySources.append(geometrySource)
        
        }
        */
        /*
        for(var i = 0; i < size;i += stride) {
        // Create vertex for x,y,z position
        let vertice = SCNVector3(dataBuffer.getFloat32(), dataBuffer.getFloat32(), dataBuffer.getFloat32())
        vertices.append(vertice)
        
        // Get Colour of vertex
        let color = dataBuffer.getInt32()
        
        // Get normal value for vertex
        let normal = SCNVector3(dataBuffer.getFloat32(),dataBuffer.getFloat32(),dataBuffer.getFloat32())
        normals.append(normal)
        
        }
        */
    }
}



struct RenderDataSourceInfo {
    let streamOffset: Int
    let elementCountFromOffset: Int
    let indexOffset: Int
    let indicesCountFromOffset:Int
    
    
    init?(jointRenderInstanceNode:PSSGNode) {
        guard let streamOffset = jointRenderInstanceNode.attributesDictionary["streamOffset"]?.value as? Int,
         elementCountFromOffset = jointRenderInstanceNode.attributesDictionary["elementCountFromOffset"]?.value as? Int,
        indexOffset = jointRenderInstanceNode.attributesDictionary["indexOffset"]?.value as? Int,
            indicesCountFromOffset = jointRenderInstanceNode.attributesDictionary["indicesCountFromOffset"]?.value as? Int else {
                return nil
        }
        
        self.streamOffset = streamOffset
        self.elementCountFromOffset = elementCountFromOffset
        self.indexOffset = indexOffset
        self.indicesCountFromOffset = indicesCountFromOffset
    }
}

extension PSSGFile {
    func isGeometrySourceProvider() -> Bool {
        // Seems to be the common indicator among
        let libraryNodes = rootNode.nodesWithName("LIBRARY")
        for libraryNode in libraryNodes {
            if let type = libraryNode.attributesDictionary["type"]?.formattedValue as? String {
                if type == "RENDERINTERFACEBOUND" {
                    return true
                }
            }
        }
        
        
        return false
    }
    
    

    
    struct GeometryElementSource {
        var modelVertices: [SCNVector3] = []
        var modelNormals: [SCNVector3] = []
        var modelUVs: [STCoordinate] = []
        var textureCoordinates: [[STCoordinate]] = []
        var indices: [UInt32] = []
        var geometryElement: [SCNGeometryElement] = []
        
        init(renderDataSource: PSSGRenderDataSource,renderDataSourceInfo: RenderDataSourceInfo?, renderInterfaceBound: RenderInterfaceBound?, indiceOffset: Int) {
            
            
            
            // Get Indices
            
            let renderIndexSource = renderDataSource.renderIndexSource // .nodeWithName("RENDERINDEXSOURCE")!
            
            let indices = getIndices(renderIndexSource, renderDataSourceInfo: renderDataSourceInfo, indiceOffset: indiceOffset)
            
            let indexData = NSData(bytes: indices, length: indices.count * sizeof(UInt32))
            
            // Create Geometry Element
            geometryElement = [SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: indices.count
                / 3, bytesPerIndex: sizeof(UInt32))]
            
            
            var hasUVSource = false
            var currentUVIndex = 0

            // Get Geometry Sources
            for renderStream in renderDataSource.renderStreams {
                let dataBlockID = renderStream.dataBlockID
                let subStream = renderStream.subStream

                guard let dataBlock = renderInterfaceBound?.dataBlockForID(dataBlockID) else  {
                    break
                }
                
                let streamOffset = renderDataSourceInfo?.streamOffset ?? 0
                let elementCountFromOffset = renderDataSourceInfo?.elementCountFromOffset ?? dataBlock.elementCount
                
               let dataBlockStream = dataBlock.streams[subStream]
                    guard let geometrySourceSematic = dataBlockStream.renderType.geometrySourceSemantic else {
                        // Can't parse into SceneKit
                        break
                    }
                    

                    switch(geometrySourceSematic) {
                    case .Vertex:
                        let vertices = dataBlockStream.vectorDataFromStreamOffset(streamOffset, count: elementCountFromOffset)!
                        modelVertices += vertices
                        
                    case .Normal:
                        if  let normals = dataBlockStream.vectorDataFromStreamOffset(streamOffset, count: elementCountFromOffset) {
                            modelNormals += normals
                        } 
                    case .TexCoord:
                        let stCoordinates = dataBlockStream.coordinateDataFromStreamOffset(streamOffset, count: elementCountFromOffset)!

                        if !hasUVSource {
                            
                            modelUVs += stCoordinates
                            hasUVSource = true

                        }
                        
                            if currentUVIndex < textureCoordinates.count {
                                textureCoordinates[currentUVIndex] += stCoordinates
                            } else {
                                textureCoordinates.append(stCoordinates)
                            }
                            currentUVIndex++
                            
                        
                        
                    default:
                        break
                    }
                    
                
            }
            
            
            
        }
        
        func getIndices(renderIndexSource: PSSGNode,renderDataSourceInfo: RenderDataSourceInfo?,  indiceOffset: Int) -> [UInt32] {
            let format = renderIndexSource.attributesDictionary["format"]?.value as? String
            
            let indexCount = renderIndexSource.attributesDictionary["count"]?.value as! Int
            let indexOffset = renderDataSourceInfo?.indexOffset ?? 0
            let streamOffset = renderDataSourceInfo?.streamOffset ?? 0
            let indicesCountFromOffset = renderDataSourceInfo?.indicesCountFromOffset ?? indexCount
            
            
            let rawIndexSourceData = renderIndexSource.nodeWithName("INDEXSOURCEDATA")?.data as! NSData
            let indexSourceData = rawIndexSourceData// rawIndexSourceData.subdataWithRange(NSMakeRange(renderDataSourceInfo.indexOffset, sizeof(UInt16) * renderDataSourceInfo.indicesCountFromOffset));
            let indexSourceDataPointer = UnsafeMutablePointer<UInt8>(indexSourceData.bytes);
            
            // Load into buffer
            let dataBuffer = ByteBuffer(order: BigEndian(), data: indexSourceDataPointer, capacity: indexSourceData.length, freeOnDeinit: false)
            let originalIndices: [UInt32]
            if let formatType = format where formatType == "uint" {
                originalIndices = Array(dataBuffer.getUInt32((rawIndexSourceData.length / sizeof(UInt32)))[indexOffset...indexOffset + indicesCountFromOffset-1])
            } else {
                originalIndices = Array(dataBuffer.getUInt16((rawIndexSourceData.length / sizeof(UInt16)))[indexOffset...indexOffset + indicesCountFromOffset-1]).map({ (indice) -> UInt32 in
                    return UInt32(indice)
                })
            }
            
            
            // Normalise indices based on stream (vector) offset.
            let indices = originalIndices.map({ (indice) -> UInt32 in
                indice - UInt32(streamOffset) + UInt32(indiceOffset)
            })
            
            return indices
        }
    }
    
    
    enum PSSGGeometryInfo {
        case MatrixPattleBundle
        case SkinNode
        case RenderNode
        case TrackSplit
        
        var bundleNode: String? {
            switch(self) {
            case .MatrixPattleBundle:
                return "MATRIXPALETTEBUNDLENODE"
            case .SkinNode:
                return nil
            case .RenderNode:
                return "ROOTNODE"
            case .TrackSplit:
                return "NODE"
            }
        }
        
        var jointNode: String {
            switch(self) {
            case .MatrixPattleBundle:
                return "MATRIXPALETTEJOINTNODE"
            case .SkinNode:
                return "SKINNODE"
            case .RenderNode:
                return "LODVISIBLERENDERNODE"
            case .TrackSplit:
                return "RENDERNODE"
            }
 
        }
        
        var altJointNode:String? {
            switch(self) {
            case .MatrixPattleBundle:
                return nil
            case .SkinNode:
                return nil
            case .RenderNode:
                return "RENDERNODE"
            case .TrackSplit:
                return nil
            }
        }
        
        var renderInstanceNode: String {
            switch(self) {
            case .MatrixPattleBundle:
                return "MATRIXPALETTEJOINTRENDERINSTANCE"
            case .SkinNode:
                return "MODIFIERNETWORKINSTANCE"
            case .RenderNode:
                return "RENDERSTREAMINSTANCE"
            case .TrackSplit:
                return "RENDERSTREAMINSTANCE"

            }
        }
    }
    
    func setMaterialProperty(materialProperty: SCNMaterialProperty, texture: PSSGTexture) {
        // Load texture into material
        materialProperty.contents  = texture.ddsFile?.CreateImage().takeUnretainedValue()
        if texture.wrapS > 0 {
            materialProperty.wrapS = SCNWrapMode.Repeat
        }
        if texture.wrapT > 0 {
            materialProperty.wrapT = SCNWrapMode.Repeat
        }
        
    }
    
    
    func getMaterials() -> [String: SCNMaterial] {
        
        var materials: [String: SCNMaterial] = [:]
        
        let shaderGroupNodes = rootNode.nodesWithName("SHADERGROUP")
        var shaderGroups: [String:PSSGShaderGroup] = [:]
        
        for shaderGroupNode in shaderGroupNodes {
            if let shaderGroup = PSSGShaderGroup(shaderGroupNode: shaderGroupNode) {
                shaderGroups[shaderGroup.id] = shaderGroup
            }
        }
        
        let shaderInstanceNodes = rootNode.nodesWithName("SHADERINSTANCE")
        for shaderInstanceNode in shaderInstanceNodes {
            if let shaderInstance = PSSGShaderInstance(shaderInstanceNode: shaderInstanceNode) {
                
                // Create Material
                let material = SCNMaterial()
                material.name = shaderInstance.id
                var transform: SCNMatrix4? = nil
                
                for shaderInput in shaderInstance.shaderInputs {
                    // Get corresponding parameter in shader group
                    let shaderInputDefinition = shaderGroups[shaderInstance.shaderGroup.identifier]!.shaderInputDefinations[shaderInput.parameterID]
                    
                    if let textureID = shaderInput.textureID {
              
                        switch(shaderInputDefinition.name) {
                    
                        case "TDiffuseAlphaMap", "TColourMap","TlargeColourMap":
                            
                            // Get texture if exists
                            if let texture = textureManager.textures[textureID.identifier]  {
                                
                                setMaterialProperty(material.diffuse, texture: texture)
                            
                                break
                            }

                            
                         
                            guard let pssgDirectory = url?.URLByDeletingLastPathComponent where  textureManager.textures[textureID.identifier] == nil  else  {
                                break
                            }
                            /*
                            if shaderInputDefinition.name == "TColourMap" {
                                print("ColourMap")
                                break
                            }
                            */
                            
                            if let textureFilename = textureID.externalReference where !textureFilename.isEmpty {
                                
                                // Actual Textures seem to be stored in patchup_ot.pssg rather than objectstextures.pssg
                                let modifiedTextureFilename = textureFilename.stringByReplacingOccurrencesOfString("objectstextures", withString: "patchup_ot")
                                
                                // Attempt to load texture
                                let textureURL = pssgDirectory.URLByAppendingPathComponent(modifiedTextureFilename)
                                textureManager.loadTexturesFromURL(textureURL)
                            } else if let textureFilename = url?.lastPathComponent where !textureManager.loadedFiles.contains(textureFilename) {
                                
                                textureManager.loadTexturesFromPSSG(self)
                            }
                            
                            // Get texture if exists
                            if let texture = textureManager.textures[textureID.identifier]  {
                            
                                
                                // Load texture into material
                                setMaterialProperty(material.diffuse, texture: texture)

                                
                            }
                            
                        default:
                            break
                        }
                        
                        
                    } else if let format = shaderInput.format {
                        switch(shaderInputDefinition.name) {
                        case "ColourMapScale":
                            if let scale = shaderInput.inputData?.first as? Float {
                                // Set Transform
                                transform = SCNMatrix4MakeScale(CGFloat(scale), CGFloat(scale), CGFloat(scale))
                                
                            }
                        case "Map1UVScaleAndOffset":
                            if let offsetScale = shaderInput.inputData where offsetScale.count == 4 {
                                
                                let xScale = CGFloat(offsetScale[0] as! Float)
                                let yScale = CGFloat(offsetScale[1] as! Float)
                                let xOffset = CGFloat(offsetScale[2] as! Float)
                                let yOffset = CGFloat(offsetScale[3] as! Float)
                                
                                let scaleTransform =  SCNMatrix4MakeScale(xScale, yScale, 1.0)
                                let newTransform = SCNMatrix4Translate(scaleTransform, xOffset, yOffset, 0)
                                
                                
                                print(offsetScale)
                                
                                
                            }
                            //shaderInput.
                        default:
                            break
                        }
                    }
                }
                
                if let transform = transform {
                    material.diffuse.contentsTransform = transform
                   
                }
                // Automatically repeat, Needs fixing to read in texture node
               // material.diffuse.wrapS = SCNWrapMode.Repeat
               // material.diffuse.wrapT = SCNWrapMode.Repeat
                
                // Append Material
                materials[material.name!] = material
                
            }
        }
        
        
        return materials
        
    }
    
    func nodesForLevelOfDetails(renderNodes: [PSSGNode]) -> [PSSGNode] {
        let nodes = renderNodes.filter({ (node) -> Bool in
            let nickname = node.attributesDictionary["nickname"]!.formattedValue as! String
            return !nickname.hasPrefix("SHADOWCASTING") && !nickname.hasPrefix("DECAL") && !nickname.containsString("BATCH")
        })

        
        let highLODNodes = nodes.filter({ (node) -> Bool in
            let nickname = node.attributesDictionary["nickname"]!.formattedValue as! String
            return nickname.hasPrefix("HIGH")
        })
        
        if highLODNodes.count > 0 {
           return nodes.filter({ (node) -> Bool in
                let nickname = node.attributesDictionary["nickname"]!.formattedValue as! String
                return !nickname.hasPrefix("LOW")
            })
        }
        
        
        
        return renderNodes
    }
    
    func geometryForObject() -> [Model] {
        // Get rootNode
        
        let sceneRootNodes = rootNode.nodesWithName("ROOTNODE") 
        if sceneRootNodes.count == 0 {
            return []
        }
        
        
        let geometryInfo: PSSGGeometryInfo
        let rootNodes: [PSSGNode]
        if let mphnNode = rootNode.nodesWithName("MATRIXPALETTEBUNDLENODE").last {
            geometryInfo = PSSGGeometryInfo.MatrixPattleBundle
            rootNodes = [mphnNode]
        } else if sceneRootNodes.count > 1 {
            geometryInfo = PSSGGeometryInfo.RenderNode
            
            rootNodes = sceneRootNodes
   
        } else  {
            // Check if Nodes
            let nodes = sceneRootNodes[0].childNodesWithName("NODE", recursively: false)
            if nodes.count > 0 {
                // TrackSplit Hopefully
                geometryInfo = PSSGGeometryInfo.TrackSplit
                rootNodes = nodes.last!.childNodesWithName("NODE", recursively: false)
                
            } else {
                geometryInfo = PSSGGeometryInfo.SkinNode
                rootNodes = sceneRootNodes
            }

        }
        
       
        var models: [Model] = []
        var materials: [String:SCNMaterial] = getMaterials()
        
        for mpbNode in rootNodes {
            var modelName = "<unknown>"

            let id = mpbNode.attributesDictionary["id"]?.value as! String
            print("ID: \(id)")
            
            if geometryInfo == .RenderNode {
                modelName = id.stringByReplacingOccurrencesOfString(" Root", withString: "")
            } else if geometryInfo == .TrackSplit {
                modelName = id

            }
            
            
            var jointNodes = mpbNode.nodesWithName(geometryInfo.jointNode) // SKINNODE
            if let altJointName = geometryInfo.altJointNode where jointNodes.count == 0 {
                // Try alternative node name
                jointNodes = mpbNode.nodesWithName(altJointName) // SKINNODE
            }
            if geometryInfo == .TrackSplit {
                jointNodes = nodesForLevelOfDetails(jointNodes)
            }
            
            // For each Geometry Object
            for jointNode in jointNodes {
                if geometryInfo != .RenderNode && geometryInfo != .TrackSplit {
                    modelName = jointNode.attributesDictionary["nickname"]?.value as! String
                }
                print(modelName)
                let transformData = jointNode.nodeWithName("TRANSFORM")?.data! as! NSData
                let transform: SCNMatrix4 = SCNMatrix4.fromData(transformData)!
                
                var modelGeometryElements:[SCNGeometryElement] = []
                // var modelGeometrySources: [SCNGeometrySource] = []
                var modelMaterials: [SCNMaterial] = []
                
                var modelVertices: [SCNVector3] = []
                var modelNormals: [SCNVector3] = []
                var modelUVs: [STCoordinate] = []
                
                // For each sub geometry object. Sections with materials
                let renderInstanceNodes = jointNode.childNodesWithName(geometryInfo.renderInstanceNode, recursively: false)
                for jointRenderInstanceNode in renderInstanceNodes { // MODIFIERNETWORKINSTANCE
                    let renderInstanceID = jointRenderInstanceNode.attributesDictionary["indices"]!.value as! String
                    let nodeID = renderInstanceID.stringByReplacingOccurrencesOfString("#", withString: "")
                    let materialReferenceID = jointRenderInstanceNode.attributesDictionary["shader"]!.value as! String
                    let materialName = String(materialReferenceID.characters.dropFirst())// stringByReplacingOccurrencesOfString("#", withString: "")
                
                    
                    let renderDataSourceInfo = RenderDataSourceInfo(jointRenderInstanceNode: jointRenderInstanceNode)
                
                    // Get Material
                    if let existingMaterial = materials[materialName] {
                        modelMaterials.append(existingMaterial)
                    } else {
                        print("Material Not found \(materialName)")
                        let newMaterial = SCNMaterial()
                        newMaterial.name = materialName
                        materials[materialName] = newMaterial
                        modelMaterials.append(newMaterial)
                    }
                    
                    if let renderDataSource = self.renderDataSources?[nodeID] {
                        let geometrySource = GeometryElementSource(renderDataSource: renderDataSource, renderDataSourceInfo: renderDataSourceInfo, renderInterfaceBound: renderInterfaceBound, indiceOffset: modelVertices.count)
                        
                        // Append data
                        modelVertices += geometrySource.modelVertices
                        modelNormals += geometrySource.modelNormals
                        modelUVs += geometrySource.modelUVs
                        if geometrySource.textureCoordinates.count > 1 {
                            print("Got multiple UVs")
                        }
                        modelGeometryElements += geometrySource.geometryElement
                    
                    }
                }
                
                // Create Gemetry Sources
                var geometrySources: [SCNGeometrySource] = []
                
                if modelVertices.count > 0 {
                    let vertexSource = SCNGeometrySource(vertices: &modelVertices, count: modelVertices.count)
                    geometrySources.append(vertexSource)
                }
                
                if modelNormals.count > 0 {
                    let normalSource = SCNGeometrySource(normals: &modelNormals, count: modelNormals.count)
                    geometrySources.append(normalSource)
                }
                
                // Create UVs source
                if modelUVs.count > 0 {
                    let uvSource = SCNGeometrySource(textureCoordinates: &modelUVs, count: modelUVs.count)
                    geometrySources.append(uvSource)
                }
                
                // Save Model
                let geometryObject = SCNGeometry(sources: geometrySources, elements: modelGeometryElements)
                geometryObject.name = modelName
                print(geometryObject.name!)
                
                // Assign Materials
                geometryObject.materials = modelMaterials
                
                models.append(Model(transform: transform, geometry: geometryObject))
                
                
            }
        }
        
        return models
        
    }
}

extension SCNMatrix4 {
    static func fromData(data: NSData) -> SCNMatrix4? {
        let byteBuffer = ByteBuffer(order: BigEndian(), data: data.byteBuffer, capacity: data.length, freeOnDeinit: false)
        
        let rawValues = byteBuffer.getFloat32(16)
        if rawValues.count == 16 {
            // Great we have a valid matrix
            
            // This is kinda yuck, might want to right some sort of test. Walking on thin ice
            
            var matrix = SCNMatrix4()
            matrix.m11 = CGFloat(rawValues[0])
            matrix.m12 = CGFloat(rawValues[1])
            matrix.m13 = CGFloat(rawValues[2])
            matrix.m14 = CGFloat(rawValues[3])
            
            matrix.m21 = CGFloat(rawValues[4])
            matrix.m22 = CGFloat(rawValues[5])
            matrix.m23 = CGFloat(rawValues[6])
            matrix.m24 = CGFloat(rawValues[7])
            
            matrix.m31 = CGFloat(rawValues[8])
            matrix.m32 = CGFloat(rawValues[9])
            matrix.m33 = CGFloat(rawValues[10])
            matrix.m34 = CGFloat(rawValues[11])
            
            matrix.m41 = CGFloat(rawValues[12])
            matrix.m42 = CGFloat(rawValues[13])
            matrix.m43 = CGFloat(rawValues[14])
            matrix.m44 = CGFloat(rawValues[15])
            
            
            return matrix
        }
        return nil
    }
}