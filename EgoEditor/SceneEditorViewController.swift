//
//  SceneEditorViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit

enum TextureType {
    case DiffuseAlphaMap
    case NormalMap
    case SurfaceMap
    case OcclusionMap
    case UnknownType
    
    static func textureTypeFromSampler(sampler: String) -> TextureType
    {
        switch(sampler) {
        case "TDiffuseAlphaMap":
            return TextureType.DiffuseAlphaMap
        case "TNormalMap":
            return TextureType.NormalMap
        case "TOcclusionMap":
            return TextureType.OcclusionMap
        default:
            return TextureType.UnknownType
        }
    }
    static func fromFileComponent(component: String?) -> TextureType {
        if let component = component {
            switch(component) {
            case "nm":
                return TextureType.NormalMap
            case "specocc", "spec":
                return TextureType.OcclusionMap
            default:
                return TextureType.UnknownType
            }
        }
        // Return standard diffuse
        return TextureType.DiffuseAlphaMap
    }
}

struct Model {
    let transform: SCNMatrix4
    let geometry: SCNGeometry
}

struct TextureComponents {
    var modelName: String?
    let title: String
    var type: TextureType
    
    init?(textureFilename: String) {
        let components = textureFilename.componentsSeparatedByString("_")
        type = TextureType.DiffuseAlphaMap
        if components.count == 1 {
            title = components.first!
            
        } else if components.count > 1 {
            modelName = components.first!
            title = components[1]
            if components.count == 3 {
                type = TextureType.fromFileComponent(components.last!)
            }
        } else {
            return nil
        }
    }
    
    
}

protocol SceneEditorViewControllerDelegate {
    func sceneEditorViewController(didSelectObject object: AnyObject) -> Bool
    func sceneEditorViewController(didLoadScene scene:SCNScene)
}

class SceneEditorViewController: NSViewController, SceneEditorViewDelegate, SCNProgramDelegate {
    
    @IBOutlet weak var sceneView: SceneEditorView!
    var pssgFile: PSSGFile?
    var sharedMaterials: [String:SCNMaterial] = [:]
    var delegate: SceneEditorViewControllerDelegate?
    var translateManipulator: TranslateControl!
    
    var selectableNodes:[String: AnyObject] = [:] // Not sure how you are meant to get the data model for a given model, more research needs to be done. Dictionary will work for now
    
    
    weak var document: PSSGDocument? {
        didSet {
            if document == nil { return }
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
    
    func getInstanceData(filename: String) -> InstanceData? {
        // Attemp to load instance data
        if let ornamentsFileURL = pssgFile?.pssgDirectory?.URLByAppendingPathComponent("route_0/" + filename) where pssgFile?.url!.lastPathComponent == "objectss.pssg" {
            if let instanceData = NSData(contentsOfURL: ornamentsFileURL) {
                let instanceData = InstanceData(data: instanceData)
                return instanceData
            }
            
        }
        return nil
        
    }
    
    func loadInstancesIntoScene(scene:SCNScene, instanceData: InstanceData,geometries: [Model]) {
        for instance in instanceData.instanceList.instances {
            // Find InstanceRef with ID
            guard let instanceRef = instanceData.instanceList.instanceReferenceWithID(instance.referenceID) else {
                break
            }
            
            // Find Geometry for InstanceRef based on filename
            guard let geometryModel = geometries.find({$0.geometry.name == instanceRef.filename}) else {
                break
            }
            
            // Create SCNode for the instance
            let instanceNode = SCNNode(geometry: geometryModel.geometry)
            instanceNode.transform = instance.transform
            instanceNode.name = instanceRef.filename
            // Add it to the scene
            scene.rootNode.addChildNode(instanceNode)
            
        }
    }
    
    func loadScene() {
        if let pssgFile = pssgFile where pssgFile.isGeometrySourceProvider() {
            let scene = sceneView.scene!
            
            
            
            
            
            let pssgGeometries = pssgFile.geometryForObject()
    
            if let instanceData = getInstanceData("ornaments.bin")  {
                loadInstancesIntoScene(scene, instanceData: instanceData, geometries: pssgGeometries)
                
                // Load Track
                do {
                    let trackURL = pssgFile.pssgDirectory!.URLByAppendingPathComponent("tracksplit.pssg")
                    let fileHandle = try NSFileHandle(forReadingFromURL: trackURL)
                    let schema = NSBundle.mainBundle().URLForResource("pssg", withExtension: ".xsd")!
                    let trackPSSG = try PSSGFile(file: fileHandle, schemaURL: schema)
                    trackPSSG.url = trackURL
                    let trackGeometries = trackPSSG.geometryForObject()
                    for model in trackGeometries ?? [] {
                        
                        let geometryNode = SCNNode(geometry: model.geometry)
                        geometryNode.name = model.geometry.name
                        
                        // Add materials for reference later
                        appendMaterials(geometryNode.geometry?.materials ?? [])
                        
                        geometryNode.transform = model.transform
                        scene.rootNode.addChildNode(geometryNode)
                        
                    }
                    
                } catch {
                    
                }
                
                
                // Load trees 
                do {
                    let treesURL = pssgFile.pssgDirectory!.URLByAppendingPathComponent("trees.pssg")
                    let fileHandle = try NSFileHandle(forReadingFromURL: treesURL)
                    let schema = NSBundle.mainBundle().URLForResource("pssg", withExtension: ".xsd")!
                    let treesPSSG = try PSSGFile(file: fileHandle, schemaURL: schema)
                    treesPSSG.url = treesURL
                    let treeGeometries = treesPSSG.geometryForObject()
                    if let treeInstances = getInstanceData("trees.bin") {
                        loadInstancesIntoScene(scene, instanceData: treeInstances, geometries: treeGeometries)
                    }
                    
                } catch {
                    
                }
                
                // Hacky Solution to load Sky
                do {
                    let skyURL = pssgFile.pssgDirectory!.URLByAppendingPathComponent("route_0/sky_day.pssg")
                    let fileHandle = try NSFileHandle(forReadingFromURL: skyURL)
                    let schema = NSBundle.mainBundle().URLForResource("pssg", withExtension: ".xsd")!
                    let skyPSSG = try PSSGFile(file: fileHandle, schemaURL: schema)
                    skyPSSG.url = skyURL
                    
                    // Get Sky Material Instance
                    TextureManager.sharedManager.loadTexturesFromPSSG(skyPSSG)
                    
                    let shaderInput = skyPSSG.rootNode.nodeWithName("SHADERINPUT")
                    if let skyTextureReference = shaderInput?.attributesDictionary["texture"]?.formattedValue as? String {
                        let name = skyTextureReference.stringByReplacingOccurrencesOfString("#", withString: "")
                        if let skyTexture = TextureManager.sharedManager.textures[name] {
                            scene.background.contents = skyTexture.ddsFile?.CreateImage().takeUnretainedValue()
                        }
                    }
                 
                    
                } catch {
                    
                }
                
                

                
                
                
                
                
                
            } else {
                //    SCNMaterialProperty
                for model in pssgGeometries ?? [] {
                    
                    let geometryNode = SCNNode(geometry: model.geometry)
                    geometryNode.name = model.geometry.name
                    
                    // Add materials for reference later
                    appendMaterials(geometryNode.geometry?.materials ?? [])
                    
                    geometryNode.transform = model.transform
                    scene.rootNode.addChildNode(geometryNode)
                    
                }
            }
            
            
        
            
            
            
       
   
            document?.scene = scene
            self.delegate?.sceneEditorViewController(didLoadScene: scene)
            
            translateManipulator = TranslateControl()
            translateManipulator.render()
            scene.rootNode.addChildNode(translateManipulator)
            
            // Configure Camera
            scene.rootNode.camera?.zNear = 0
            
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
        print("Selected Node \(node.name)")
        // Move translate Manipulator
        
        if let nodeName = node.name {
            if nodeName.rangeOfString(TranslateControl.identifier) == nil {
                translateManipulator.position = node.position
                
                print("Selected object \(node.name!)")
//self.delegate?.sceneEditorViewController(didSelectObject: selectedObject)
            } else {
                print("Selected handle")
            }

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
            if( pathExtension == "pssg" || pathExtension == "xml" || pathExtension == "bin" ||  pathExtension == "grs") {
                return NSDragOperation.Copy

            }
        }
        return NSDragOperation.None
    }
    
    func program(program: SCNProgram, handleError error: NSError) {
        print(error)
    }
    
    func program(program: SCNProgram, bindValueForSymbol symbol: String, atLocation location: UInt32, programID: UInt32, renderer: SCNRenderer) -> Bool {
        return true
    }
    
    
    func loadImageAssetsWithURLs(imageAssetURLs: [NSURL]) {
        for ddsURL in imageAssetURLs {
            
            // Get filename, confirm that it belongs to material
            
            let textureFilename = ddsURL.lastPathComponent!
            
            print(textureFilename)
        
            // Get texture definition
            
            let materialDefinition = MaterialDefinition(data: NSData(contentsOfURL: NSBundle.mainBundle().URLForResource("render_materials", withExtension: "xml")!)!)

            // Map to material
            
            if let materials = materialDefinition.materialsForTextureFilename(textureFilename) {
                
                // Add to each material
                
                for material in materials {
                    
                    // Load DDS Image
                    if let dds = DDS(URL: ddsURL) {
                        let imageRef = dds.CreateImage
                        
                        // Finally load into materials

                            let textureType = TextureType.textureTypeFromSampler(material.sampler)
                            
                            switch(textureType) {
                            case .DiffuseAlphaMap:
                                print("Added \(textureFilename) as diffuse map to material \(material)")
                                if let material = sharedMaterials[material.materialName] {
                                    material.diffuse.contents = imageRef().takeUnretainedValue()

                                }
                                /*
                            case .NormalMap:
                                print("Added \(textureFilename) as normal map to material \(material)")
                                sharedMaterials[material.materialName]?.normal.contents = imageRef().takeUnretainedValue()
*/
                            default:
                                break
                            }
                        
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
        // Add wireframe program
 
        
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
    
    func loadBin(url: NSURL) -> Bool {
        let data = NSData(contentsOfURL: url)!
        let instanceData = InstanceData(data: data)
        
        return true
        
        
    }
    
    func loadGrassMap(url:NSURL) -> Bool {
        let data = NSData(contentsOfURL: url)!
        let grassMap = GrassMap(data: data)
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
                case "bin":
                    return loadBin(url)
                case "grs":
                    return loadGrassMap(url)
                
            default:
                return false
            }
        }
        
        return false
    }
    
    
}