//
//  TextureManager.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 18/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation


struct PSSGTexture {
    var ddsFile: DDS?
    
    let wrapS: Int
    
    let wrapT: Int

    let wrapR: Int // Not Used
    
    init(node: PSSGNode) {
        // Parse node
        wrapS = node.attributesDictionary["wrapS"]?.formattedValue as! Int
        wrapT = node.attributesDictionary["wrapT"]?.formattedValue as! Int
        wrapR = node.attributesDictionary["wrapR"]?.formattedValue as! Int
       
    }
    
    
}

class TextureManager {
    var textures: [String: PSSGTexture] = [:]
    var loadedFiles: [String] = []
    var imageAssetDirectoryURL: NSURL

    
    static let sharedManager = TextureManager()

    
    private init() {
        
        // Get URL to temporary directory
        let temporaryDirectory = NSURL.fileURLWithPath(NSTemporaryDirectory())
        
        // Create Folder for image assets
        imageAssetDirectoryURL = temporaryDirectory.URLByAppendingPathComponent("EgoEditor")
        
        // Remove existing folder
        do {
            try NSFileManager.defaultManager().removeItemAtURL(imageAssetDirectoryURL)
        } catch {}
        
        // Create directory
        try! NSFileManager.defaultManager().createDirectoryAtURL(imageAssetDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        
        
    }
    
    func loadTexturesFromURL(url: NSURL) {
        if let pathExtension = url.pathExtension {
            switch(pathExtension) {
            case "pssg":
                loadPSSG(url)
            default:
                break
            }

        }
    }
    
    func loadImageAssetsWithURLs(imageAssetURLs: [NSURL]) {
        for ddsURL in imageAssetURLs {
            
            // Get filename, confirm that it belongs to material
            let textureFilename = ddsURL.URLByDeletingPathExtension!.lastPathComponent!
            
            print(textureFilename)
            
            if let dds = DDS(URL: ddsURL) {
                
                textures[textureFilename]?.ddsFile = dds
                
            }
        }
    }
    
    func loadTexturesFromPSSG(pssgFile: PSSGFile) -> Bool {
        
        if let filename = pssgFile.url?.lastPathComponent {
            loadedFiles.append(filename)
        }
        
        // Get Texture Nodes 
        let textureNodes = pssgFile.rootNode.nodesWithName("TEXTURE")
        for textureNode in textureNodes {
            // Create DDS File
            // Get filepath
            let textureName = textureNode.attributesDictionary["id"]?.value as! String
            let filename = textureName + ".dds"
            let filepath = imageAssetDirectoryURL.URLByAppendingPathComponent(filename)

            // Create PSSG Texture
            let pssgTexture = PSSGTexture(node: textureNode)
            textures[textureName] = pssgTexture
            
            if let ddsFile = DDSFile(node: textureNode) {
                // Write DDS File
                let ddsFileData = ddsFile.dataForFile()
                ddsFileData.writeToURL(filepath, atomically: false)
            }
        }
       
        // Export Textures into temporary directory for loading
       // pssgFile.writeImageAssetsToURL(imageAssetDirectoryURL)
        
        do {
            
            // Load DDS Files
            let ddsURLs = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(imageAssetDirectoryURL, includingPropertiesForKeys: nil, options: [])
            loadImageAssetsWithURLs(ddsURLs)
            return true
            
        } catch {
            return false
        }
    }
    
    func loadPSSG(url: NSURL) -> Bool {
        // Load PSSGFile
        do {
            let fileHandle = try NSFileHandle(forReadingFromURL: url)
            let schema = NSBundle.mainBundle().URLForResource("pssg", withExtension: ".xsd")!
            
            let draggedPSSGFile = try PSSGFile(file: fileHandle,schemaURL: schema)
            
            // Contains Image Assets, load textures onto current model
            guard  draggedPSSGFile.containsImageAssets() else {
                return false
            }
            
            // Get URL to temporary directory
            let temporaryDirectory = NSURL.fileURLWithPath(NSTemporaryDirectory())
            
            // Create Folder for image assets
            let imageAssetDirectoryURL = temporaryDirectory.URLByAppendingPathComponent("EgoEditor")
          
            
            
            return loadTexturesFromPSSG(draggedPSSGFile)
            
        } catch {
            print("Error occured loading file \(error)")
            return false
        }
        
    }
    
}