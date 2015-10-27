//
//  EditorDocumentController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 27/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class EditorDocumentController: NSDocumentController {
    
    
    /* Create a new untitled document, present its user interface if displayDocument is YES, and return the document if successful. If not successful, return nil after setting *outError to an NSError that encapsulates the reason why a new untitled document could not be created. The default implementation of this method invokes [self defaultType] to determine the type of new document to create, invokes -makeUntitledDocumentOfType:error: to create it, then invokes -addDocument: to record its opening. If displayDocument is YES, it then sends the new document -makeWindowControllers and -showWindows messages.
    
    The default implementation of this method uses the file coordination mechanism that was added to the Foundation framework in Mac OS 10.7. It passes the document to +[NSFileCoordinator addFilePresenter:] right after -addDocument: is invoked. (The balancing invocation of +[NSFileCoordinator removeFilePresenter:] is in -[NSDocument close]).
    
    For backward binary compatibility with Mac OS 10.3 and earlier, the default implementation of this method instead invokes [self openUntitledDocumentOfType:[self defaultType] display:displayDocument] if -openUntitledDocumentOfType:display: is overridden.
    */
    
    /*
    override func openUntitledDocumentAndDisplay(displayDocument: Bool) throws -> NSDocument {
        print("New Document")
        
        // Show panel
   //     let mainWindow = NSApplication.sharedApplication().mainWindow!
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        let newDocumentWindow = storyboard.instantiateControllerWithIdentifier("NewDocumentWindowController") as! NSWindowController
        
        NSApp.runModalForWindow(newDocumentWindow.window!)
        
     //   mainWindow.beginSheet(newDocumentWindow as! NSWindow, completionHandler: { (response) -> Void in
            
     //  })
        
        
        
        // Get selection
        
        // Create Doc type
        let defaultType = self.defaultType!
        let document = try makeUntitledDocumentOfType(defaultType)
        
        if displayDocument {
            // Show document
            document.makeWindowControllers()
            document.showWindows()
        }
        
        return document
        
    }*/
}
