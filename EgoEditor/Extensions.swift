//
//  Extensions..swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 5/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
import Cocoa

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
