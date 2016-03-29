//
//  Race.swift
//  wf_app
//
//  Created by Rui Brito on 28/03/16.
//  Copyright © 2016 Rui Brito. All rights reserved.
//

import Foundation
import CoreData

@objc(Race)
class Race: NSManagedObject {
    
    @NSManaged var qrcode: String?
    @NSManaged var validated: String?
    @NSManaged var check1: String?
    @NSManaged var check2: String?
    @NSManaged var final: String?

}
