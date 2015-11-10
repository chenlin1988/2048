//
//  ActionModel.swift
//  2048
//
//  Created by 陈林 on 15/9/28.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import Foundation

enum MoveDirection{
    case Up
    case Down
    case Left
    case Right
}

//要执行的动作
enum Action {
    case NoAction(index:Int,value:Int)
    case Move(index:Int,value:Int)
    case SingleMerged(index:Int,value:Int)
    case DoubleMerged(firstIndex:Int,secondIndex:Int,value:Int)
    
    func getValue()->Int{
        switch self {
        case let NoAction(_,v):
            return v
        case let Move(_,v):
            return v
        case let SingleMerged(_,v):
            return v
        case let DoubleMerged(_,_,v):
            return v
        }
    }
    
    
    func getIndex()->Int{
        switch self {
        case let NoAction(i,_):
            return i
        case let Move(i,_):
            return i
        case let SingleMerged(i,_):
            return i
        case let DoubleMerged(i,_,_):
            return i
        }
    }
    
}

//用于更新面板中部分方块的目的地、值、移除面板等
enum ActionOrder{
    case SingleActionOrder(index:Int,value:Int,destination:Int,merged:Bool)
    case DoubleActuinOrder(firstIndex:Int,secondIndex:Int,value:Int,destiantion:Int)
}

//移动手势处理
struct MoveCommand{
    let direction:MoveDirection
    var completion:(Bool)->Void
}