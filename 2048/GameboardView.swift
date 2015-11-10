//
//  GameboardView.swift
//  2048
//
//  Created by 陈林 on 15/9/21.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import UIKit

class GameboardView: UIView {
    
    //方块个数
    var dimension:Int = 4
    //方块的宽
    var tileWidth: CGFloat = 40
    //方块于方块的间距
    var tilePadding:CGFloat = 3
    //方块圆角值
    var tileCornerRadius:CGFloat = 6
    //所有的方块集合
    var tiles:Dictionary<NSIndexPath,TileView>
    
    let tileColorProvider = TileColorProvider()
    
    
    let tilePopStartScale: CGFloat = 0.1
    let tilePopMaxScale: CGFloat = 1.1
    let tilePopDelay: NSTimeInterval = 0.02
    let tileExpandTime: NSTimeInterval = 0.18
    let tileContractTime: NSTimeInterval = 0.08
    
    let mergeStartScale: CGFloat = 1.0
    let mergeEndScale: CGFloat = 1.1
    let mergeScaleDuration: NSTimeInterval = 0.08
    let mergeRestoreDuration: NSTimeInterval = 0.08
    
    let tileMoveDuration: NSTimeInterval = 0.1
    
    init(dimension:Int,tileWidth:CGFloat,tilePadding:CGFloat ,cornerRadius:CGFloat ,backgroundColor:UIColor,rectBackgroundColor:UIColor){
        self.dimension = dimension
        self.tileWidth = tileWidth
        self.tilePadding = tilePadding
        self.tileCornerRadius = cornerRadius
        
        tiles = Dictionary()
        
        let rectWidth = tilePadding + CGFloat(dimension) * (tileWidth + tilePadding)
        super.init(frame: CGRectMake(0, 0, rectWidth, rectWidth))
        
        self.backgroundColor = backgroundColor
        layer.cornerRadius = cornerRadius
        
        self.createGameboard(rectBackgroundColor)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createGameboard(rectBackgroundColor:UIColor){
        
        //x光标位置
        var xCursor:CGFloat
        //y光标位置
        var yCursor:CGFloat
        
        xCursor = tilePadding
        
        for _ in 0 ..< dimension {
            
            yCursor = tilePadding
            
            for _ in 0 ..< dimension {
                let tileBackgroundColor = UIView(frame: CGRectMake(xCursor, yCursor, tileWidth, tileWidth))
                tileBackgroundColor.backgroundColor = rectBackgroundColor
                tileBackgroundColor.layer.cornerRadius = tileCornerRadius
                addSubview(tileBackgroundColor)
                yCursor += tileWidth + tilePadding
            }
            
            xCursor += tileWidth +  tilePadding
        }
        
    }
    
    
    func clearAll(){
        for row in 0..<dimension {
            for column in 0..<dimension {
                
                let index = NSIndexPath(forRow: row, inSection: column)
                
                let tile = tiles[index]
                
                if tile != nil {
                    tiles.removeValueForKey(index)
                    tile?.removeFromSuperview()
                }
                
            }
        }
    }
    
    func insertTile(position:(Int,Int),value:Int){
        
        let (row,column) = position
        
        //得到y轴要显示的点
        let y = tilePadding + CGFloat(row) * (tilePadding + tileWidth)
        //得到x轴要显示的点
        let x = tilePadding + CGFloat(column) * (tilePadding + tileWidth)
        
        let tile = TileView(aValue: value, tileWidth: tileWidth, postion: CGPointMake(x, y), cornerRadius: tileCornerRadius, delegate: tileColorProvider)
       
        tile.layer.setAffineTransform(CGAffineTransformMakeScale(0, 0))
        
        //将方块添加到视图中
        self.addSubview(tile)
        //将方块显示到前面
        self.bringSubviewToFront(tile)
        self.tiles[NSIndexPath(forRow: row, inSection: column)] = tile
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            tile.layer.setAffineTransform(CGAffineTransformMakeScale(1, 1))
            }) { (isComplete:Bool) -> Void in
               
        }
    }
    
    //移动或移除视图上的方块
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int){
        
        /**
        1.获取from的位置方块信息
        2.根据from的信息创建新的to方块，设置位置，大小，值
        3.移除to位置的方块
        */
        
//        print("from:\(from)   to:\(to)  value:\(value)")
        
        let (fromRow,fromColumn) = from
        let (toRow,toColumn) = to
        //获取到要移动的方块
        let fromIndexPath = NSIndexPath(forRow: fromRow, inSection: fromColumn)
        let toIndexPath = NSIndexPath(forRow: toRow, inSection: toColumn)
        
        let tile = tiles[fromIndexPath]
        let toTile = tiles[toIndexPath]
        
        //从集合中移除原始的方块信息
        tiles.removeValueForKey(fromIndexPath)
        //将tile放到新的面板位置中
        tiles[toIndexPath] = tile
        
        var tempTileFrame = tile?.frame
        //得到y轴要显示的点
        tempTileFrame?.origin.y = tilePadding + CGFloat(toRow) * (tilePadding + tileWidth)
        //得到x轴要显示的点
        tempTileFrame?.origin.x = tilePadding + CGFloat(toColumn) * (tilePadding + tileWidth)
       
        
        let isPopAnimation = (toTile != nil)
        
        UIView.animateWithDuration(tileMoveDuration, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            //给tile设置新的位置信息
            tile?.frame = tempTileFrame!
            }) { (isComplete:Bool) -> Void in
                //特效执行完成之后赋值
               tile?.value = value
                //移除多余的方块
                //从父级视图中移除自己
                toTile?.removeFromSuperview()
            
                if isPopAnimation {
                    //设置缩放前tile的缩放参数（原始大小）
                    tile?.layer.setAffineTransform(CGAffineTransformMakeScale(self.mergeStartScale, self.mergeStartScale))
                    UIView.animateWithDuration(self.mergeScaleDuration, animations: { () -> Void in
                        //放大为原来大小的1.1倍
                        tile?.layer.setAffineTransform(CGAffineTransformMakeScale(self.mergeEndScale, self.mergeEndScale))
                        },
                        completion: { (isComplete:Bool) -> Void in
                            //特效完成后，还原
                            UIView.animateWithDuration(self.mergeRestoreDuration, animations: { () -> Void in
                                tile?.layer.setAffineTransform(CGAffineTransformIdentity)
                            })
                    })
                }
        }
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int){
        
        
//        print("from1:\(from.0)   from2:\(from.1)   to:\(to)  value:\(value)")
        
        let (fromRow1,fromColumn1) = from.0
        let (fromRow2,fromColumn2) = from.1
        
        let (toRow,toColumn) = to
        
        let fromIndexPath1 = NSIndexPath(forRow: fromRow1, inSection: fromColumn1)
        let fromIndexPath2 = NSIndexPath(forRow: fromRow2, inSection: fromColumn2)
        let toIndexPath = NSIndexPath(forRow: toRow, inSection: toColumn)
        
        let tile1 = tiles[fromIndexPath1]
        let tile2 = tiles[fromIndexPath2]
        
        let toTile = tiles[toIndexPath]
        
        
        tiles.removeValueForKey(fromIndexPath1)
        tiles.removeValueForKey(fromIndexPath2)
        tiles[toIndexPath] = tile1
        
        var tempTileFrame = tile1?.frame
        
        tempTileFrame?.origin.x = tilePadding + CGFloat(toColumn) * (tilePadding + tileWidth)
        tempTileFrame?.origin.y = tilePadding + CGFloat(toRow) * (tilePadding + tileWidth)
        
        let isPopAnimate = (toTile != nil)
        
        UIView.animateWithDuration(tileMoveDuration, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            tile1?.frame = tempTileFrame!
            tile2?.frame = tempTileFrame!
            }) { (isCompelete:Bool) -> Void in
                tile1?.value = value
                
                tile2?.removeFromSuperview()
                toTile?.removeFromSuperview()
                
                if isPopAnimate {
                    
                    tile1?.layer.setAffineTransform(CGAffineTransformMakeScale(self.mergeStartScale, self.mergeStartScale))
                    
                    UIView.animateWithDuration(self.mergeScaleDuration, animations: { () -> Void in
                        tile1?.layer.setAffineTransform(CGAffineTransformMakeScale(self.mergeEndScale, self.mergeEndScale))
                        }, completion: { (isComplete:Bool) -> Void in
                            UIView.animateWithDuration(self.mergeRestoreDuration, animations: { () -> Void in
                                tile1?.layer.setAffineTransform(CGAffineTransformIdentity)
                            })
                    })
                }
        }
    }

}
