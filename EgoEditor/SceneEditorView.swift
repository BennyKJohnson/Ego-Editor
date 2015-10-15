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
    
    func sceneView(sceneView: SceneEditorView, didSelectNode node: SCNNode, geometryIndex: Int, event: NSEvent)

}

protocol SceneEventHandler {
    func mouseDragged(event: NSEvent) -> Bool // Call super
    func mouseUp(event: NSEvent) -> Bool
    func mouseDown(event: NSEvent) -> Bool
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
    
    override func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        
        // Convert the mouse location in screen coordinates to local coordinates, then perform a hit test with the local coordinates
        let mouseLocation = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let hits = self.hitTest(mouseLocation, options: nil)
        
        // If there was a hit, select the nearest object; otherwise unselect.
        if let initalHit = hits.first {
           // self.editorDelegate?.sceneView(self, didSelectNode: initalHit.node, geometryIndex: initalHit.geometryIndex, event: theEvent)
        } else {
            // Unselect current selected node
            
        }
        
        
        // Reset Manipulator color
        
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        // Response to drag
        
    }
 
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        // Convert the mouse location in screen coordinates to local coordinates, then perform a hit test with the local coordinates
        let mouseLocation = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let hits = self.hitTest(mouseLocation, options: nil)
        
        // If there was a hit, select the nearest object; otherwise unselect.
        if let initalHit = hits.first {
            self.editorDelegate?.sceneView(self, didSelectNode: initalHit.node, geometryIndex: initalHit.geometryIndex, event: theEvent)
        } else {
            // Unselect current selected node
            
        }
        
    }
}
