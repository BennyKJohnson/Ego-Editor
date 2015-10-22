//
//  TextureManager.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 18/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

class TextureManager {
    var textures: [String: DDS] = [:]
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
                
                textures[textureFilename] = dds
                
            }
        }
    }
    
    func loadTexturesFromPSSG(pssgFile: PSSGFile) -> Bool {
        
        if let filename = pssgFile.url?.lastPathComponent {
            loadedFiles.append(filename)
        }
        
        
       
        // Export Textures into temporary directory for loading
        pssgFile.writeImageAssetsToURL(imageAssetDirectoryURL)
        
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