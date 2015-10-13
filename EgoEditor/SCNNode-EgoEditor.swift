//
//  SCNNode-EgoEditor.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 13/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Cocoa
import SceneKit
extension SCNNode {
    func setSceneEditorReferenceName(name: String) {
        self.name = "_" + name
    }
    
    var shouldBeRemovedFromSceneGraphUponSave:Bool {
        return false
    }
}