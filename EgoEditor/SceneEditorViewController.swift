//
//  SceneEditorViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit

struct Model {
    let transform: SCNMatrix4
    let geometry: SCNGeometry
}

struct TextureComponents {
    var modelName: String?
    let title: String
    var type: String? = nil
    
    init?(textureFilename: String) {
        let components = textureFilename.componentsSeparatedByString("_")
        if components.count == 1 {
            title = components.first!
        } else if components.count > 1 {
            modelName = components.first!
            title = components[1]
            if components.count == 3 {
                type = components.last!
            }
        } else {
            return nil
        }
    }
}

protocol SceneEditorViewControllerDelegate {
    func sceneEditorViewController(didSelectObject object: AnyObject) -> Bool
}

class SceneEditorViewController: NSViewController, SceneEditorViewDelegate {
    
    @IBOutlet weak var sceneView: SceneEditorView!
    var pssgFile: PSSGFile?
    var sharedMaterials: [String:SCNMaterial] = [:]
    var delegate: SceneEditorViewControllerDelegate?
    
    var selectableNodes:[String: AnyObject] = [:] // Not sure how you are meant to get the data model for a given model, more research needs to be done. Dictionary will work for now
    
    
    weak var document: PSSGDocument? {
        didSet {
            if document == nil { return }
            print("Got PSSG Document")
            pssgFile = document?.pssgFile
            if pssgFile != nil {
                loadScene()
            }
        }
    }
    
    func appendMaterials(materials: [SCNMaterial]) {
        for material in materials {
            sharedMaterials[material.name!] = material
        }
    }
    
    func loadScene() {
        if let pssgFile = pssgFile where pssgFile.isGeometrySourceProvider() {
            let pssgGeometries = pssgFile.geometryForObject()
            let scene = sceneView.scene!
            //    SCNMaterialProperty
            for model in pssgGeometries ?? [] {
                
                let geometryNode = SCNNode(geometry: model.geometry)
                geometryNode.name = model.geometry.name
                
                // Add materials for reference later
                appendMaterials(geometryNode.geometry?.materials ?? [])
                
                //    geometryNode.
                //   geometryNode.
                print(model.transform)
                // geometryNode.transform += model.transform
                geometryNode.transform = model.transform
                scene.rootNode.addChildNode(geometryNode)
                
            }
            document?.scene = scene
        }
        
        // Write Scene
        //    saveScene()
        
        // scene.rootNode.transform =
        
    }
    
    func saveScene() {
        // Show save panel
        let saveDialog = NSSavePanel()
        saveDialog.beginWithCompletionHandler({ (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.sceneView.scene?.writeToURL(saveDialog.URL!, options: nil, delegate: nil, progressHandler: nil)
            }
        })
        
    }
    
    func createCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    func sceneView(sceneView: SceneEditorView, didSelectNode node: SCNNode, geometryIndex: Int, event: NSEvent) {
        if let nodeName = node.name , selectedObject = selectableNodes[nodeName]  {
            print("Selected object \(node.name!)")
            self.delegate?.sceneEditorViewController(didSelectObject: selectedObject)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.editorDelegate = self
        
        sceneView.backgroundColor = NSColor.lightGrayColor()
        sceneView.showsStatistics = true
        
        
    }
    
    
    func dragOperationForURL(url: NSURL) -> NSDragOperation {
        if let pathExtension = url.pathExtension  {
            if( pathExtension == "pssg" || pathExtension == "xml") {
                return NSDragOperation.Copy

            }
        }
        return NSDragOperation.None
    }
    
    func loadImageAssetsWithURLs(imageAssetURLs: [NSURL]) {
        for ddsURL in imageAssetURLs {
            // Get filename, confirm that it belongs to material
            let textureFilename = ddsURL.lastPathComponent!.componentsSeparatedByString(".").first!
            print(textureFilename)
            
            // Map to material
            if let textureComponents = TextureComponents(textureFilename: textureFilename), materials = textureToMaterial[textureComponents.title] where textureComponents.type == nil {
                
                // Load DDS Image
                if let dds = DDS(URL: ddsURL) {
                    let imageRef = dds.CreateImage
                    
                    // Finally load into materials
                    for material in materials {
                        sharedMaterials[material]?.diffuse.contents = imageRef().takeUnretainedValue()
                        //sharedMaterials[material]
                    }
                }
                
            }
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
            // Remove existing folder
            do {
                try NSFileManager.defaultManager().removeItemAtURL(imageAssetDirectoryURL)
            } catch {}
            
            // Create directory
            try NSFileManager.defaultManager().createDirectoryAtURL(imageAssetDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Export Textures into temporary directory for loading
            draggedPSSGFile.writeImageAssetsToURL(imageAssetDirectoryURL)
            
            // Load DDS Files
            let ddsURLs = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(imageAssetDirectoryURL, includingPropertiesForKeys: nil, options: [])
            loadImageAssetsWithURLs(ddsURLs)
            return true
            
        } catch {
            print("Error occured loading file")
            return false
        }
        
    }
    
    func addRenderable(object: SceneRenderable) {
        let objectNode = object.sceneNodeForObject()
        self.sceneView.scene?.rootNode.addChildNode(objectNode)
    }
    
    func loadXML(url: NSURL) -> Bool {
        let data = NSData(contentsOfURL: url)!
        let xmlFile = XMLFile(data: data)
        
        let cameraXML = xmlFile.xmlDocument.XMLDataWithOptions(NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement)
        
        let vehicleCameraParser = VehicleCameraXMLParser()
        let xmlParser = NSXMLParser(data: cameraXML)
        xmlParser.delegate = vehicleCameraParser
        xmlParser.parse()
        print(vehicleCameraParser.cameraViews.count)
        
        for cameraView in vehicleCameraParser.cameraViews {
            self.selectableNodes[cameraView.name] = cameraView
            addRenderable(cameraView)
        }
        
        self.delegate?.sceneEditorViewController(didSelectObject: vehicleCameraParser.cameraViews[0])
        
        
        
        return true
    }
    
    func performDragOperationForURL(url: NSURL) -> Bool {
        print("Dragged file \(url.absoluteString)")
        if let pathExtension = url.pathExtension  {
            switch(pathExtension) {
                case "pssg":
                    return loadPSSG(url)
                case "xml":
                    return loadXML(url)
            default:
                return false
            }
        }
        
        return false
    }
    
    
}