//
//  FileHandle.swift
//  PSSGEditor
//
//  Created by Benjamin Johnson on 30/09/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation


// This is a generic protocol for reading binary files. At the moment only NSFileHandler conforms to it.
// However this could be any other file handling class such as System.IO.Stream for Windows (Once Swift is supported)

protocol FileHandle {
    
    func readInt32() -> Int? // Get Int32 from bytes in stream
    
    func readString(length: Int) -> String? // Read string of length from stream
    
    func readString() -> String? // Read length then read string of length provided
    
    func readCString() -> String? // Read Null terminated string
    
    var offsetInFile: UInt64 { get }
    
    func seekToFileOffset(offset: UInt64)
    
    func readUInt16() -> Int?
    
    func readUInt32() -> Int?
    
    func readBoolean() -> Bool?
    
    func readFloat() -> Float?
    
     func readBytes(count: Int) -> [UInt8]?
    
    func readData(size:Int) -> NSData?
    
    var availableData: NSData { get }
    
    
}

extension FileHandle {
    func readBoolean() -> Bool? {
        if let boolInt = readInt32() {
            return Bool(boolInt)
        }
        return nil
    }
    
    func readCString() -> String? {
        var stringBytes: [UInt8] = []
        repeat {
          //  let char = readBytes(1)!.first!
            stringBytes.append(readBytes(1)!.first!)
        } while(stringBytes.last! != 0)
        stringBytes.removeLast()
        
        // Convert to UTF8 String
        if let str = NSString(bytes: stringBytes, length: stringBytes.count, encoding: NSUTF8StringEncoding) as? String {
            return str
        }
        return nil
    }
    
    func readString(length: Int) -> String? {
        if let vals = readBytes(length) {
            var s = ""
            for v in vals {
                let uni = UnicodeScalar(UInt32(v))
                if uni.value == 0 {
                    break
                }
                s += String(uni)
            }
            return s
        }
        return nil
    }
    
    
    func readString() -> String? {
        if let length = readInt32() {
            return readString(length)
        } else {
            return nil
        }
    }
    
}

extension NSData {
    func floatValue() -> Float? {
        if self.length != sizeof(Float32) {
            return nil
        }
        var val: Float32 = 0
        self.getBytes(&val, length: sizeof(Float32))
        return val
    }
    

}

extension Float {
    var bigEndian: Float {
        return 0.0
    }
}



extension NSFileHandle: FileHandle {
    func readInt32() -> Int? {
        let data: NSData? = readDataOfLength(sizeof(Int32));
        if data?.length != sizeof(Int32) {
            return nil
        }
        var val: Int32 = 0
        data!.getBytes(&val, length: sizeof(Int32))
        val = val.bigEndian
        return Int(val)
    }
    
    func readData(size: Int) -> NSData? {
          return readDataOfLength(size);
    }
    
    func readUInt16() -> Int? {
        let data: NSData? = readDataOfLength(sizeof(UInt16));
        if data?.length != sizeof(UInt16) {
            return nil
        }
        var val: UInt16 = 0
        data!.getBytes(&val, length: sizeof(UInt16))
        val = val.bigEndian
        return Int(val)
    }
    
    
    func readUInt32() -> Int? {
        let data: NSData? = readDataOfLength(sizeof(UInt32));
        if data?.length != sizeof(UInt32) {
            return nil
        }
        var val: UInt32 = 0
        data!.getBytes(&val, length: sizeof(UInt32))
        val = val.bigEndian
        return Int(val)
    }
    
    func readFloat() -> Float? {
        let data: NSData? = readDataOfLength(sizeof(Float32));
        if data?.length != sizeof(Float32) {
            return nil
        }
        var val: Float32 = 0
        data!.getBytes(&val, length: sizeof(Float32))
        
       // val = val
        return Float(val)
    }
    
    func readDouble() -> Double? {
        let data: NSData? = readDataOfLength(sizeof(Double));
        if data?.length != sizeof(Double) {
            return nil
        }
        var val: Double = 0
        data!.getBytes(&val, length: sizeof(Double))
        // val = val
        return val
    }
    
    func readBytes(count: Int) -> [UInt8]? {
        let dat: NSData? = readDataOfLength(count)
        if dat?.length != count {
            print("Can't read bytes.")
            return nil
        }
        var bytes = [UInt8](count: count, repeatedValue: 0)
        dat!.getBytes(&bytes, length: dat!.length)
        return bytes
    }
    
 
    
}