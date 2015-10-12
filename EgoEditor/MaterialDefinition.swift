//
//  MaterialDefinition.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 12/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation


struct TextureReplace {
    let materialName: String
    let sampler: String
    let texture: String
}

class MaterialDefinitionParser: NSObject, NSXMLParserDelegate {
    let parser: NSXMLParser
    var replaceTextures: [TextureReplace] = []
    
    
    init(data: NSData) {
        parser = NSXMLParser(data: data)
        super.init()
        
        parser.delegate = self
        parser.parse();
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "replace" {
            
            let texture = attributeDict["texture"]!
            let sampler = attributeDict["sampler"]!
            let material = attributeDict["material"]!
            let textureReplace = TextureReplace(materialName: material, sampler: sampler, texture: texture)
            
            replaceTextures.append(textureReplace)
        }
    }

    
}



class MaterialDefinition {
    
    var textures:[String: [TextureReplace]] = [:]
    
    init(data: NSData) {
        let materialDefinitionParser = MaterialDefinitionParser(data: data)
        
        for textureReplace in materialDefinitionParser.replaceTextures {
            addTextureReplace(textureReplace)
        }
    }
    
    func addTextureReplace(textureReplace: TextureReplace) {
        if let _ = textures[textureReplace.texture] {
            textures[textureReplace.texture]!.append(textureReplace)
        } else {
            textures[textureReplace.texture] = [textureReplace]
        }
    }
    
    func materialsForTextureFilename(filename: String ) -> [TextureReplace]? {
        let textureNames = textures.keys
        
        // Perform a fuzzy search of texture name
        for textureName in textureNames {
            if filename.rangeOfString(textureName) != nil {
               return textures[textureName]
            }
        }
        return nil
    }
    
    func containsDefinitionForTexture(textureName: String) -> Bool {
        return textures[textureName] != nil
    }
    

}