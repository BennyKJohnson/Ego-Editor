//
//  DDSFile.swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 6/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation

struct DDSHeader {
    let size: UInt32 = 124
    var flags: DDSFlags = DDSFlags.RequiredFlags
    let height: UInt32!                         // Surface height (in pixels).
    let width: UInt32!                          // Surface width (in pixels).
    var pitchOrLinearSize: UInt32!              // The pitch or number of bytes per scan line in an uncompressed texture
    var depth: UInt32!                          // Depth of a volume texture (in pixels), otherwise unused.
    var mipMapCount: UInt32!                    // Number of mipmap levels, otherwise unused.
    let reserved1: [UInt32] = Array<UInt32>(count: 11, repeatedValue: 0) // Reserved
    var pixelFormat: DDSPixelFormat!            // The pixel format.
    var caps: DDSCap = [.DDSCAPS_TEXTURE]       // Specifies the complexity of the surfaces stored.
    var caps2: DDSCaps2 = []                    // Additional detail about the surfaces stored.
    let caps3: UInt32 = 0
    let caps4: UInt32 = 0
    let reserved2: UInt32 = 0

    var linearSize: UInt32!
   
    init(textureNode: PSSGNode) {
        
        height = UInt32(textureNode.attributesDictionary["height"]?.value as! Int)
        width = UInt32(textureNode.attributesDictionary["width"]?.value as! Int)
    }
    
    
    static func linearSize(width: UInt32, height: UInt32) -> UInt32 {
        return (height * width) / 2
    }
    func data() -> NSData {
        let headerData = NSMutableData(capacity: Int(size))!
        headerData.appendBytes([size], length: sizeof(UInt32))
        headerData.appendBytes([flags.rawValue], length: sizeof(UInt32))
        headerData.appendBytes([height], length: sizeof(UInt32))
        headerData.appendBytes([width], length: sizeof(UInt32))
        headerData.appendBytes([pitchOrLinearSize], length: sizeof(UInt32))
        headerData.appendBytes([depth], length: sizeof(UInt32))
        headerData.appendBytes([mipMapCount], length: sizeof(UInt32))
        headerData.appendBytes(reserved1, length: reserved1.count * sizeof(UInt32))
        
        // Write Pixel Format
        headerData.appendData(pixelFormat.data())
        
        // Write Caps
        headerData.appendBytes([caps.rawValue], length: sizeof(UInt32))
        headerData.appendBytes([caps2.rawValue], length: sizeof(UInt32))
        headerData.appendBytes([caps3], length: sizeof(UInt32))
        headerData.appendBytes([caps4], length: sizeof(UInt32))
        
        headerData.appendBytes([reserved2], length: sizeof(UInt32))
        
        return headerData
    }
}

/*
// Flags to indicate which members contain valid data.
When you write .dds files, you should set the DDSD_CAPS and DDSD_PIXELFORMAT flags, and for mipmapped textures you should also set the DDSD_MIPMAPCOUNT flag. However, when you read a .dds file, you should not rely on the DDSD_CAPS, DDSD_PIXELFORMAT, and DDSD_MIPMAPCOUNT flags being set because some writers of such a file might not set these flags
*/
struct DDSFlags: OptionSetType {
    let rawValue: UInt32
    
    static let DDSD_CAPS = DDSFlags(rawValue: 0x1)              // Required
    static let DDSD_HEIGHT = DDSFlags(rawValue: 0x2)            // Required
    static let DDSD_WIDTH = DDSFlags(rawValue: 0x4)             // Required
    static let DDSD_PITCH = DDSFlags(rawValue: 0x8)             // Required when pitch is provided for an uncompressed texture.
    static let DDSD_PIXELFORMAT = DDSFlags(rawValue: 0x1000)    // Required
    static let DDSD_MIPMAPCOUNT = DDSFlags(rawValue: 0x20000)   // Required in a mipmapped texture.
    static let DDSD_LINEARSIZE = DDSFlags(rawValue: 0x80000)    // Required when pitch is provided for a compressed texture.
    static let DDSD_DEPTH = DDSFlags(rawValue: 0x800000)        // Required in a depth texture.
    
    static let RequiredFlags: DDSFlags = [.DDSD_CAPS, .DDSD_HEIGHT, .DDSD_WIDTH, .DDSD_PIXELFORMAT]
}

struct DDSCap: OptionSetType {
    let rawValue: UInt32
    
    static let DDSCAPS_COMPLEX = DDSCap(rawValue: 0x8) // a mipmap, a cubic environment map, or mipmapped volume texture
    static let DDSCAPS_MIPMAP = DDSCap(rawValue: 0x400000) // should be used for a mipmap
    static let DDSCAPS_TEXTURE = DDSCap(rawValue: 0x1000) // Required
    
}

struct DDSCaps2: OptionSetType {
    let rawValue: UInt32
    
    static let DDSCAPS2_CUBEMAP	= DDSCaps2(rawValue: 0x200)             // Required for a cube map.
    
    static let DDSCAPS2_CUBEMAP_POSITIVEX = DDSCaps2(rawValue: 0x400)   // Required when these surfaces are stored in a cube map.
    static let DDSCAPS2_CUBEMAP_NEGATIVEX = DDSCaps2(rawValue: 0x800)
    
    static let DDSCAPS2_CUBEMAP_POSITIVEY = DDSCaps2(rawValue: 0x1000)
    static let DDSCAPS2_CUBEMAP_NEGATIVEY = DDSCaps2(rawValue: 0x2000)
    
    static let DDSCAPS2_CUBEMAP_POSITIVEZ = DDSCaps2(rawValue: 0x4000)
    static let DDSCAPS2_CUBEMAP_NEGATIVEZ = DDSCaps2(rawValue: 0x8000)

    static let DDSCAPS2_VOLUME	 = DDSCaps2(rawValue: 0x200000)         // Required for a volume texture.

}


// See https://msdn.microsoft.com/en-us/library/windows/desktop/bb943984(v=vs.85).aspx
struct DDSPixelFormat {
    let size: UInt32 = 32
    var flag: Flags = []
    let fourCC: UInt32
    var rGBBitCount: UInt32 = 0
    
    var rBitMask: UInt32 = 0
    var gBitMask: UInt32 = 0
    var bBitMask: UInt32 = 0
    var aBitMask: UInt32 = 0
    
    struct Flags: OptionSetType {
        let rawValue: UInt32
        
        static let DDPF_ALPHAPIXELS = Flags(rawValue: 0x1)  // dwRGBAlphaBitMask contains valid data.
        static let DDPF_ALPHA =       Flags(rawValue: 0x2)  // dwRGBBitCount contains the alpha channel bitcount; dwABitMask contains valid data)
        static let DDPF_FOURCC = Flags(rawValue: 0x4) // dwFourCC contains valid data.
        static let DDPF_RGB = Flags(rawValue: 0x40)
        static let DDPF_YUV = Flags(rawValue: 0x200)
        static let DDPF_LUMINANCE = Flags(rawValue: 0x20000)
        
    }
    
    init(flags: Flags, fourCC: UInt32) {
        self.flag = flags
        self.fourCC = fourCC
    }
    
    func data() -> NSData {
        let formatData = NSMutableData(capacity: Int(size))!
        
        formatData.appendBytes([size], length: sizeof(UInt32))
        formatData.appendBytes([flag.rawValue], length: sizeof(UInt32))
        formatData.appendBytes([[fourCC]], length: sizeof(UInt32))
        formatData.appendBytes([rGBBitCount], length: sizeof(UInt32))
        
        // Write RGBA bit masks
        formatData.appendBytes([rBitMask], length: sizeof(UInt32))
        formatData.appendBytes([gBitMask], length: sizeof(UInt32))
        formatData.appendBytes([bBitMask], length: sizeof(UInt32))
        formatData.appendBytes([aBitMask], length: sizeof(UInt32))
        
        return formatData
    }
}

enum DDSTexelFormat: String {
    case dxt1 = "dxt1"
    case dxt1srgb = "dxt1_srgb"
    case dxt2 = "dxt2"
    case dxt3 = "dxt3"
    case dxt4 = "dxt4"
    case dxt5 = "dxt5"
    case dxt5srgb = "dxt5_srgb"
    case ui8x4 = "ui8x4"
    case u8 = "u8"
    
    var fourCC: UInt32 {
        let fourCCString = self.rawValue.componentsSeparatedByString("_").first!
        let byteString = [UInt8](fourCCString.uppercaseString.utf8)
        let fourCC = UnsafePointer<UInt32>(byteString).memory
        return fourCC
    }
}

struct DDSFile {
    let magic: UInt32 = 0x20534444 // containing the four character code value 'DDS '
    var header: DDSHeader
    var binaryData: NSData!
    var binaryData2: [Int: NSData] = [:]
    
    init?(node:PSSGNode) {
        
        header = DDSHeader(textureNode: node)
        let texelFormatString = node.attributesDictionary["texelFormat"]!.value as! String
        
        guard let texelFormat = DDSTexelFormat(rawValue: texelFormatString) else {
            return nil    // Unknown format, exit
        }
        
        let fourCC = texelFormat.fourCC

        switch(texelFormat) {
        case .dxt1:
                
            header.flags.insert(.DDSD_LINEARSIZE)
            header.pitchOrLinearSize = (header.width * header.height) / 2
            header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)
            
        case .dxt1srgb:
                
            header.flags.insert(.DDSD_LINEARSIZE)
            header.pitchOrLinearSize = (header.width * header.height) / 2
            header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)

        case .dxt2, .dxt3, .dxt4, .dxt5, .dxt5srgb:
                
            header.flags.insert(.DDSD_LINEARSIZE)
            header.pitchOrLinearSize = (header.width * header.height)
            header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)
        case .ui8x4:
            header.flags.insert(.DDSD_LINEARSIZE)
            header.pitchOrLinearSize = header.height * header.width // Ryder doesn't seem confident in this line
            header.pixelFormat = DDSPixelFormat(flags: [.DDPF_ALPHAPIXELS, .DDPF_RGB], fourCC: 0)
            header.pixelFormat.rGBBitCount = 32
            // Setup RGBA Masks
            header.pixelFormat.rBitMask = 0xFF0000
            header.pixelFormat.gBitMask = 0xFF00
            header.pixelFormat.bBitMask = 0xFF
            header.pixelFormat.aBitMask = 0xFF000000
            
        case .u8:
            header.flags.insert(.DDSD_LINEARSIZE)
            header.pixelFormat = DDSPixelFormat(flags: [.DDPF_LUMINANCE], fourCC: 0)
            header.pixelFormat.rGBBitCount = 9
            header.pixelFormat.rBitMask = 0xFF
        }
        
        // Add Auto Mip Map
        if let _ = node.attributesDictionary["automipmap"]?.value as? Int, numberOfMipMapLevels = node.attributesDictionary["numberMipMapLevels"]?.value as? Int {
            if numberOfMipMapLevels > 0 {
                
                header.flags.insert(.DDSD_MIPMAPCOUNT)
                header.mipMapCount = UInt32(numberOfMipMapLevels)
                header.caps.insert(.DDSCAPS_MIPMAP)
                header.caps.insert(.DDSCAPS_COMPLEX)
                
            }
        }
        
        let textureImageBlocks = node.nodesWithName("TEXTUREIMAGEBLOCK")
        if textureImageBlocks.count > 1 {
            for textureImageBlock in textureImageBlocks {
                let typeName = textureImageBlock.attributesDictionary["typename"]?.value as! String
                switch(typeName) {
                case "Raw":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_POSITIVEX)
                    binaryData2[0] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)
                case "RawNegativeX":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_NEGATIVEX)
                    binaryData2[1] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)

                case "RawPositiveY":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_POSITIVEY)
                    binaryData2[2] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)
                    
                case "RawNegativeY":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_NEGATIVEY)
                    binaryData2[3] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)
                    
                case "RawPositiveZ":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_POSITIVEZ)
                    binaryData2[4] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)
                    
                case "RawNegativeZ":
                    header.caps2.insert(.DDSCAPS2_CUBEMAP_NEGATIVEZ)
                    binaryData2[5] = (textureImageBlock.nodeWithName("TEXTUREIMAGEBLOCKDATA")!.data as! NSData)
                default:
                    break
                }
            }
        } else if let textureImageBlockData = textureImageBlocks.first?.nodeWithName("TEXTUREIMAGEBLOCKDATA") {
            binaryData = (textureImageBlockData.data as! NSData)
        } else {
            return nil // No image block data!
        }
    }
    
    func dataForFile() -> NSData {
        
        let fileData = NSMutableData()
        fileData.appendBytes([magic], length: sizeof(UInt32))
        fileData.appendData(header.data())
        
        if binaryData2.count > 0 {
            for var i = 0; i < binaryData2.count; i++ {
                if let data = binaryData2[i] {
                    fileData.appendData(data)
                }
            }
        } else {
            fileData.appendData(binaryData)
        }
    
        return fileData
    }
  
}