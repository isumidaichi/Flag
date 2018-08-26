//
//  Placeholder.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/26.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import Foundation
import UIKit

public class PlaceHolderTextView: UITextView {
    
    lazy var placeHolderLabel:UILabel = UILabel()
    var placeHolderColor:UIColor = UIColor.lightGray
    var placeHolder:NSString = "例）今回はxcodeについて学びます。xcodeと簡単なswiftの文法を学び、オリジナルなメモアプリを作りましょう。"
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: NSNotification.Name.UITextViewTextDidChange, object: nil)
    }
    
    override public func draw(_ rect: CGRect) {
        if(self.placeHolder.length > 0) {
            self.placeHolderLabel.frame = CGRect(x: 8, y: 8, width: self.bounds.size.width - 16 , height: 0)
            self.placeHolderLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            self.placeHolderLabel.numberOfLines = 0
            self.placeHolderLabel.font = self.font
            self.placeHolderLabel.backgroundColor = UIColor.clear
            self.placeHolderLabel.textColor = self.placeHolderColor
            self.placeHolderLabel.alpha = 0
            self.placeHolderLabel.tag = 1
            
            self.placeHolderLabel.text = self.placeHolder as String
            self.placeHolderLabel.sizeToFit()
            self.addSubview(placeHolderLabel)
        }
        
        self.sendSubview(toBack: placeHolderLabel)
        
        if(self.text.utf16.count == 0 && self.placeHolder.length > 0){
            self.viewWithTag(1)?.alpha = 1
        }
        
        super.draw(rect)
    }
    
    @objc func textChanged(notification:NSNotification?) -> (Void) {
        if(self.placeHolder.length == 0){
            return
        }
        
        if(self.text.utf16.count == 0) {
            self.viewWithTag(1)?.alpha = 1
        }else{
            self.viewWithTag(1)?.alpha = 0
        }
    }
    
}
