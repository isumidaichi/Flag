//
//  SignUpViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Auth.auth().languageCode = "ja";
        // DB参照
        ref = Database.database().reference()
    }
    
    // 新規登録ボタンの処理
    @IBAction func tappedSignUpButton(_ sender: UIButton) {
        // 全てのfiledの記入を確認
        if let _ = name.text, let email = email.text, let password = password.text {
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                self.validateAuthenticationResult(user, error: error)
            }
        } else {
            let alert = UIAlertController(title: "エラー", message: "記入漏れがあります。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // ユーザー登録の処理
    private func validateAuthenticationResult(_ user: AuthDataResult?, error: Error?) {
        if let error = error{
            let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
        } else {
            // メアドの登録ができたらユーザー名を登録
            let request = Auth.auth().currentUser?.createProfileChangeRequest()
            request?.displayName = name.text
            request?.commitChanges(completion: { (error) in
                if let error = error {
                    let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            })
            
            // 最後にメアド認証
            guard (Auth.auth().currentUser?.isEmailVerified)! else {
                Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                    if nil == error {
                        // DBにもユーザー名を保存
                        if (Auth.auth().currentUser != nil) {
                            let newChild = self.ref.child("users").childByAutoId()
                            newChild.setValue(
                                [
                                    "user_id": Auth.auth().currentUser?.uid ,
                                    "name": self.name.text
                                ]
                            )
                        }
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        // メアドが存在しない場合、再入力を求める
                        let alert = UIAlertController(title: "エラー", message: "メールアドレスを確認して下さい", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                        
                        self.name.text = ""
                        self.email.text = ""
                        self.password.text = ""
                    }
                })
                return
            }
        }
    }
    
    // キーボード閉じるためのタッチイベント設定
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
