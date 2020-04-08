//
//  AlertSound+CDProperties.swift
//  WakyZzz
//
// //  Created by Eric Stein on 4/7/20.
//  Copyright © 2020 Olga Volkova OC. All rights reserved.
//
//

import Foundation
import CoreData


extension AlertRing {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlertRing> {
        return NSFetchRequest<AlertRing>(entityName: "AlertRing")
    }
    
    // All of these attributes are necessary therefore none of them is optional
    @NSManaged public var repeatMon: Bool
    @NSManaged public var repeatTue: Bool
    @NSManaged public var repeatWed: Bool
    @NSManaged public var repeatThu: Bool
    @NSManaged public var repeatFri: Bool
    @NSManaged public var repeatSat: Bool
    @NSManaged public var repeatSun: Bool
    @NSManaged public var enabled: Bool
    @NSManaged public var creationDateID: String
    @NSManaged public var time: Int32

}
