//
//  ViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 1/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class PSSGDataViewController: NSViewController, NSMenuDelegate {
    
    var pssgFile: PSSGFile?
    var selectedPSSGNode: PSSGNode?
    
    @IBOutlet weak var dataOutlineView: NSOutlineView!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        outlineView.setDataSource(self)
        outlineView.setDelegate(self)
        dataOutlineView.setDataSource(self)
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    weak var document: PSSGDocument? {
        didSet {
            if document == nil { return }
            print("Got PSSG Document")
            pssgFile = document?.pssgFile
           // Referesh views
            outlineView.reloadData()
            dataOutlineView.reloadData()
                
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        //print("selected \(sender.selectedRowIndexes)")
        if let selectedNode = outlineView.itemAtRow(outlineView.selectedRow) as? PSSGNode {
            print("Selected \(selectedNode.name)")
            selectedPSSGNode = selectedNode
            dataOutlineView.reloadData()
        } else {
            selectedPSSGNode = nil
        }

    }

    @IBAction func selectionDidChange(sender: NSOutlineView) {
        //print("selected \(sender.selectedRowIndexes)")
        
       
    }
    
    @IBAction func nodesReferencingNode(sender: AnyObject) {
        print("Go to node")
        let clickedRow = dataOutlineView.clickedRow
        if let selectedAttribute = dataOutlineView.itemAtRow(clickedRow) as? PSSGAttribute {
            let referenceID = selectedAttribute.value as! String
            
            if let nodeForID = pssgFile?.nodesReferencingID(referenceID).first {
                // Get index path
                for ancestor in nodeForID.ancestorNodes {
                    outlineView.expandItem(ancestor)
                }
                outlineView.selectItem(nodeForID)
                outlineView.scrollRowToVisible(outlineView.rowForItem(nodeForID))
                //   scrollRowToVisible
                // outlineView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: true)
            }
        }
    }
    
    
    @IBAction func exportTextures(sender: AnyObject) {
        
        let clickedRow = outlineView.clickedRow
        if let selectedNode = outlineView.itemAtRow(clickedRow) as? PSSGNode  {
            let textureNodes = selectedNode.nodesWithName("TEXTURE")
            if textureNodes.count > 0 {
                // Show Directory Panel
                let directoryPanel = NSOpenPanel()
                directoryPanel.canChooseFiles = false
                directoryPanel.canChooseDirectories = true
                directoryPanel.canCreateDirectories = true
                directoryPanel.prompt = "Export"
                directoryPanel.beginWithCompletionHandler({ (result) -> Void in
                    if result == NSFileHandlingPanelOKButton {
                        self.document?.writeTextureNodesToURL(directoryPanel.URL!, textureNodes: textureNodes)
                    }
                })
            }
        }
    }
    
    @IBAction func exportDataForSelectedNode(sender: AnyObject) {
        let clickedRow = outlineView.clickedRow
        if let selectedNode = outlineView.itemAtRow(clickedRow) as? PSSGNode where selectedNode.isDataNode {
            
            // Show save panel
            let saveDialog = NSSavePanel()
            saveDialog.beginWithCompletionHandler({ (result) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    if let data = selectedNode.data as? NSData {
                        data.writeToURL(saveDialog.URL!,
                             atomically: false)
                    }
                }
            })
            
        } else {
            let errorMessage = NSAlert()
            errorMessage.messageText = "No data"
            errorMessage.runModal()
        }

    }
    
    
    
    @IBAction func goToNodeWithSelectedID(sender: NSMenuItem) {
        print("Go to node")
         let clickedRow = dataOutlineView.clickedRow
        if let selectedAttribute = dataOutlineView.itemAtRow(clickedRow) as? PSSGAttribute {
            let referenceID = selectedAttribute.formattedValue as! String
            let nodeID = String(referenceID.characters.dropFirst())
            if let nodeForID = pssgFile?.rootNode.nodeWithID(nodeID) {
                // Get index path
                for ancestor in nodeForID.ancestorNodes {
                    outlineView.expandItem(ancestor)
                }
                outlineView.selectItem(nodeForID)
                outlineView.scrollRowToVisible(outlineView.rowForItem(nodeForID))
             //   scrollRowToVisible
               // outlineView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: true)
            }
        }
    }
    
    
    
    
    // Populate context menu for data outline view
    func menuNeedsUpdate(menu: NSMenu) {
        let clickedRow = dataOutlineView.clickedRow
        
        if let gotoItem = menu.itemAtIndex(0) {

            if let selectedAttribute = dataOutlineView.itemAtRow(clickedRow) as? PSSGAttribute {
                gotoItem.enabled = selectedAttribute.isReferenceID

                
                print("Selected \(selectedAttribute.key)")
                if  selectedAttribute.isReferenceID {
                    gotoItem.title = "Go to \(selectedAttribute.value! as! String)"

                }
            } else {
                
            }
        }
  
        
    }
    
    
}

extension PSSGDataViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    
    
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let selectedNode = selectedPSSGNode where outlineView == dataOutlineView {
            // Needs to be generalised some how to deal with these special cases
            if selectedNode.name == "DATABLOCKDATA" {
                return 1
            }
            
            return selectedNode.attributes.count
            
        } else if pssgFile != nil {
            if let node = item as? PSSGNode {
                return node.childNodes.count
            } else {
                return 1
                
            }
        } else {
            return 0
        }
        
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let _ = selectedPSSGNode where outlineView == dataOutlineView {
            return false
        }
        else if let node = item as? PSSGNode {
            return !node.isLeaf
        }
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let selectedNode = selectedPSSGNode where outlineView == dataOutlineView {
            if index < selectedNode.attributes.count {
                return selectedNode.attributes[index]

            } else {
                return selectedNode

            }
            
        } else if let node = item as? PSSGNode {
            return node.childNodes[index]
            
        } else {
            return pssgFile!.rootNode
        }
        
    }
    
    func outlineView(outlineView: NSOutlineView,
        objectValueForTableColumn tableColumn: NSTableColumn?,
        byItem item: AnyObject?) -> AnyObject? {
            if let currentAttribute = item as? PSSGAttribute where outlineView == dataOutlineView {
                if tableColumn!.identifier == "key" {
                    return currentAttribute.key
                } else {
                    if let data = currentAttribute.formattedValue {
                        // Special case for showing parameter name, would like to make this logic generic, define rules in XML Schema, though it seems it would be complex using combined IDs
                        if currentAttribute.key == "parameterID" {
                            if let parameterID = currentAttribute.formattedValue as? Int,shaderGroupReference = currentAttribute.node?.parentNode?.attributesDictionary["shaderGroup"]?.formattedValue as? String  {
                                let shaderGroupID = String(shaderGroupReference.characters.dropFirst())
                                if let shaderInputDefinition = pssgFile!.rootNode.subNodeForNodeWithIdentifier(shaderGroupID, parameterID: parameterID) {
                                    let shaderName = shaderInputDefinition.attributesDictionary["name"]!.formattedValue as! String
                                    return "\(data) (\(shaderName))"
                                }
                            }
                        }
                        

                        return "\(data)"
                    } else {
                        return "nil (no data)"
                    }
                }
                
            } else if let currentDataNode = item as? PSSGNode where outlineView == dataOutlineView {
                
                return "\(currentDataNode.data)"
            } else {
                let node = item as! PSSGNode
                // print(node.name)
                return node.name
            }
            
    }
    
    
    
}

extension NSOutlineView {
    func expandParentsOfItem(item: AnyObject) {
        var item: AnyObject? = item
        while(item != nil) {
            let parent = self.parentForItem(item)
            if !self.isExpandable(parent) {
                break
            }
            if !self.isItemExpanded(parent) {
                self.expandItem(parent)
            }
            item = parent
        }
    }
    
    func selectItem(item: AnyObject) {
        var rowIndex = self.rowForItem(item)
        if rowIndex < 0 {
            self.expandParentsOfItem(item)
            
            // Lets try again after expanding parent items
            rowIndex = self.rowForItem(item)
            if(rowIndex < 0) {
                Swift.print("Couldn't find index for item")
            }
        }
        self.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: false)
    }
}

