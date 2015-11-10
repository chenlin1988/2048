//
//  ScoreView.swift
//  2048
//
//  Created by 陈林 on 15/10/29.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import UIKit
import CoreData

class ScoreView:UIView{
    
    var score:Int = 0 {
        didSet{
            
            if score > topScore {
                topScore = score
                saveHistoryMaxscore()
            }
            
//            print("ScoreView#score:\(score)")
            
            scoreLabel.text = "分数\n\(score)"
        }
    }
    
    var topScore:Int = 0 {
        didSet{
            topScoreLabel.text = "最高分数\n\(topScore)"
        }
    }
    
    let backgroud_left_padding:CGFloat = 20
    
    var backgroudWidth:CGFloat
    var backgroudHeight:CGFloat
    
    let viewPadding:CGFloat = 4
    
    
    let topBackgroudView:UIView
    var topScoreLabel:UILabel
    
    let scoreBackgroudView:UIView
    var scoreLabel:UILabel
    
    init (score:Int,x:CGFloat,y:CGFloat,width:CGFloat,font:UIFont){
        self.score = score
        
        self.backgroudWidth = width / 2 - backgroud_left_padding * 2
        
        self.backgroudHeight = backgroudWidth * 9 / 20
        
        topBackgroudView = UIView(frame: CGRectMake(backgroud_left_padding,0,backgroudWidth,backgroudHeight))
        topBackgroudView.backgroundColor = UIColor(red: 86/255, green: 86/255, blue: 86/255, alpha: 1)
        topBackgroudView.layer.cornerRadius = 6
        
        
        topScoreLabel = UILabel(frame: CGRectMake(0,0,backgroudWidth,backgroudHeight))
        topScoreLabel.textAlignment = NSTextAlignment.Center
        topScoreLabel.textColor = UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        topScoreLabel.numberOfLines = 0
        
//        topScoreLabel.text = "最高分数\n\(topScore)"
        
        topBackgroudView.addSubview(topScoreLabel)
        
        scoreBackgroudView = UIView(frame: CGRectMake(width / 2 + backgroud_left_padding,0,backgroudWidth,backgroudHeight))
        scoreBackgroudView.backgroundColor = UIColor(red: 86/255, green: 86/255, blue: 86/255, alpha: 1)
        scoreBackgroudView.layer.cornerRadius = 6
        
        scoreLabel = UILabel(frame: CGRectMake(0,0,backgroudWidth,backgroudHeight))
        scoreLabel.textAlignment = NSTextAlignment.Center
        scoreLabel.textColor = UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        scoreLabel.numberOfLines = 0
        scoreLabel.text = "分数\n\(self.score)"
        
        scoreBackgroudView.addSubview(scoreLabel)
        
        super.init(frame: CGRectMake(x, y, width, backgroudHeight))
        
        topScoreLabel.font = font
        scoreLabel.font = font
        self.addSubview(topBackgroudView)
        self.addSubview(scoreBackgroudView)
        
        
        var textScore = "最高分数\n\(topScore)"
        let maxScores = readHistoryMaxscore()
        if maxScores.count > 0 {
            let temp_score = maxScores[0] as! ScoreData
            textScore = "最高分数\n\(temp_score.maxScore!)"
            topScore = Int(temp_score.maxScore!)
        }
        
        topScoreLabel.text = textScore
    }

    func getContext()->NSManagedObjectContext{
        //获取代理
        let dataDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //获取管理上下问
        return dataDelegate.managedObjectContext
    }
    
    func readHistoryMaxscore()->[AnyObject]{
                //获取entity请求
        let request = NSFetchRequest(entityName: "ScoreData")
        
        var scoreHistory: [AnyObject]?
        
        var error: NSError? = nil
        
        do {
            scoreHistory = try getContext().executeFetchRequest(request)
        } catch let nserror1 as NSError{
            error = nserror1
            print("error:\(error)")
        }
        
        ///////deleteAll/////
//        for item in scoreHistory! {
//            print(item.valueForKey("maxScore"))
//            getContext().deleteObject(item as! NSManagedObject)
//        }
//
//        do{
//            try getContext().save()
//        }catch let err as NSError {
//            error = err
//            print("error:\(error)")
//        }
        return scoreHistory!
    }
    
    func saveHistoryMaxscore(){
        
        let context = getContext()
        
        let hmScore = readHistoryMaxscore()
        
        if hmScore.count == 0 {
//            let entity = NSEntityDescription.entityForName("ScoreData", inManagedObjectContext: context)
//            let scoreData = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
//            scoreData.setValue(topScore, forKey: "maxScore")
            
            let scoreVO = NSEntityDescription.insertNewObjectForEntityForName("ScoreData", inManagedObjectContext: context) as! ScoreData
            
            scoreVO.maxScore = topScore
            
            
        }else {
//            hmScore[0].setValue(topScore, forKey: "maxScore")
            
            (hmScore[0] as! ScoreData).maxScore = topScore
            
        }

        var error:NSError?
        
        do{
           try context.save()
        }catch let err as NSError {
            error = err
            print("error:\(error)")
        }
        
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
 
}
