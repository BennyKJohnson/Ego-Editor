//
//  CameraView.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 10/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import SceneKit

enum ValueType: String {
    case Bool = "bool"
    case Scalar = "scalar"
    case Vector3 = "vector3"
    case String = "string"
}

struct Parameter {
    let name: String
    let value: AnyObject
    let valueType: ValueType
    
    var attributeType: AttributeType? {
        switch(valueType) {
        case .String:
            return AttributeType.String
        case .Bool:
            return AttributeType.Boolean
        case .Scalar:
            return AttributeType.Scalar
        default:
            return nil
        }
    }
}

// Objects that can be represented in scene view
protocol SceneRenderable {
    func sceneNodeForObject() -> SCNNode
    
}




class CameraView: AttributesInspectorDataSource, SceneRenderable {
    var parameters: [Parameter] = []
    var type: String
    var hidden: Bool = false
    var position: SCNVector3?
    var name: String
    var yaw: Float?
    var pitch: Float?
    var roll: Float?
    
    lazy var attributeParameters: [Parameter] = {
        var attributeParameters: [Parameter] = []
        for parameter in self.parameters {
            if let attributeType = parameter.attributeType {
                attributeParameters.append(parameter)
            }
        }
        return attributeParameters
    }()
    
    init(name: String,type: String, parameters: [Parameter]) {
        self.type = type
        self.parameters = parameters
        self.name = name
    }
    
    func numberOfSectionsInAttributesInspector(attributesInspector: AttributesInspectorViewController) -> Int {
        return 1
    }
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, numberOfRowsInSection section: Int) -> Int {
        return attributeParameters.count
    }
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, cellForRowAtIndexPath indexPath: AttributeIndexPath) -> AttributeDescriptor {
        
        let parameter = attributeParameters[indexPath.row]
        return AttributeDescriptor(title: parameter.name.stringFromCamelCase(), type: parameter.attributeType!)
        
    }
    
    func attributesInspector(attributesInspector: AttributesInspectorViewController, titleForHeaderInSection section: Int) -> String
    {
        return "Parameters"
    }
    
    func sceneNodeForObject() -> SCNNode {
        let width: CGFloat = 0.1
        let height:CGFloat = 0.2
        let length: CGFloat = 0.2
        
        // Hacky way of dealing with hit test returning child nodes for camera
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.15, chamferRadius: 0)
        let lensGeometry = SCNPyramid(width: width, height: 0.07, length: width)
        let lens = SCNNode(geometry: lensGeometry)
        let cameraNode = SCNNode()
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.name = name
        lens.position.z += 0.15
        lens.rotation = SCNVector4Make(1,0 , 0, -CGFloat(M_PI/2))
        cameraNode.addChildNode(lens)
        cameraNode.addChildNode(boxNode)
        cameraNode.name = name
        lens.name = name
        cameraNode.name = name
        
        if let position = position {
            cameraNode.position = position

        }
        return cameraNode
    }

    
    
    
}



class VehicleCameraXMLParser:NSObject, NSXMLParserDelegate {
    var parameters: [Parameter] = []
    var viewType: String = ""
    var cameraViews: [CameraView] = []
    var cameraView: CameraView?
    
    var isInViewChild: Bool = false
    
    func parserDidStartDocument(parser: NSXMLParser) {
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "View" {
            isInViewChild = true
            let type = attributeDict["type"]!
            let name = attributeDict["ident"]!
            
            cameraView = CameraView(name: name,type: type, parameters: [])
            
        } else if elementName == "Parameter" {
            if isInViewChild {
                let typeString = attributeDict["type"]!
                let name = attributeDict["name"]!

                
                if let valueString = attributeDict["value"] {
                    let valueType = ValueType(rawValue: typeString)!
                    let parameter = Parameter(name: name, value: valueString, valueType: valueType)
                    cameraView!.parameters.append(parameter)

                } else if name == "target" || name == "offset" {
                    
                    let xValue = attributeDict["x"]!.floatValue
                    let yValue = attributeDict["y"]!.floatValue
                    let zValue = attributeDict["z"]!.floatValue
                    let position = SCNVector3(xValue, yValue,zValue)
                    cameraView?.position = position
                    print("Found camera at \(position)")
                }
                
            }
            
        } else {
            isInViewChild = false
        }
    }

    
   
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let cameraView = cameraView where  elementName == "View" {
            cameraViews.append(cameraView)
        } else {
            isInViewChild = true
        }
    }
    
}

