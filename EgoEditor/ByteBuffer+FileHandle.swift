//
//  ByteBuffer+FileHandle.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 5/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation


extension ByteBuffer: FileHandle {
    func readInt32() -> Int? {
        return Int(self.getInt32())
    }

    var offsetInFile: UInt64 { return UInt64(position) }
    
    var availableData: NSData {
        return readData(capacity)!
    }
    
    func seekToFileOffset(offset: UInt64) {
        self.position = Int(offset)
    }
    
    func readUInt16() -> Int? {
        return Int(getUInt16())
    }
    
    func readUInt32() -> Int? {
        return Int(getUInt32())
    }

    func readFloat() -> Float? {
        return getFloat32()
    }
    
    func readBytes(count: Int) -> [UInt8]? {
        return getUInt8(count)
    }
    
    func readData(size:Int) -> NSData? {
        if let bytes = readBytes(size) {
           
            return NSData(bytes: bytes, length: size)
        }
        return nil
    }
}

extension ByteBuffer {
    func readHalf() -> Float? {
        var byteData = self.getUInt16()
        return f16toFloat(&byteData)
    }
}


