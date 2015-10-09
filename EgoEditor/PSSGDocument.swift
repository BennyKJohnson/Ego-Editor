//
//  Document.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 1/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit

enum PSSGSupportedExportTypes: String {
    case DAE = "org.khronos.collada.digital-asset-exchange"
    case XML = "public.xml"
    case XSD = "public.xsd"
}

class PSSGDocument: NSDocument {
    
    var pssgFile: PSSGFile!
    var scene: SCNScene?
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! EEWindowController
        self.addWindowController(windowController)
    }
    
    override func writeToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: NSURL?) throws {
        
        print(typeName)
        if let fileType = PSSGSupportedExportTypes(rawValue: typeName) {
            switch(fileType) {
            case .DAE:
                if let scene = scene {
                    scene.writeToURL(url, options: nil, delegate: nil, progressHandler: nil)
                    return
                }
                
            case .XML:
                if let xmlDocument = pssgFile.generateXMLDocument() {
                    xmlDocument.XMLDataWithOptions(NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement).writeToURL(url, atomically: false)
                    return
                }
            case .XSD:
                if let xmlDocument = pssgFile.schema.generateXMLDocument() {
                    xmlDocument.XMLDataWithOptions(NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement).writeToURL(url, atomically: false)
                    return
                }
            }
        }
        
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)

  
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

    /*
    override func dataOfType(typeName: String) throws -> NSData {
        print(typeName)
        
        
        if let xmlDocument = pssgFile.generateXMLDocument() {
            return xmlDocument.XMLDataWithOptions(NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement)
        } else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        
        
        
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

*/
    
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        // Get Binary Reader
        
        do {
            let fileHandle = try NSFileHandle(forReadingFromURL: url)
            let schema = NSBundle.mainBundle().URLForResource("pssg", withExtension: ".xsd")!
            
            pssgFile = try PSSGFile(file: fileHandle,schemaURL: schema)
            
            
        } catch {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)

        }
        
        
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        
        
        
        
        
    }


}

