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

protocol MainEditorDelegate {
    func mainEditor(didSelectObject object: AnyObject)
}

class MainEditorViewController: NSSplitViewController, NSToolbarDelegate, SceneEditorViewControllerDelegate {
    

    
    @IBOutlet var basicEditor: NSSplitViewItem!
    @IBOutlet var assistEditor: NSSplitViewItem!
    
    var sceneEditorViewController: SceneEditorViewController!
    var pssgDataViewController: PSSGDataViewController!
    var delegate: MainEditorDelegate?
    
    override func awakeFromNib() {
         basicEditor = splitViewItems.first!
         assistEditor = splitViewItems.last!
        sceneEditorViewController = self.childViewControllers.first as! SceneEditorViewController
        sceneEditorViewController.delegate = self

        pssgDataViewController = self.childViewControllers.last as! PSSGDataViewController
    }
    
    weak var document: PSSGDocument? {
        didSet {
          //  if document == nil { return }
            
          
            sceneEditorViewController.document = document
            pssgDataViewController.document = document
            
            
            
        }
    }
    
    func sceneEditorViewController(didSelectObject object: AnyObject) -> Bool {
        delegate?.mainEditor(didSelectObject: object)
        return true
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
