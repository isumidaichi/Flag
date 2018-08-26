//
//  CreateViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CreateViewController: UIViewController {
    
    let uid = Auth.auth().currentUser?.uid
    var ref: DatabaseReference!
    var pickerData: String!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var detailField: UITextView!
    @IBOutlet weak var placeField: UITextField!
    @IBOutlet weak var tagField: UITextField!
    @IBOutlet weak var limitNumField: UITextField!
    @IBOutlet weak var dateField: UIDatePicker!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // DB参照
        ref = Database.database().reference()
        
        // キーボード設定
        placeField.textContentType = UITextContentType.fullStreetAddress
        scrollView.keyboardDismissMode = .interactive
        
        // textviewに枠線を設定
        detailField.layer.borderWidth = 0.4;
        detailField.layer.cornerRadius = 10.0;
        detailField.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // DBに保存
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard (uid != nil) else {
            // ログインアラート
            let alert = UIAlertController(title: "エラー", message: "再度ログインして下さい", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)

            return
        }
        
        let title: String = self.titleField.text!
        let detail: String = self.detailField.text!
        let place: String = self.placeField.text!
        let tag: String = self.tagField.text!
        let limitNum: String = self.limitNumField.text!
        let date: String? = self.pickerData
        
        guard nilCheck(title, detail, place, tag, limitNum, date) else {
            let alert = UIAlertController(title: "エラー", message: "記入漏れがあります。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        // eventsテーブルに
        let data : [String : Any] = [
            "title": title as Any,
            "detail": detail as Any,
            "place": place as Any,
            "tag": tag as Any,
            "limitNum": limitNum as Any,
            "date": date as Any
        ]
        let newChild = self.ref.child("events").childByAutoId()
        newChild.setValue(data)
        
        // event_user_hostテーブルに
        let event = newChild.key
    
        let hostData : [String : Any] = [
            "event_id": event as Any,
            "user_id": self.uid as Any,
            ]
        let newHostChild = self.ref.child("event_user_host").childByAutoId()
        newHostChild.setValue(hostData)
        
        // tagテーブルに
        let newTagChild = self.ref.child("tag").childByAutoId()
        newTagChild.setValue(tag)
        
        // モーダルを閉じる
        self.dismiss(animated: true, completion: nil)
    }
    
    // データ変更時の呼び出しメソッド
    @IBAction func changeDate(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d(EEE) HH:mm"
        pickerData = "\(formatter.string(from: sender.date)) 〜"
    }
    
    // キーボード設定
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    // fieldのnilをチェック
    func nilCheck(_ title: String, _ detail: String, _ place: String, _ tag: String, _ limitNum: String, _ date: String?) -> Bool {
        if title == "" || detail == "" || place == "" || tag == "" || limitNum == "" || date == nil {
            return false
        }
        return true
    }
    
}
