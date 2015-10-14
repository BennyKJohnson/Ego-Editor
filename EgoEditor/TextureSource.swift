//
//  TextureSource.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 6/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit



protocol MaterialPropertyDataSource {
    func textures() -> [SCNMaterialProperty]
    func shouldSaveTexturesToTemporaryDirectory() -> Bool
}

extension PSSGFile: MaterialPropertyDataSource {
 
    func textures() -> [SCNMaterialProperty] {
        let textureNodes = rootNode.nodesWithName("TEXTURE")
        for textureNode in textureNodes {
            let wrapS = textureNode.attributesDictionary["wrapS"]?.value as! Int
            let wrapT = textureNode.attributesDictionary["wrapT"]?.value as! Int
            
            let materialProperty = SCNMaterialProperty()
            materialProperty.wrapS = SCNWrapMode(rawValue: wrapS) ?? SCNWrapMode.Clamp
            materialProperty.wrapT = SCNWrapMode(rawValue: wrapT) ?? SCNWrapMode.Clamp
            
        }
        return []
    }
    
    func shouldSaveTexturesToTemporaryDirectory() -> Bool {
        // Save the located texture files to temp directiory
       // let textureNodes = rootNode.nodesWithName("TEXTURE")
        
        fatalError("Not implemented")
        //return true
    }

    
}