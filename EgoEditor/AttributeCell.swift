//
//  AttributeCell.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 10/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

protocol AttributeCell {
    
    var titleTextLabel: NSTextField! { get }
    
    var detailLabel: NSTextField? { get }
    
    
}

extension AttributeCell {
    
    var detailLabel: NSTextField? {
        return nil
    }
    
}

class TextFieldAttributeCell: NSTableCellView, AttributeCell {
    @IBOutlet var titleTextLabel: NSTextField!
    @IBOutlet var attributeTextField: NSTextField!
    
    
}

class CheckBoxAttributeCell: NSTableCellView, AttributeCell {
       @IBOutlet var titleTextLabel: NSTextField!
    
    @IBOutlet var checkBox: NSButton!
}