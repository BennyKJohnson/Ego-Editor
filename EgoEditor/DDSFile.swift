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
    let reserved1: UInt32 = 0                   // Reserved for some reason
    var pixelFormat: DDSPixelFormat!             // The pixel format.
    var caps: DDSCap = [.DDSCAPS_TEXTURE]       // Specifies the complexity of the surfaces stored.
    var caps2: DDSCap = []                      // Additional detail about the surfaces stored.
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
    
    static let DDSCAPS2_CUBEMAP_NEGATIVEZ = DDSCaps2(rawValue: 0x2000)
    static let DDSCAPS2_VOLUME	 = DDSCaps2(rawValue: 0x200000)         // Required for a volume texture.

}


// See https://msdn.microsoft.com/en-us/library/windows/desktop/bb943984(v=vs.85).aspx
struct DDSPixelFormat {
    let size: UInt32 = 32
    let flag: Flags
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
}

struct DDSFile {
    let magic: UInt32 = 0x20534444 // containing the four character code value 'DDS '
    var header: DDSHeader
    
    init?(node:PSSGNode) {
        
        header = DDSHeader(textureNode: node)
        let texelFormat = node.attributesDictionary["texelFormat"]!.value as! String
        let byteString = [UInt8](texelFormat.uppercaseString.utf8)
        let fourCC = UnsafePointer<UInt32>(byteString).memory
        
        switch(texelFormat) {
            case "dxt1":
                
                header.flags.insert(.DDSD_LINEARSIZE)
                header.pitchOrLinearSize = (header.width * header.height) / 2
                header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)
            case "dxt1_srgb":
                
                header.flags.insert(.DDSD_LINEARSIZE)
                header.pitchOrLinearSize = (header.width * header.height) / 2
                header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)

            case "dxt2", "dxt3", "dxt4", "dxt5":
                header.flags.insert(.DDSD_LINEARSIZE)
                header.pitchOrLinearSize = (header.width * header.height)
                header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)
            
            case "dxt5_srgb":
                
                header.flags.insert(.DDSD_LINEARSIZE)
                header.pitchOrLinearSize = (header.width * header.height) / 2
                header.pixelFormat = DDSPixelFormat(flags: [.DDPF_FOURCC], fourCC: fourCC)
        default:
            break
        }
        
        
    }
}