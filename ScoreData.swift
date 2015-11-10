//
//  ScoreData.swift
//  2048
//
//  Created by 陈林 on 15/11/10.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import Foundation
import CoreData

/**
 该文件需要在选中
 */
class ScoreData: NSManagedObject {
    
    @NSManaged var maxScore: NSNumber?

}
