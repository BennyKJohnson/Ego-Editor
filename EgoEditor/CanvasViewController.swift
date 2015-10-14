//
//  CanvasViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 13/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit
class CanvasViewController: NSSplitViewController, SceneEditorViewControllerDelegate {

    var sceneGraphViewController: SceneGraphViewController!
    var sceneEditorViewController: SceneEditorViewController!
    
    weak var scene: SCNScene? {
        didSet {
            sceneGraphViewController.rootNode = scene?.rootNode
        }
    }
    
    weak var document: PSSGDocument? {
        didSet {
            //  if document == nil { return }
            //sceneEditorViewController.document = document
            
            sceneEditorViewController.document = document
        }
    }
    
    override func awakeFromNib() {

        sceneGraphViewController = self.childViewControllers.first as! SceneGraphViewController
        
        sceneEditorViewController = self.childViewControllers.last as! SceneEditorViewController
        sceneEditorViewController.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func sceneEditorViewController(didSelectObject object: AnyObject) -> Bool {
        return true
    }
    
    func sceneEditorViewController(didLoadScene scene:SCNScene) {
        print("Loaded Scene")
        self.scene = scene
    }
    
}
