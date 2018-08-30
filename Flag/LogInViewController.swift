//
//  LogInViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth

class LogInViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBAction func unwindLogin(segue: UIStoryboardSegue) {}

    override func viewDidLoad() {
        super.viewDidLoad()
        Auth.auth().languageCode = "ja";
    }
    
    // ログインボタンの処理
    @IBAction func tappedLogInButton(_ sender: UIButton) {
        if let email = email.text, let password = password.text{
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                self.validateAuthenticationResult(user, error: error)
            }}
    }
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        // モーダルを閉じる
        self.dismiss(animated: true, completion: nil)
    }
    
    private func validateAuthenticationResult(_ user: AuthDataResult?, error: Error?) {
        if let error = error{
            let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "goTop", sender: self)
        }
    }
    
    // キーボード閉じるためのタッチイベント設定
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
    }
}
