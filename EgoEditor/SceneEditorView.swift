//
//  SceneEditorView.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import SceneKit

protocol SceneEditorViewDelegate {
    func performDragOperationForURL(url: NSURL) -> Bool
    func dragOperationForURL(url: NSURL) -> NSDragOperation
}

class SceneEditorView: SCNView {
    
    var editorDelegate: SceneEditorViewDelegate?
    
    override func awakeFromNib() {
    
        registerForDraggedTypes([NSURLPboardType])

    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard()
        
        // Delegate responsibility to view's owner
        if let fileURL = NSURL(fromPasteboard: pasteBoard), editorDelegate = editorDelegate {
            return editorDelegate.performDragOperationForURL(fileURL)
        }

        return false
    }
    
    func dragOperationForPasteBoard(pasteBoard: NSPasteboard) -> NSDragOperation {
        if let fileURL = NSURL(fromPasteboard: pasteBoard) {
            
            return self.editorDelegate?.dragOperationForURL(fileURL) ?? NSDragOperation.None
        }
        return NSDragOperation.None
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return dragOperationForPasteBoard(sender.draggingPasteboard())
    }
    
    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return dragOperationForPasteBoard(sender.draggingPasteboard())
    }
 
}
