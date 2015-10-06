//
//  PSSGErrorTypes.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

enum PSSGDataType {
    case Binary
    case CompressedBinary
    case XML
}

enum PSSGReadError: ErrorType {
    case InvalidFile(reason: String)
    case InvalidAttribute(readError: PSSGAttributeReadError)
    case InvalidNode(readError: PSSGNodeReadError)
    
}

// Sub Node error type, instead of having a whole list. Its a lot easier to catch different errors if grouped then drill down to the exact reason and recover if possible.
enum PSSGNodeReadError: ErrorType {
    case NoIdentifier
    case NoSchema
    case InvalidAttribute(readError: PSSGAttributeReadError)
}

enum PSSGAttributeReadError: ErrorType {
    case NoSchema
    case NoKey
    case NoValue
}
