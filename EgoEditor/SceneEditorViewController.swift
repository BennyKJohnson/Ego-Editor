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


class SceneEditorViewController: NSViewController {
    
    @IBOutlet weak var sceneView: SceneEditorView!
    var pssgFile: PSSGFile?

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
    
    func loadScene() {
        if let pssgFile = pssgFile where pssgFile.isGeometrySourceProvider() {
            let pssgGeometries = pssgFile.geometryForObject()
            let scene = sceneView.scene!
        //    SCNMaterialProperty
            for model in pssgGeometries ?? [] {
                
                let geometryNode = SCNNode(geometry: model.geometry)
                geometryNode.name = model.geometry.name
                
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.backgroundColor = NSColor.lightGrayColor()
        sceneView.showsStatistics = true
       
      
    }
    
    
}