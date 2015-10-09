//
//  PSSGFile+ImageAssetSource.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 8/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

protocol ImageAssetSource {
    func containsImageAssets() -> Bool
    func writeImageAssetsToURL(url: NSURL) -> Bool
}

extension PSSGFile: ImageAssetSource {
    func containsImageAssets() -> Bool {
        return rootNode.nodeWithName("TEXTURE") != nil
    }
    
    func writeImageAssetsToURL(url: NSURL) -> Bool {
        let textureNodes = rootNode.nodesWithName("TEXTURE")
        writeTextureNodesToURL(url, textureNodes: textureNodes)
        
        return true
    }
    
    func writeTextureNodeToURL(url: NSURL, textureNode: PSSGNode) {
        // Create DDS File
        print("Writing \(url.absoluteURL)")
        
        if let ddsFile = DDSFile(node: textureNode) {
            // Write DDS File
            let ddsFileData = ddsFile.dataForFile()
            ddsFileData.writeToURL(url, atomically: false)
        }
    }
    
    func writeTextureNodesToURL(url: NSURL, textureNodes: [PSSGNode]) {
        // Loop Through texture nodes
        for textureNode in textureNodes {
            // Get filepath
            let filename = textureNode.attributesDictionary["id"]?.value as! String
            let filepath = url.URLByAppendingPathComponent("\(filename).dds")
            writeTextureNodeToURL(filepath, textureNode: textureNode)
        }
    }
    
}
