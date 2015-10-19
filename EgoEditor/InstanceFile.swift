//
//  InstanceFile.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 19/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit


struct InstanceReference {
    let referenceID: Int
    let filename: String
    let prebakedShadows: Int
    let sponsor: Int?
    let maxInstances: Int
    
    let boundsMin: SCNVector3
    let boundsMax: SCNVector3
}

struct Instance {
    
    let transform: SCNMatrix4
    
    let instanceTag: Int
    
    let instanceID: Int
    
    let referenceID: Int
    
}

struct PathAdmin {
    let id:Int
    let name: String
    let instanceTag: Int
    let loop: Int
    let canTriggerEveryLap: Int
    let pingPong: Int
    let hideOnLoad:Int
    let heroAdmin: Int
    let existProbability: Float
    
}

struct InstanceList {
    
    let referenceCount: Int
    
    let instanceCount: Int
    
    let totalLandmarks: Int
    
    let boundsMin: SCNVector3
    
    let boundsMax: SCNVector3
    
    var instances: [Instance] = []
    
    var instanceReference: [InstanceReference] = []
    
    func instanceReferenceWithID(id: Int) -> InstanceReference? {
        for instanceRef in instanceReference {
            if instanceRef.referenceID == id {
                return instanceRef
            }
        }
        
        return nil
    }
    
}
enum InstanceDataType {
    case Ornaments
    case Trees
}



struct InstanceData {
    
    var instanceList: InstanceList!
    var type: InstanceDataType!
    
    init(data: NSData) {
        let dataPointer = UnsafeMutablePointer<UInt8>(data.bytes); // Get pointer to file bytes
        let stream = ByteBuffer(order: LittleEndian(), data: dataPointer, capacity: data.length, freeOnDeinit: false)
        
        // Read Instance List
        stream.getInt32()
        let boundingBoxOffset = stream.getInt32()
        
      
        
        let numberOfSections = stream.getInt32()
        
        let minBounds: SCNVector3
        let maxBounds: SCNVector3
        
        if boundingBoxOffset == 12 {
            // Read bounding box
            // Read bounds
            minBounds = stream.readVector()
            maxBounds = stream.readVector()
            type = .Trees
        } else {
            let someOffset = stream.getInt32()
            let someNum1 = stream.getInt32()
            let totalObjectCount = stream.getInt32()
            let someNum2 = stream.getInt32()
            
            // Read bounds
            minBounds = stream.readVector()
            maxBounds = stream.readVector()
            type = .Ornaments
        }
        
        
        let referenceCount = stream.readInt32()!
        let instanceNum = stream.readInt32()!
        let totalLandmarks = stream.readInt32()!
        
        let instanceReferenceOffset = stream.readInt32()!
        var currentPosition = stream.offsetInFile
        stream.seekToFileOffset(UInt64(instanceReferenceOffset))

        // Get Instance References
        let instanceReferences = readInstnaceReferences(stream, count: referenceCount, dataType: type)
        
        // Set offset by to original position
        stream.seekToFileOffset(currentPosition)
        
        let totalCount: Int = stream.readInt32()!
        let instancesOffset = stream.readInt32()!
        let instanceCount = stream.readInt32()!
        
        // Get Instances
        currentPosition = stream.offsetInFile
        stream.seekToFileOffset(UInt64(instancesOffset))
        let instances = readInstace(stream, count: instanceCount, dataType: type)
        stream.seekToFileOffset(UInt64(currentPosition))

        /*
        let dependentReferenceNum = stream.readInt32()!
        let dependentInstanceNum = stream.readInt32()!
        let dependentOffset = stream.readInt32()!
        
        stream.readInt32()!
        let otherOffset = stream.readInt32()!
        stream.readInt32()!
        
        let pathAnimCount = stream.readInt32()!
        */
        
        instanceList = InstanceList(referenceCount: referenceCount, instanceCount: instanceCount
        , totalLandmarks: totalLandmarks, boundsMin: minBounds, boundsMax: maxBounds, instances: instances, instanceReference: instanceReferences)
        
        
    }
    
    func readInstace(stream: ByteBuffer, count:Int,dataType: InstanceDataType) -> [Instance] {
        var instances: [Instance] = []
        
        for(var i = 0;i < count; i++) {
            let referenceID = stream.readInt32()!
            let instanceID = stream.readInt32()!
            
            let transform1 = stream.readVector()
            let transform2 = stream.readVector()
            let transform3 = stream.readVector()
            let transform4 = stream.readVector()
        
            let objectID:Int
            if(dataType == .Ornaments) {
                let padding = stream.getInt32(5)
                objectID = stream.readInt32()!
                let someOtherNum = stream.getInt32()
                let pad = stream.readInt32()!
            } else {
                stream.readInt32()
                let shadowFactor = stream.readFloat()
                stream.getInt32(2)
                objectID = stream.readInt32()!
            }
            
       
            
            var transform = SCNMatrix4()
            transform.m11 = transform1.x
            transform.m12 = transform1.y
            transform.m13 = transform1.z
            transform.m14 = 0
            
            transform.m21 = transform2.x
            transform.m22 = transform2.y
            transform.m23 = transform2.z
            transform.m24 = 0
            
            transform.m31 = transform3.x
            transform.m32 = transform3.y
            transform.m33 = transform3.z
            transform.m34 = 0
            
            transform.m41 = transform4.x
            transform.m42 = transform4.y
            transform.m43 = transform4.z
            transform.m44 = 1
            
            
            let instance = Instance(transform: transform, instanceTag: objectID, instanceID: instanceID, referenceID: referenceID)
            instances.append(instance)
            
        }
        
        return instances
    }
    
    func readInstnaceReferences(stream: FileHandle, count: Int, dataType: InstanceDataType) -> [InstanceReference] {
        var instanceReferences: [InstanceReference] = []
        
        for(var i = 0; i < count; i++) {
            let nameOffset = stream.readInt32()!
            let position = stream.offsetInFile
            stream.seekToFileOffset(UInt64(nameOffset))
            // Read String
            let name = stream.readCString()!
            stream.seekToFileOffset((position))
            
            let referenceID = stream.readInt32()!
            let boundsMin = stream.readVector()
            let boundsMax = stream.readVector()
            
            let prebakedShadows:Int// = stream.readInt32()!
            let maxInstances:Int
            let sponsor: Int?

            if dataType == .Ornaments {
                 sponsor = stream.readInt32()!
                 prebakedShadows = stream.readInt32()!

                maxInstances = stream.readInt32()!
                stream.readInt32() // Terminator
                
            } else {
                sponsor = nil
                prebakedShadows = stream.readInt32()!
                maxInstances = stream.readInt32()!
                
            }
      

            
            let instanceReference = InstanceReference(referenceID: referenceID, filename: name, prebakedShadows: prebakedShadows, sponsor: sponsor, maxInstances: maxInstances, boundsMin: boundsMin, boundsMax: boundsMax)
            instanceReferences.append(instanceReference)
            
        }
        
        return instanceReferences
    }

}
