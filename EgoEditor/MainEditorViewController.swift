//
//  MainEditorViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 3/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class MainEditorViewController: NSSplitViewController {
    
    
    weak var document: PSSGDocument? {
        didSet {
          //  if document == nil { return }
            
            
            let sceneEditorViewController = self.childViewControllers.first as! SceneEditorViewController
            sceneEditorViewController.document = document
            let pssgDataViewController = self.childViewControllers.last as! PSSGDataViewController
            pssgDataViewController.document = document
            
            
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
