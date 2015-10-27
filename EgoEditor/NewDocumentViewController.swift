//
//  NewDocumentViewController.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 27/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa

class NewDocumentViewController: NSViewController {

    @IBOutlet var collectionView: NSCollectionView!
    
    @IBOutlet weak var arrayController: NSArrayController!
    
    var documentTypes =  NSMutableArray()
    
    override func awakeFromNib() {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.itemPrototype = self.storyboard?.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
        
        let trackDocument = DocumentObject(title: "Track", image: NSImage(named: "Scene")!)
        arrayController.addObject(trackDocument)
        
        // Do view setup here.
    }
    
}

class DocumentCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet var iconView: NSImageView!
    
    @IBOutlet var headerLabel: NSTextField!
    
}

class DocumentObject: NSObject {
    
    init(title: String, image: NSImage) {
        self.title = title
        self.image = image
    }
    
    var title: String
    
    var image: NSImage
    
}