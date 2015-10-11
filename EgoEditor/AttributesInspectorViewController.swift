//
//  AttributesInspectorViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 10/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

enum AttributeType {
    case Scalar
    case String
    case Boolean
}

class AttributeDescriptor {
    let title: String
    let type: AttributeType
    var value: AnyObject?
    init(title: String, type: AttributeType) {
        self.title = title
        self.type = type
    }
}

struct AttributeIndexPath {
    let section: Int
    let row: Int
}

protocol AttributesInspectorDataSource {
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController,numberOfRowsInSection section: Int) -> Int
    
    func numberOfSectionsInAttributesInspector(attributesInspector: AttributesInspectorViewController) -> Int
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController,
        cellForRowAtIndexPath indexPath: AttributeIndexPath) -> AttributeDescriptor
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController,
        titleForHeaderInSection section: Int) -> String
    
}
/*
class AttributeCell: NSObject, AttributeDescriptor {
    let title: String
    let type: AttributeType
    init(title: String, type: AttributeType) {
        self.title = title
        self.type = type
    }
}
*/
class AttributesGroup {
    let title: String
    var cells: [AttributeDescriptor] = []
    
    init(title: String, cells: [AttributeDescriptor]) {
        self.title = title
        self.cells = cells
    }
}

class SampleAttributesDataSource: AttributesInspectorDataSource {
    
    let attributes = [AttributeDescriptor(title: "Attribute String", type: AttributeType.String),
        AttributeDescriptor(title: "Attribute Bool", type: AttributeType.Boolean)]
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, cellForRowAtIndexPath indexPath: AttributeIndexPath) -> AttributeDescriptor {
        
 
        return attributes[indexPath.row]
    }
    
    func numberOfSectionsInAttributesInspector(attributesInspector: AttributesInspectorViewController) -> Int {
        return 1
    }
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, titleForHeaderInSection section: Int) -> String {
        return "Some Title"
    }
}

class AttributesInspectorViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet var outlineView: NSOutlineView!
    var dataSource: AttributesInspectorDataSource?
    var numberOfSections: Int = 0
    var sections: [AttributesGroup] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        outlineView.sizeLastColumnToFit()
        outlineView.floatsGroupRows = false

        outlineView.setDataSource(self)
        outlineView.setDelegate(self)
        dataSource = SampleAttributesDataSource()
        reloadData()
        
    
        
    }
    
    func reloadData() {
        // Get number of disclosureViewControllers required
        numberOfSections = dataSource?.numberOfSectionsInAttributesInspector(self) ?? 0
        sections = []
        var disclosureViews: [NSView] = []
        for(var i = 0; i < numberOfSections;i++) {
            
            // Create DisclosureViewController
            let disclosureViewController = DisclosureViewController(nibName: "DisclosureViewController", bundle: NSBundle.mainBundle())!
            let sectionTitle = dataSource!.attributesInspector(self, titleForHeaderInSection: i)
            disclosureViewController.title = sectionTitle
            
            
            let attributesViewController = AttributesViewController(nibName: "AttributesViewController", bundle: NSBundle.mainBundle())!
            disclosureViewController.disclosedView = attributesViewController.view
            
            
            // Get number of rows
            let numberOfRows = dataSource!.attributesInspector(self, numberOfRowsInSection: i)
            
            var attributeCells: [AttributeDescriptor] = []
            for(var r = 0; r < numberOfRows;r++) {
                let indexPath = AttributeIndexPath(section: i, row: r)
                
                let attributeInfo = dataSource!.attributesInspector(self, cellForRowAtIndexPath: indexPath)
                attributeCells.append(attributeInfo)
                
            }
            sections.append(AttributesGroup(title: sectionTitle, cells: attributeCells))
            


            // Add DisclosureView to AttributeInspector
            disclosureViews.append(disclosureViewController.view)
        //    disclosureViewControllers.append(disclosureViewController)
          //  attributesStackView.addView(disclosureViewController.view, inGravity: NSStackViewGravity.Bottom)
         
        }
        
        /*
        let stackView = NSStackView(views: disclosureViews)
        stackView.alignment = NSLayoutAttribute.CenterX;
        stackView.spacing = 0; // No spacing between the disclosure views
        attributesStackView = stackView
    */
        outlineView.reloadData()

    }
    
    
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return sections[index]

        } else {
            let section = item as! AttributesGroup
            return section.cells[index]
        }
        
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        
        return true
    }

    func outlineView(outlineView: NSOutlineView, shouldShowOutlineCellForItem item: AnyObject) -> Bool {
        return true
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return sections.count
        } else {
            let section = item as! AttributesGroup
            return section.cells.count
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if(outlineView.parentForItem(item) == nil) {
            return true
        }
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if let section = item as? AttributesGroup {
            let headerCell = outlineView.makeViewWithIdentifier("HeaderTextField", owner: self) as! NSTextField
            headerCell.stringValue = section.title
            
            return headerCell
        } else if let attributeInfo = item as? AttributeDescriptor {
            switch(attributeInfo.type) {
            case .String:
                
                let textFieldCell = outlineView.makeViewWithIdentifier("TextFieldAttributeCell", owner: self) as! TextFieldAttributeCell
                
                textFieldCell.titleTextLabel.stringValue = attributeInfo.title
                textFieldCell.attributeTextField.stringValue = attributeInfo.value as? String ?? ""
                
                return textFieldCell
                
            case .Boolean:
                
                let checkBoxCell = outlineView.makeViewWithIdentifier("CheckBoxAttributeCell", owner: self) as! CheckBoxAttributeCell
                checkBoxCell.titleTextLabel.stringValue = attributeInfo.title
                return checkBoxCell
                
            case .Scalar:
                let textFieldCell = outlineView.makeViewWithIdentifier("TextFieldAttributeCell", owner: self) as! TextFieldAttributeCell
                
                textFieldCell.titleTextLabel.stringValue = attributeInfo.title
                
                return textFieldCell
            }
    
        }
        
        fatalError("Unrecognised item")
        
    }
    

    
}
