//
//  Extensions..swift
//  EgoEditor
//
//  Created by Benjamin Johnson on 5/10/2015.
//  Copyright © 2015 Benjamin Johnson. All rights reserved.
//

import Foundation
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
