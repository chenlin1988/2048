//
//  ViewController.swift
//  2048
//
//  Created by 陈林 on 15/9/21.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import UIKit

class ViewController: UIViewController,GameCommandProtocol {

    //view上用到的手势
    let gestures = [("up:",UISwipeGestureRecognizerDirection.Up),("down:",UISwipeGestureRecognizerDirection.Down),("left:",UISwipeGestureRecognizerDirection.Left),("right:",UISwipeGestureRecognizerDirection.Right)]
    
    var gameCommand:GameCommand?
    var gameBoard:GameboardView?
    var scoreView:ScoreView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 251/255, green: 248/255, blue: 241/255, alpha: 1)
        
        initGame(4)
    }
    
    func fontForNumbers() -> UIFont {
        if let font = UIFont(name: "HelveticaNeue-Bold", size: 16) {
            return font
        }
        return UIFont.systemFontOfSize(16)
    }
    
    func initGame(dimension:Int,threshold:Int = 2048){
        
        let padding:CGFloat = 20
        let tilePadding:CGFloat = 4
        let cornerRadius:CGFloat = 6
        
        //初始化分数view
        scoreView = ScoreView(score: 0, x: 0, y: 50, width: self.view.bounds.size.width,font: fontForNumbers())
        view.addSubview(scoreView!)
        
        //创建重置按钮
        let swidth = scoreView?.scoreLabel.frame.width
        let sheight = scoreView?.scoreLabel.frame.height
        
        let sx = scoreView?.scoreBackgroudView.frame.origin.x
        let sy = (scoreView?.frame.origin.y)! + sheight! + 20
        
        let reset = UIButton(frame: CGRectMake(sx!,sy,swidth!,sheight! * 0.8))
        reset.backgroundColor = UIColor(red: 237.0/255.0, green: 224.0/255.0, blue: 200.0/255.0, alpha: 1.0)
        reset.setTitle("New Game", forState: UIControlState.Normal)
        reset.setTitleColor(UIColor(red: 119.0/255.0, green: 110.0/255.0, blue: 101.0/255.0, alpha: 1.0), forState: UIControlState.Normal)
        reset.layer.cornerRadius = cornerRadius
        reset.addTarget(self, action: Selector("resetGame"), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(reset)
        

        //得到游戏面板的宽
        let gameBoardWidth = self.view.bounds.size.width - padding * 2
        
        //得到方块应该显示的宽度
        let tileWidth = (gameBoardWidth - (CGFloat(dimension) + 1)*tilePadding) / CGFloat(dimension)
        
        //创建游戏面板
        let game = GameboardView(dimension: dimension, tileWidth: tileWidth, tilePadding: tilePadding, cornerRadius: cornerRadius, backgroundColor: UIColor.blackColor(), rectBackgroundColor: UIColor.darkGrayColor())
        
        game.frame.origin.x = padding
        game.frame.origin.y = reset.frame.origin.y + reset.bounds.size.height + 20
        
        
        view.addSubview(game)
        
        gameBoard = game
        //创建游戏操作模块，
        gameCommand = GameCommand(dimension: dimension, threshold: threshold, delegate: self)
        //初始方块信息
        gameCommand?.insertTileByRandom(2)
        gameCommand?.insertTileByRandom(2)
        //注册手势监听
        registerGestureRecognizer()
    }
    
    func resetGame(){
        gameBoard?.clearAll()
        gameCommand?.score = 0
        gameCommand?.clearAll()
        gameCommand?.insertTileByRandom(2)
        gameCommand?.insertTileByRandom(2)
    }
    
    //注册轻扫手势识别器
    //UISwipeGestureRecognizer在不设置direction的时候，默认是向右滑动
    func registerGestureRecognizer(){
        
        for (s,g) in gestures {
            //创建手势对象
            let gesture = UISwipeGestureRecognizer(target: self, action: Selector(s))
            //操作的手指数
            gesture.numberOfTouchesRequired = 1
            //方向
            gesture.direction = g
            //注册到视图中
            self.view.addGestureRecognizer(gesture)
        }
       
    }
    
    
    func up (sender:UISwipeGestureRecognizer){
        
        queueMove(MoveDirection.Up)
    }
    
    func down (sender:UISwipeGestureRecognizer){
        queueMove(MoveDirection.Down)
    }
    
    func left (sender:UISwipeGestureRecognizer){
        queueMove(MoveDirection.Left)
    }
    
    func right (sender:UISwipeGestureRecognizer){
        queueMove(MoveDirection.Right)
    }
    
    
    func scoreChanged(score: Int){
//        print("score:\(score)")
        scoreView?.score = score
        
    }
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int){
//        print("单个移动")
        gameBoard?.moveOneTile(from, to: to, value: value)
    }
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int){
//        print("多个移动")
        gameBoard?.moveTwoTiles(from, to: to, value: value)
    }
    func insertTile(location: (Int, Int), value: Int){
        gameBoard?.insertTile(location, value: value)
    }

    
    func queueMove(direction:MoveDirection){
        gameCommand?.queueMove(direction, completion: { (changed:Bool) -> Void in
//            print("change:\(changed)")
            if changed {
                self.showMessage(changed)
            }
        })
    }
    
    func showMessage(changed:Bool){
        //1.判断是否有2048.
        //2.生成新的方块
        //3.判断是否已经无法移动（游戏结束）
        if gameCommand!.hasWin() {
            
            let alertWin = UIAlertController(title: "Win", message: "恭喜您获得了2048", preferredStyle: UIAlertControllerStyle.Alert)
            let alertAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
            alertWin.addAction(alertAction)
            self.presentViewController(alertWin, animated: true, completion: nil)
            return
        }
        
        let value = (arc4random_uniform(100) % 2 == 0 ? 4 : 2)
        gameCommand?.insertTileByRandom(value)
        
        if gameCommand!.hasLost() {
            let alertLost = UIAlertController(title: "Lost", message: "抱歉，游戏结束", preferredStyle: UIAlertControllerStyle.Alert)
            let alertAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
            alertLost.addAction(alertAction)
            self.presentViewController(alertLost, animated: true, completion: nil)
        }
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

