//
//  GameModel.swift
//  2048
//
//  Created by 陈林 on 15/9/24.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import UIKit


protocol GameCommandProtocol : class {
    func scoreChanged(score: Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
    func insertTile(location: (Int, Int), value: Int)
}

/**
游戏内部实现控制类
*/
class GameCommand: NSObject {
    
    //维，表示行或者列数
    var dimension:Int
    //阈值，当移动得到的最大值为该值时，提示胜利
    var threshold:Int
    //控制排队执行移动操作的等待时间
    var timer:NSTimer
    //排队执行等待时间
    let queueDelay = 0.3
    
    //最大可以排队执行的移动操作
    let maxCommand:Int = 100
    //排队执行的手势操作
    var queue:[MoveCommand]
    //游戏面板所以的格子上的信息
    var gameBoard:GameBoardData<TileInfo>
    
    let delegate:GameCommandProtocol
    
    var score:Int{
        didSet{
            //在赋值完毕后执行代理
            delegate.scoreChanged(score)
        }
    }
    
    init(dimension:Int,threshold:Int,delegate:GameCommandProtocol) {
        self.dimension = dimension
        self.threshold = threshold
        
        timer = NSTimer()
        queue = [MoveCommand]()
        //初始化面板上所以都为空
        gameBoard = GameBoardData(d: dimension, initValue: TileInfo.Empty)
        self.delegate = delegate
        self.score = 0
        //不能忘记继承父级init
        super.init()
    }
    
    func clearAll(){
        for row in 0..<dimension {
            
            for column in 0..<dimension{
                switch gameBoard[row,column] {
                case TileInfo.Empty:
                    continue
                default:
                    gameBoard[row,column] = TileInfo.Empty
                }
            }
        }
        
    }
    
    
    /**
    在面板插入新的方块
    */
    func insertTile(position:(Int,Int),value:Int){
        let (r,c) = position
        //将获取到得随机位置赋值
        gameBoard[r,c] = TileInfo.Tile(value)
        //通知代理处理界面方块的显示
        delegate.insertTile(position, value: value)
    }
    
    /**
    获取新的随机数字（2、4）方块显示位置
    */
    func insertTileByRandom(value:Int){
        
        let empty = getEmptyByGameBoard()
        
        if empty.isEmpty {
            return
        }
        
        let random = arc4random_uniform(UInt32(empty.count - 1))
        
        insertTile(empty[Int(random)], value: value)
    }
    
    /**
    获取面板中为empty的格子
    */
    func getEmptyByGameBoard()->[(Int,Int)]{
        var empty = [(Int,Int)]()
        
        for row in 0..<dimension{
            for column in 0..<dimension{
                switch gameBoard[row,column] {
                    case TileInfo.Empty:
                        empty.append((row,column))
                default: break;
                }
                //swift2中更简单的判断枚举类型是否相同
//                if case TileInfo.Empty = gameBoard[row,column] {
//                    
//                }
            }
        }
        
        return empty
    }
    
    /**
    判断是否游戏结束
    */
    func hasLost()->Bool{
        
        //首先判断是否有empty的格子，如果有，直接返回false
        if getEmptyByGameBoard().count > 0 {
            return false
        }
        
        //如果没有empty的格子，那么向下和向左判断是否有可以合并的方块，（相邻方块value相等）
        for i in 0..<dimension{
            for j in 0..<dimension{
                
                if case let TileInfo.Tile(v) = gameBoard[i,j] where neighbourIsEqualToDown((i,j), value: v) || neighbourIsEqualToRight((i,j), value: v){
                    return false
                }
            }
        }
        
        return true
    }
    
    /**
        判断相邻的方块是否相等（向下对比）
    */
    func neighbourIsEqualToDown(position:(Int,Int),value:Int)->Bool{
        let (r,c) = position
        if r+1 >= dimension {
            return false
        }
        //判断是否相同的枚举类型，如果相同，并赋值
        if case let TileInfo.Tile(v) = gameBoard[r+1,c] {
            if value == v {
                return true
            }
        }
        return false
    }
    
    
    func neighbourIsEqualToRight(position:(Int,Int),value:Int)->Bool{
        let (r,c) = position
        if c+1 >= dimension {
            return false
        }
        
        if case let TileInfo.Tile(v) = gameBoard[r,c+1] {
            return value == v
        }
        return false
    }
    
    /**
    判断是否已经有2048得方块，如果有，说明已经胜利，但是游戏可以继续
    */
    func hasWin()->Bool{
        
        for i in 0..<dimension{
            for j in 0..<dimension{
                if case let TileInfo.Tile(v) = gameBoard[i,j] where v >= threshold{
                    return true
                }
            
            }
        }
        
        return false
    }
    
    //列队移动
    func queueMove(direction:MoveDirection,completion:(Bool)->Void){
        
        if queue.count > maxCommand {
            return
        }
        
        queue.append(MoveCommand(direction:direction,completion:completion))
        
        //如果没有启动就启动
        if !timer.valid {
            timerHandler()
        }
        
    }
    
    
    func timerHandler(){
        //判断有没有列队要执行的手势滑动操作
        if queue.count == 0 {
            return
        }
        
        //是否需要继续之后的列队手势操作
        var valid:Bool = false
        
        while queue.count > 0 {
            let command = queue[0]
            queue.removeAtIndex(0)
            
            valid = executeMove(command.direction)
            
            command.completion(valid)

            if valid {
                break
            }
            
        }
        
        if valid {
            //如果本次移动的有方块，那么等待后执行下一次的移动
            timer = NSTimer.scheduledTimerWithTimeInterval(queueDelay, target: self, selector: Selector("timerHandler"), userInfo: nil, repeats: false)
        }
        
    }
    
    func executeMove(command:MoveDirection)->Bool{
        /**
        1.根据移动的方向获取到反向的数据列
        2.去除该列empty的格子，例如：[2|x|x|2]移动为[2|2]
        3.计算需要合并的格子，例如：[2|2|4|4]合并为[4|8]
        4.将移动和合并好的方块再排序用于在面板上呈现
        5.将计算好的格子更新到面板上
        
        */
        
        //用于判断是否需要执行下一次移动 false：说明当前的移动已经没有可以移动的方块了，true：说明当前的移动还有可以移动的方块
        var isExecuteNextMove = false
        for i in 0..<dimension {
            
            let tiles_temp = buildPositionForTiles(i, command: command)
            let group = tiles_temp.map({ (pt:(Int,Int)) -> TileInfo in
                let (row,column) = pt
                
                return gameBoard[row,column]
            })
            
            let actionOrder = convert(mergeValue(clearEmptyBox(group)))
            
//            print("actionOrder.count:\(actionOrder.count)")
            
            isExecuteNextMove = actionOrder.count > 0 ? true : isExecuteNextMove
            
            for order in actionOrder {
                switch order {
                    case let ActionOrder.SingleActionOrder(index: j, value: v, destination: d, merged: m):
                        //获取到之前的方块位置
                        let (beforRow,beforCoulmn) = tiles_temp[j]
                        let (currentRow,currentCoulmn) = tiles_temp[d]
                        //加分数
                        if m {
                            score += v
                        }
                        //将之前位置的方块重置为empty
                        gameBoard[beforRow,beforCoulmn] = TileInfo.Empty
                        //将显示新方块位置的值替换为新计算的值
                        gameBoard[currentRow,currentCoulmn] = TileInfo.Tile(v)
                        //通知代理处理界面元素
                        delegate.moveOneTile(tiles_temp[j], to: tiles_temp[d], value: v)
                    
                    case let ActionOrder.DoubleActuinOrder(firstIndex: fIndex, secondIndex: sIndex, value: v, destiantion: d):
                        
                        let (beforRow1,beforCoulmn1) = tiles_temp[fIndex]
                        let (beforRow2,beforCoulmn2) = tiles_temp[sIndex]
                        let (currentRow,currentCoulmn) = tiles_temp[d]
                        
                        score += v
                        
                        gameBoard[beforRow1,beforCoulmn1] = TileInfo.Empty
                        gameBoard[beforRow2,beforCoulmn2] = TileInfo.Empty
                        
                        gameBoard[currentRow,currentCoulmn] = TileInfo.Tile(v)
                        delegate.moveTwoTiles((tiles_temp[fIndex],tiles_temp[sIndex]), to: tiles_temp[d], value: v)
                    
                }
            }
        }
        return isExecuteNextMove
    }
    
    /**
    根据移动的方向获取到反向的方块坐标数组，有可能根据行或列获取
    
    */
    func buildPositionForTiles(i:Int,command:MoveDirection)->[(Int,Int)]{
        //Array<(row,column) 代表着行和列
        var array = Array<(Int,Int)>(count: dimension, repeatedValue: (0,0))
        
        for j in 0..<dimension {
            switch command {
            case MoveDirection.Up:
                //从(0,0) -- (3,0)
                array[j] = (j,i)
            case MoveDirection.Down:
                //从(3,0) -- (0,0)
                array[j] = (dimension - j - 1,i)
            case MoveDirection.Left:
                //从(0,0) -- (0,3)
                array[j] = (i,j)
            case MoveDirection.Right:
                //从(0,3) -- (0,0)
                array[j] = (i,dimension - j - 1)
            }
        }
        
        return array
    }
    
    /**
    去除该集合中empty的方格，例如：[2|x|x|2]移动为[2|2]
    */
    func clearEmptyBox(group:[TileInfo]) -> [Action]{
        var array = [Action]()
        for (index,tile) in group.enumerate() {
            switch tile {
            case let TileInfo.Tile(value) where array.count == index:
                //如果每一次要添加时，判断当前数组中得个数与当前要添加的index相等，说明之前都是TileInfo，没有Empty，所以告诉下面的处理过程，改tile不需要移动
                array.append(Action.NoAction(index: index, value: value))
            case let TileInfo.Tile(value):
                //除过不需要移动的，那么就是需要移动的tile
                array.append(Action.Move(index: index, value: value))
            default: break
                
            }
        }
        return array
    }
    
    /**
    计算需要合并的格子，将相邻的，值相同的合并，每一个方块只能参加一次合并，例如：[2|2|4|4]合并为[4|8]，
    */
    func mergeValue(group:[Action]) ->[Action]{
        var array = [Action]()
        //是否跳过下一个
        var skipNext:Bool = false
        for (index,action) in group.enumerate() {
            if skipNext {
                skipNext = false
                continue
            }
            
            /**
            1.先判断是不是第一个要合并的
            2.判断是否有第二、三、四...个要合并的
            3.将不合并的移动补位
            4.判断不需要移动的
            5.无论之前有没有要合并或者移动的，当前为移动的依然要移动
            */
            switch action {
            case let Action.NoAction(index: i, value: v) where index < group.count - 1 && v == group[index+1].getValue() && isNotMoves(index, currentGroupCount: array.count, beforIndex: i):
                let nextTile = group[index+1]
//                print("v:\(v)  nextValue:\(nextTile.getValue())")
                let v_temp = v + nextTile.getValue()
//                print("v_temp:\(v_temp)")
                skipNext = true
                array.append(Action.SingleMerged(index: nextTile.getIndex(), value: v_temp))
                
            case let tile where index < group.count - 1 && tile.getValue() == group[index+1].getValue() :
                let nextTile = group[index+1]
                let v_temp = tile.getValue() + nextTile.getValue()
                skipNext = true
                array.append(Action.DoubleMerged(firstIndex: tile.getIndex(), secondIndex: nextTile.getIndex(), value: v_temp))
            case let Action.NoAction(index: i, value: v) where !isNotMoves(index, currentGroupCount: array.count, beforIndex: i):
                array.append(Action.Move(index: i, value: v))
            case let Action.NoAction(index: i, value: v):
                array.append(Action.NoAction(index: i, value: v))
            case let Action.Move(index: i, value: v):
                array.append(Action.Move(index: i, value: v))
            default:
                break
//                print("不处理‘SingleMerged’和‘DoubleMerged’，因为当前的group中还没有这两个枚举")
            }
            
        }
        
        return array
    }
    
    /**
    如果当前的index等于当前数组的count，并且之前的index和当前的index相等，那么就说明当前的tile不需要移动
    */
    func isNotMoves(currentIndex:Int,currentGroupCount:Int,beforIndex:Int)->Bool{
        return currentIndex == currentGroupCount && currentGroupCount == currentIndex
    }
    
    /**
    
    将移动和合并好的方块再排序用于在面板上呈现
    */
    func convert(group:[Action])->[ActionOrder]{
        
        var order = [ActionOrder]()
        
        for (index,action) in group.enumerate() {
            switch action {
                case let Action.SingleMerged(index: i, value: v):
                    order.append(ActionOrder.SingleActionOrder(index: i, value: v, destination: index, merged: true))
                case let Action.DoubleMerged(firstIndex: fi, secondIndex: si, value: v):
                    order.append(ActionOrder.DoubleActuinOrder(firstIndex: fi, secondIndex: si, value: v, destiantion: index))
                case let Action.Move(index: i, value: v):
                    order.append(ActionOrder.SingleActionOrder(index: i, value: v, destination: index, merged: false))
                default:
                 break
//                    print("其他的action不需要处理")
            }
        }

        return order
        
    }
    
    
    
}
