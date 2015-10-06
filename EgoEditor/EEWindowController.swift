//
//  EEWindowController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 1/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class EEWindowController: NSWindowController, NSToolbarDelegate {
    @IBOutlet weak var toolbar: NSToolbar!
    
    // MARK: Overrides
    override func windowDidLoad() {
        super.windowDidLoad()
        toolbar.delegate = self
        self.window?.titleVisibility = NSWindowTitleVisibility.Hidden; // or .Hidden in Swift
    }
    
    
    
    override var document: AnyObject? {
        didSet {
            
            let listViewController = window!.contentViewController as! MainEditorViewController
            listViewController.document = document as? PSSGDocument
        }
    }
    
    func toolbarSelectableItemIdentifiers(toolbar: NSToolbar) -> [String] {
        return ["ShowHideLeft","ShowHideRight"]
    }
}