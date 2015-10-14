//
//  TranslateControl.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 12/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

class TranslateControl: SCNNode {
    
    let xAxisColor: NSColor = NSColor.redColor()
    let yAxisColor: NSColor = NSColor.greenColor()
    let zAxisColor: NSColor = NSColor.blueColor()
    
    let axisHeight: CGFloat = 1
    let axisThickness: CGFloat = 0.01
    
    let coneHeight: CGFloat = 1.0 / 5.0
    let coneDiameter: CGFloat = 1.0 / 12.0

    
    func render() {
        
        // Create X Axis
        let height = CGFloat(axisHeight * axisScale())
        let yAxisLine = SCNCylinder(radius: CGFloat(axisThickness * axisScale()), height: height)
        yAxisLine.firstMaterial?.diffuse.contents = yAxisColor
        let yAxis = SCNNode(geometry: yAxisLine)
        yAxis.position.y = height / 2
        
        
        let xAxisLine = SCNCylinder(radius: CGFloat(axisThickness * axisScale()), height: height)
        xAxisLine.firstMaterial?.diffuse.contents = xAxisColor
        

        let xAxis = SCNNode(geometry: xAxisLine)
        xAxis.position.x = height / 2
        xAxis.addChildNode(xHead())
        
        xAxis.rotation = SCNVector4(0,0,1,M_PI / 2)
        
        let zAxisLine = SCNCylinder(radius: CGFloat(axisThickness * axisScale()), height: height)
        let zAxis = SCNNode(geometry: zAxisLine)
        zAxis.position.z = height / 2
        zAxis.addChildNode(zHead())
        zAxisLine.firstMaterial?.diffuse.contents = zAxisColor
        zAxis.rotation = SCNVector4(1,0,0,M_PI / 2)
        
        self.addChildNode(yAxis)
        self.addChildNode(xAxis)
        
        self.addChildNode(zAxis)
    }
    
    func axisScale() -> CGFloat
    {
        return 1.0
    }
    
    func zHead() -> SCNNode {
    //    let translation = SCNVector3(0, (axisScale() * (1 - coneHeight)), 0)
        let headGeometry = SCNCone(topRadius: 0, bottomRadius: axisScale() * coneDiameter, height: coneHeight * axisScale())
        headGeometry.firstMaterial?.diffuse.contents = zAxisColor

        let xHead = SCNNode(geometry: headGeometry)
        
        xHead.position.y = axisHeight / 2 + (coneHeight / 2)
        return xHead
    }
    
    func yHead() -> SCNNode {
        let translation = SCNVector3((axisScale() * (1 - coneHeight)), 0, 0)
        let headGeometry = SCNCone(topRadius: 0, bottomRadius: axisScale() * coneDiameter, height: coneHeight * axisScale())
        headGeometry.firstMaterial?.diffuse.contents = yAxisColor
        let xHead = SCNNode(geometry: headGeometry)
        xHead.position = translation
        
        return xHead
    }
    
    func xHead() -> SCNNode {
       // let translation = SCNVector3((axisScale() * (1 - coneHeight)), 0, 0)
        let headGeometry = SCNCone(topRadius: 0, bottomRadius: axisScale() * coneDiameter, height: coneHeight * axisScale())
        let xHead = SCNNode(geometry: headGeometry)
        headGeometry.firstMaterial?.diffuse.contents = xAxisColor

       // xHead.position = translation
        return xHead
    }
    
}