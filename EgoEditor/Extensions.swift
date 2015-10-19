//
//  Extensions..swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 5/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import Cocoa
import SceneKit

extension Array {
    
    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
}


extension String {
    
    func stringFromCamelCase() -> String {
        var string = self
        string = string.stringByReplacingOccurrencesOfString("([a-z])([A-Z])", withString: "$1 $2", options: NSStringCompareOptions.RegularExpressionSearch, range: Range<String.Index>(start: string.startIndex, end: string.endIndex))
        string.replaceRange(startIndex...startIndex, with: String(self[startIndex]).capitalizedString)
        return string
    }

        var floatValue: Float {
            return (self as NSString).floatValue
        }
    
}

extension Array {
    func objectAtIndex(index:Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

extension CollectionType {
    func find(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element? {
        return try indexOf(predicate).map({self[$0]})
    }
}

extension SCNMaterial {
    class func wireframeShader() -> SCNProgram {
        let wireframeShader = SCNProgram()
        
        // Get URL to wireframe shaders
        let wireFrameFSHURL = NSBundle.mainBundle().URLForResource("C3D-wireframe", withExtension: "fsh")!
        let wireFrameVSHURL = NSBundle.mainBundle().URLForResource("C3D-wireframe", withExtension: "vsh")!
        
        let wireFrameFSH = try! NSString(contentsOfURL: wireFrameFSHURL, encoding: NSUTF8StringEncoding)
        let wireFrameVSH = try! NSString(contentsOfURL: wireFrameVSHURL, encoding: NSUTF8StringEncoding)
        
        // Load shader code into program
        wireframeShader.fragmentShader = wireFrameFSH as String
        wireframeShader.vertexShader = wireFrameVSH as String
        
        // Set variables vertex shader
        wireframeShader.setSemantic(SCNGeometrySourceSemanticColor, forSymbol: "u_color", options: nil)
        wireframeShader.setSemantic(SCNGeometrySourceSemanticVertex, forSymbol: "v_vertexCenter", options: nil)
        
        // Set variables fragment shader
        wireframeShader.setSemantic(SCNProjectionTransform, forSymbol: "u_modelViewProjectionTransform", options: nil)
         wireframeShader.setSemantic(SCNGeometrySourceSemanticVertex, forSymbol: "a_position", options: nil)
        
        return wireframeShader
    }
}
