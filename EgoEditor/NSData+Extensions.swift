//
//  NSData+Extensions.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 2/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

extension String {
    var firstCharacter: Character {
        return self[self.startIndex.advancedBy(0)]
    }
    

}

extension NSData {
    
    /// Return hexadecimal string representation of NSData bytes
    
    public var hexadecimalString: NSString {
        var bytes = [UInt8](count: length, repeatedValue: 0)
        getBytes(&bytes, length: length)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
            hexString.appendString(" ")
            
        }
        
        return NSString(string: hexString)
    }
}