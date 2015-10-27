//
//  ObjectLibraryViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 27/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

struct ObjectInformation {
    
    let name: String
    let description: String?
    let image: NSImage?
    
}

protocol ObjectLibraryDataSource {
    func numberOfObjects() -> Int
    func objectInformationForRow(row: Int) -> ObjectInformation
}


class ObjectLibraryViewController: NSViewController, NSTableViewDataSource {

    var objectDataSource: ObjectLibraryDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 0//objectDataSource.numberOfObjects()
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let objectInfo = objectDataSource.objectInformationForRow(row)
        
        // Create Cell
        let objectCell = tableView.makeViewWithIdentifier("ObjectTableViewCell", owner: self) as! NSTableCellView
        
        // Prepare Cell
        objectCell.textField?.stringValue = objectInfo.name
        
        return objectCell
        
        
        
        
        
        
    }
    
    
    
}
