//
//  SceneGraphViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 13/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit

// Provides the data about the scene to be displayed in the scenegraphview
protocol SceneGraphDataSource {
    
}

class StructureNode {
    var name: String
    var imageName: String
    
    init(name: String, imageName: String) {
        self.name = name
        self.imageName = imageName
    }
}

class EntryNode {
    var name: String
    let entityType: EntityType
    init(name: String, type: EntityType) {
        self.name = name
        self.entityType = type
    }
}

enum EntityType {
    case Animation
    case Camera
    case Geometry
    case Light
    case Material
    case Textures
}

class SceneGraphViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    
    @IBOutlet var outlineView: NSOutlineView!
    
    let sections = [StructureNode(name: "Entities", imageName: "entities"),StructureNode(name: "Scene Graph", imageName: "sceneGraph")]
    let entryNodes = [EntryNode(name: "Animations", type: EntityType.Animation), EntryNode(name: "Cameras", type: EntityType.Camera), EntryNode(name: "Geometries", type: EntityType.Geometry), EntryNode(name: "Lights", type: EntityType.Light), EntryNode(name: "Materials", type: EntityType.Material), EntryNode(name: "Textures", type: EntityType.Textures)]
    var rootNode: SCNNode! {
        didSet {
            self.updateSceneGraph()
        }
    }
    
    func geometriesForScene() -> [String] {
        var geometrySources: [String] = []
        let flattenedScene = rootNode.flattenedClone()
        
        for node in flattenedScene.childNodes {
            if let geometry = node.geometry {
               geometrySources.append(geometry.name ?? "<untitled geometry>")
            }
        }
        
        return geometrySources
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        outlineView.sizeLastColumnToFit()
        outlineView.floatsGroupRows = false
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let _ = item as? StructureNode {
            return true
        } else if let _ = item as? EntryNode {
            return true
        }
        let node = item as! SCNNode
        return node.childNodes.count > 0
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return sections[index]
        } else if let section = item as? StructureNode {
            
            if section.name == sections.last!.name {
                return rootNode.childNodes[index]
            } else {
               return entryNodes[index]
            }
            
        } else if let node = item as? EntryNode {
            switch(node.entityType) {
            case .Geometry:
                return geometriesForScene()[index]
            default:
                fatalError("Not supported")
            }
            
            
        } else {
            let node = item as! SCNNode
            return node.childNodes[index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return false
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        //print("selected \(sender.selectedRowIndexes)")
        if let selectedNode = outlineView.itemAtRow(outlineView.selectedRow) as? SCNNode {
            selectedNode.geometry?.firstMaterial?.diffuse.borderColor = NSColor.orangeColor()
            /*
            for currentMaterial in selectedNode.geometry?.materials ?? [] {
                let selectionMaterial = selectedNode.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                selectionMaterial?.emission.contents = NSColor.blueColor()
                selectedNode.geometry?.firstMaterial = selectionMaterial
            }
    */
            /*
            let selectionMaterial = selectedNode.geometry?.firstMaterial?.copy() as? SCNMaterial
            selectionMaterial?.emission.contents = NSColor.blueColor()
            // Move logic to owner, should not be here
           selectedNode.geometry?.materials.append(selectionMaterial!)
            */
        }
        
    }
    
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let node = item as? SCNNode {
            return node.childNodes.count
        } else if let section = item as? StructureNode {
            if section.name == sections.first!.name {
                return entryNodes.count
            } else {
                return rootNode?.childNodes.count ?? 0
            }
        } else if let entityNode = item as? EntryNode {
            switch(entityNode.entityType) {
            case .Geometry:
                return 0
            default:
                return 0
            }

        }
        else {
            return sections.count
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if let structureNode = item as? StructureNode {
            // Dequeue Cell
            let headerCell = outlineView.makeViewWithIdentifier("SectionCell", owner: self) as! NSTableCellView
            headerCell.imageView!.image = NSImage(named: structureNode.imageName)
            headerCell.textField!.stringValue = structureNode.name
            
            return headerCell
            
        } else if let entryNode = item as? EntryNode {
            let headerCell = outlineView.makeViewWithIdentifier("SectionCell", owner: self) as! NSTableCellView
            headerCell.imageView!.image = NSImage(named: "NSFolder")
            headerCell.textField!.stringValue = entryNode.name
            
            return headerCell
        } else {
            let node = item as! SCNNode
            let textField = outlineView.makeViewWithIdentifier("Cell", owner: self) as! NSTableCellView
            textField.textField!.stringValue = node.name ?? "<untitled object>"
            return textField
        }
    }
    
  
    
    func updateSceneGraph() {
        print("Updating Scene Graph")
        outlineView.reloadData()
    }
    
}
