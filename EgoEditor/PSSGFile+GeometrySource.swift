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
    
    init(renderDataSource: PSSGNode, dataBlock: PSSGDataBlock, transform: SCNMatrix4, renderDataSourceInfo: RenderDataSourceInfo) {
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
    
    
    init(jointRenderInstanceNode:PSSGNode) {
        streamOffset = jointRenderInstanceNode.attributesDictionary["streamOffset"]?.value as! Int
        elementCountFromOffset = jointRenderInstanceNode.attributesDictionary["elementCountFromOffset"]?.value as! Int
        indexOffset = jointRenderInstanceNode.attributesDictionary["indexOffset"]?.value as! Int
        indicesCountFromOffset = jointRenderInstanceNode.attributesDictionary["indicesCountFromOffset"]?.value as! Int

    }
}

// YUCK CLEAN THIS SHIT UP!
extension PSSGFile {
    func isGeometrySourceProvider() -> Bool {
        
        return rootNode.nodeWithName("MATRIXPALETTEBUNDLENODE") != nil
    }
    
    
    
    
    func geometryForObject() -> [Model] {
        // Test dataSource code 
   
        
        let mphnNodes = [rootNode.nodesWithName("MATRIXPALETTEBUNDLENODE").last!]
        
        var models: [Model] = []
        var materials: [String:SCNMaterial] = [:]
        
        for mpbNode in mphnNodes {
            let lod = mpbNode.attributesDictionary["id"]?.value as! String
            print("LOD: \(lod)")
            
            let jointNodes = mpbNode.nodesWithName("MATRIXPALETTEJOINTNODE")
            // For each Geometry Object
            for jointNode in jointNodes {
                let modelName = jointNode.attributesDictionary["nickname"]?.value as! String
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
                for jointRenderInstanceNode in jointNode.nodesWithName("MATRIXPALETTEJOINTRENDERINSTANCE") {
                    let renderInstanceID = jointRenderInstanceNode.attributesDictionary["indices"]!.value as! String
                    let nodeID = renderInstanceID.stringByReplacingOccurrencesOfString("#", withString: "")
                    let materialReferenceID = jointRenderInstanceNode.attributesDictionary["shader"]!.value as! String
                    let materialName = materialReferenceID.stringByReplacingOccurrencesOfString("#", withString: "")
                    
                    let renderDataSourceInfo = RenderDataSourceInfo(jointRenderInstanceNode: jointRenderInstanceNode)
                    
                    // Get Material
                    if let existingMaterial = materials[materialName] {
                        modelMaterials.append(existingMaterial)
                    } else {
                        let newMaterial = SCNMaterial()
                        newMaterial.name = materialName
                     
                        
                        print("Material: " + materialName)
                        materials[materialName] = newMaterial
                        
                        
                        
                        modelMaterials.append(newMaterial)
                    }
                    
                    
                    if let renderDataSource = self.rootNode.nodeWithID(nodeID) {
                     //   print("Found node with ID \(renderInstanceID)")
                        let vertexDataBlock = renderDataSource.nodeWithName("RENDERSTREAM")!
                        
                        let renderIndexSource = renderDataSource.nodeWithName("RENDERINDEXSOURCE")!
                        let format = renderIndexSource.attributesDictionary["format"]?.value as? String
                        
                        let indexCount = renderIndexSource.attributesDictionary["count"]?.value as! Int
                        
                        let rawIndexSourceData = renderDataSource.nodeWithName("INDEXSOURCEDATA")?.data as! NSData
                        let indexSourceData = rawIndexSourceData// rawIndexSourceData.subdataWithRange(NSMakeRange(renderDataSourceInfo.indexOffset, sizeof(UInt16) * renderDataSourceInfo.indicesCountFromOffset));
                        let indexSourceDataPointer = UnsafeMutablePointer<UInt8>(indexSourceData.bytes);
                        
                        // Load into buffer
                        let dataBuffer = ByteBuffer(order: BigEndian(), data: indexSourceDataPointer, capacity: indexSourceData.length, freeOnDeinit: false)
                        let originalIndices: [UInt32]
                        if let formatType = format where formatType == "uint" {
                            originalIndices = Array(dataBuffer.getUInt32((rawIndexSourceData.length / sizeof(UInt32)))[renderDataSourceInfo.indexOffset...renderDataSourceInfo.indexOffset + renderDataSourceInfo.indicesCountFromOffset-1])
                        } else {
                            originalIndices = Array(dataBuffer.getUInt16((rawIndexSourceData.length / sizeof(UInt16)))[renderDataSourceInfo.indexOffset...renderDataSourceInfo.indexOffset + renderDataSourceInfo.indicesCountFromOffset-1]).map({ (indice) -> UInt32 in
                                return UInt32(indice)
                            })
                        }
                     
                        
                        // Normalise indices based on stream (vector) offset.
                        let indices = originalIndices.map({ (indice) -> UInt32 in
                            indice - UInt32(renderDataSourceInfo.streamOffset) + UInt32(modelVertices.count)
                        })

                        
                        
                        let indexData = NSData(bytes: indices, length: indices.count * sizeof(UInt32) )
                        // Create Geometry Element
                        let geometryElement = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Triangles, primitiveCount: indices.count
                            / 3, bytesPerIndex: sizeof(UInt32))
                        modelGeometryElements.append(geometryElement)
                        
                        
                        let dataBlockID = vertexDataBlock.attributesDictionary["dataBlock"]!.value as! String
                        let dataBlockIdentifier = String(dataBlockID.characters.dropFirst())
                        // self.rootNode.nodeWithID(String(dataBlockID.characters.dropFirst()))
                         if let dataBlock = self.renderInterfaceBound?.dataBlocks[dataBlockIdentifier] {
                           // print("Found data block \(dataBlock)")
 
                           let renderDataSource = GeometryDataSource(renderDataSource: renderDataSource, dataBlock: dataBlock, transform: transform, renderDataSourceInfo: renderDataSourceInfo)
                           // modelGeometrySources += renderDataSource.geometrySources
                            modelVertices += renderDataSource.vertices
                            modelNormals += renderDataSource.normals
              

                            
                          //  Create Multiple Geometry Elements
                         } else {
                            fatalError("DATABLOCK \(dataBlockIdentifier) not found")
                        }
                        
                        // Get ST Data
                        if let stRenderStream = renderDataSource.nodesWithName("RENDERSTREAM").get(3) {
                            let stDataBlockID = (stRenderStream.attributesDictionary["dataBlock"]!.value as! String).stringByReplacingOccurrencesOfString("#", withString: "")
                            let stDataBlock = self.rootNode.nodeWithID(stDataBlockID)!
                            let stCoordinates = GeometryDataSource.getSTData(stDataBlock, renderDataSourceInfo: renderDataSourceInfo)
                            
                            print(stCoordinates.count)
                            modelUVs += stCoordinates
                        }

                        
                    }
                    
                    
                    
                    
                }
                // Create Gemetry Sources
                let vertexSource = SCNGeometrySource(vertices: &modelVertices, count: modelVertices.count)
                let normalSource = SCNGeometrySource(normals: &modelNormals, count: modelNormals.count)
                
                // Create UVs source
                let uvSource = SCNGeometrySource(textureCoordinates: &modelUVs, count: modelUVs.count)
                
                // Save Model
                let geometryObject = SCNGeometry(sources: [vertexSource, normalSource,uvSource], elements: modelGeometryElements)
                geometryObject.name = modelName
                print(geometryObject.name!)
                
                // Assign Materials
                geometryObject.materials = modelMaterials
                
                models.append(Model(transform: transform, geometry: geometryObject))

               // print(jointNode)
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