//
//  EESplitViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 10/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class RightPropertiesSplitViewController: NSSplitViewController, MainEditorDelegate  {
    var topViewController: AttributesInspectorViewController!
    var bottomViewController: ObjectLibraryViewController!
    
    func mainEditor(didSelectObject object: AnyObject) {
        if let attributeDataSource = object as? AttributesInspectorDataSource {
            topViewController?.dataSource = attributeDataSource
            topViewController?.reloadData()
            
        }
    }
    
}


class EESplitViewController: NSSplitViewController {

    var rightViewController: RightPropertiesSplitViewController!
    var mainViewController: MainEditorViewController!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainViewController = childViewControllers.first! as! MainEditorViewController
        mainViewController.delegate = rightViewController
        
        rightViewController = childViewControllers.last! as! RightPropertiesSplitViewController
        
    }
    
    var document: AnyObject? {
        didSet {
            
        
            if let pssgDocument = document as? PSSGDocument {
                mainViewController.document = pssgDocument
            }
        }
    }
    
    
}
