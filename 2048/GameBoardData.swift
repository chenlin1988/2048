//
//  GameBoardDatabase.swift
//  2048
//
//  Created by 陈林 on 15/9/24.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import Foundation

//方块信息,empty或者方块数字
enum TileInfo{
    case Empty
    case Tile(Int)
}



//存储面板中所有格子中得数据
struct GameBoardData<T>{
    
    let dimension:Int
    var boardArray:[T]
    
    
    //初始化
    init (d:Int,initValue:T){
        dimension = d
        boardArray = [T](count: dimension * dimension, repeatedValue: initValue)
    }
    
    
    //下标脚本get/set
    subscript (row:Int,column:Int) -> T{
        get{
            return boardArray[ dimension * row + column]
        }
        set{
            boardArray[dimension * row + column] = newValue
        }
    }
    
    
    //设置所以值(mutating：变异函数才能修改结构中得值)
    mutating func setAll(item:T){
        for i in 0..<dimension {
            
            for j in 0..<dimension{
                self[i,j] = item
            }
        }
    }
}
