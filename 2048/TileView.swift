//
//  TileView.swift
//  2048
//
//  Created by 陈林 on 15/9/22.
//  Copyright © 2015年 lin.chen. All rights reserved.
//

import UIKit

class TileView: UIView {
    //方块上要显示的数字
    var value:Int = 0 {
        didSet{
            //设置背景颜色
            backgroundColor = delegate.tileColor(value)
            //设置文字颜色
            numberLabel.textColor = delegate.numbersColor(value)
            numberLabel.text = "\(value)"
        }
    }
    //数字显示的label
    var numberLabel:UILabel
    //接触循环强引用，避免被销毁时，无法销毁
//    unowned let delegate:TileColorProviderProtocol
    let delegate:TileColorProviderProtocol
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(aValue:Int,tileWidth:CGFloat,postion:CGPoint,cornerRadius:CGFloat,delegate:TileColorProviderProtocol){
        self.value = aValue
        self.delegate = delegate
        
        //设置方块数字label的显示位置和大小
        numberLabel = UILabel(frame: CGRectMake(0, 0, tileWidth, tileWidth))
        //缩放因子
        numberLabel.minimumScaleFactor = 0.5
        
        super.init(frame: CGRectMake(postion.x, postion.y, tileWidth, tileWidth))
        self.layer.cornerRadius = cornerRadius
        addSubview(numberLabel)
        
        //设置背景颜色
        backgroundColor = delegate.tileColor(value)
        //设置文字居中
        numberLabel.textAlignment = NSTextAlignment.Center
        //设置文字颜色
        numberLabel.textColor = delegate.numbersColor(value)
        
        //设置字体
        numberLabel.font = delegate.fontForNumbers()
        numberLabel.text = "\(value)"
        
    }

}
