//
//  MainEditorViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 3/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa


enum MainEditorType: Int {
    case basicEditor
    case assistEditor
}

class MainEditorViewController: NSSplitViewController, NSToolbarDelegate {
    

    
    @IBOutlet var basicEditor: NSSplitViewItem!
    @IBOutlet var assistEditor: NSSplitViewItem!
    
    var sceneEditorViewController: SceneEditorViewController!
    var pssgDataViewController: PSSGDataViewController!
    
    override func awakeFromNib() {
         basicEditor = splitViewItems.first!
         assistEditor = splitViewItems.last!
        sceneEditorViewController = self.childViewControllers.first as! SceneEditorViewController
        pssgDataViewController = self.childViewControllers.last as! PSSGDataViewController
    }
    
    weak var document: PSSGDocument? {
        didSet {
          //  if document == nil { return }
            
          
            sceneEditorViewController.document = document
            pssgDataViewController.document = document
            
            
            
        }
    }
    
    @IBAction func editorTypeChanged(sender: NSSegmentedControl) {
        print("Segment Changed")
        let editorType = MainEditorType(rawValue: sender.selectedSegment)!
        switch(editorType) {
        case .basicEditor:
            if self.splitViewItems.contains(assistEditor) {
                self.removeSplitViewItem(assistEditor)

            }
        case .assistEditor:
                self.addSplitViewItem(assistEditor)

            
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
