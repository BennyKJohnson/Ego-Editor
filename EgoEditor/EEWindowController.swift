//
//  EEWindowController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 1/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa




class EEWindowController: NSWindowController, NSToolbarDelegate {
    @IBOutlet weak var windowToolbar: NSToolbar!
    
    @IBOutlet weak var statusBar: NSButton!
    override func awakeFromNib() {
        
        
       // self.windowToolbar.delegate = self
    }
    
    

    
    // MARK: Overrides
    override func windowDidLoad() {
        super.windowDidLoad()
        

        self.window?.titleVisibility = NSWindowTitleVisibility.Hidden; // or .Hidden in Swift
        
        //if let projectDoc = document as? EgoProjectDocument {
          //  projectDoc.newDocument = false
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let newDocumentWindow = storyboard.instantiateControllerWithIdentifier("NewDocumentWindowController") as! NSWindowController
            // windowController.window.p
            window?.beginSheet(newDocumentWindow.window!, completionHandler: { (response) -> Void in
                
            })

            
        //}
    }
    
  
    
    func toolbarSelectableItemIdentifiers(toolbar: NSToolbar) -> [String] {
        
        return []
    }
    
    override var document: AnyObject? {
        didSet {
            let listViewController = window!.contentViewController as! EESplitViewController
            if let pssgDocument = document as? PSSGDocument {
                listViewController.document = pssgDocument
                statusBar.title = pssgDocument.displayName
            }
        }
    }

}