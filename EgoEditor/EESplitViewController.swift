//
//  EESplitViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 10/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class EESplitViewController: NSSplitViewController, MainEditorDelegate {

    var rightViewController: AttributesInspectorViewController!
    var mainViewController: MainEditorViewController!
    
    func mainEditor(didSelectObject object: AnyObject) {
        if let attributeDataSource = object as? AttributesInspectorDataSource {
            rightViewController?.dataSource = attributeDataSource
            rightViewController?.reloadData()
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainViewController = childViewControllers.first! as! MainEditorViewController
        mainViewController.delegate = self
        rightViewController = childViewControllers.last! as! AttributesInspectorViewController
        
    }
    
    var document: AnyObject? {
        didSet {
            
        
            if let pssgDocument = document as? PSSGDocument {
                mainViewController.document = pssgDocument
            }
        }
    }
    
    
}
