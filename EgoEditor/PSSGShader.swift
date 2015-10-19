//
//  PSSGShader.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 17/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

struct PSSGShaderGroup {
    
    let id: String
    
    var shaderInputDefinations: [PSSGShaderInputDefinition] = []
    
    init?(shaderGroupNode: PSSGNode){
        guard let id = shaderGroupNode.attributesDictionary["id"]?.formattedValue as? String else {
            return nil
        }
        
        self.id = id
        
        let shaderInputDefinitionNodes = shaderGroupNode.nodesWithName("SHADERINPUTDEFINITION")
        
        for shaderInputDefinitionNode in shaderInputDefinitionNodes {
            if let shaderInputDefinition = PSSGShaderInputDefinition(shaderInputDefinition: shaderInputDefinitionNode) {
                shaderInputDefinations.append(shaderInputDefinition)
            }
        }
    }
}

struct PSSGShaderInputDefinition {
    
    let name: String
    
    let type: String
    
    let format: String?
    
    init?(shaderInputDefinition: PSSGNode) {
        guard let name = shaderInputDefinition.attributesDictionary["name"]?.formattedValue as? String,
            type = shaderInputDefinition.attributesDictionary["type"]?.formattedValue as? String else {
                return nil
        }
        
        self.name = name
        self.type = type
        self.format = shaderInputDefinition.attributesDictionary["format"]?.formattedValue as? String
        
    }

}

struct PSSGShaderInstance {
    
    let shaderGroup: PSSGReferenceID
    
    let id: String
    
    var shaderInputs: [PSSGShaderInput] = []
    
    init?(shaderInstanceNode: PSSGNode) {
        guard let id = shaderInstanceNode.attributesDictionary["id"]?.formattedValue as? String,
            shaderGroup = shaderInstanceNode.attributesDictionary["shaderGroup"]?.formattedValue as? String else {
                return nil
        }
        
        self.id = id
        self.shaderGroup = PSSGReferenceID(referenceID: shaderGroup)
        
        let shaderInputNodes = shaderInstanceNode.nodesWithName("SHADERINPUT")
        for shaderInputNode in shaderInputNodes {
            if let shaderInput = PSSGShaderInput(shaderInputNode: shaderInputNode) {
                shaderInputs.append(shaderInput)
            }
        }
    }
}

struct PSSGReferenceID {
    
    let identifier: String
    
    let externalReference: String?
    
    let externalReferenceAlt: String?
    
    init(referenceID: String) {
        let idComponents = referenceID.componentsSeparatedByString("#")
        if idComponents.count == 2 {
            
            let externalComponents = idComponents[0].componentsSeparatedByString("|")
            
            externalReference = externalComponents[0]
            externalReferenceAlt = externalComponents.objectAtIndex(1)
            
            identifier = idComponents[1]
        } else {
            externalReference = nil
            externalReferenceAlt = nil
            identifier = idComponents[0]
            
        }
    }
}



struct PSSGShaderInput {
    
    let parameterID: Int
    
    let type: String
    
    let format: String?
    
    let textureID: PSSGReferenceID?
    
    init?(shaderInputNode: PSSGNode) {
        guard let parameterID = shaderInputNode.attributesDictionary["parameterID"]?.formattedValue as? Int,
            type = shaderInputNode.attributesDictionary["type"]?.formattedValue as? String else {
                return nil
        }
        
        self.parameterID = parameterID
        
        self.type = type
        
        self.format = shaderInputNode.attributesDictionary["format"]?.formattedValue as? String
        
        if let textureString = shaderInputNode.attributesDictionary["texture"]?.formattedValue as? String {
            textureID = PSSGReferenceID(referenceID: textureString)
        } else {
            textureID = nil
        }
    }
    
}

