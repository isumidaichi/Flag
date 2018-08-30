//
//  FavoriteTableViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class FavoriteTableViewController: UITableViewController {
    
    let uid = Auth.auth().currentUser?.uid
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var tableData:[DataSnapshot] = [DataSnapshot]()
    var eventId: String?
    
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 空のcellを消す
        view.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        tableView.tableFooterView = tableFooterView

        // ログイン確認
        guard let _ = Auth.auth().currentUser else {
            // アラート
            let alert = UIAlertController(title: "エラー", message: "ログインして下さい。", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
            return
        }

        // ログインボタン非表示
        self.loginButton.isEnabled = false
        self.loginButton.tintColor = UIColor.clear
        // DB参照
        ref = Database.database().reference()
        // tableviewの設定
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100

        observeData()
    }
    
    // ログインボタン押したら
    @IBAction func tappedLoginButton(_ sender: UIBarButtonItem) {
        let next = self.storyboard!.instantiateViewController(withIdentifier: "Login")
        self.present(next,animated: true, completion: nil)
    }
    
    // section数の指定
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // sectionあたりのcell数の指定
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    // cellの組み立て
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        
        // cell内の各要素を参照
        let titleLabel = cell.viewWithTag(1) as? UILabel
        let dateLabel = cell.viewWithTag(2) as? UILabel
        let placeLabel = cell.viewWithTag(3) as? UILabel
        // DBのデータを各要素に代入
        titleLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "title").value as? String
        dateLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "date").value as? String
        placeLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "place").value as? String
        
        return cell
    }
    
    // cellが選択された場合の処理
    override func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        eventId = self.tableData[indexPath.row].key
        performSegue(withIdentifier: "goDetail",sender: nil)
    }
    
    // segue呼ばれた際の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDetail" {
            let DetailTableViewController: DetailTableViewController = segue.destination as! DetailTableViewController
            DetailTableViewController.eventId = self.eventId!
        }
    }
    
    // お気に入りしているイベントを取得
    func observeData(){
        // 「event_user_favorite」テーブルからevent_idの取得
        self.defaultRef = ref.child("event_user_favorite")
        defaultRef?.queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            // 空の場合は空テーブルを表示
            guard snapshot.exists() else{
                self.tableData = []
                self.tableView.reloadData()
                return
            }
            
            var snapArray = [DataSnapshot]()
            var idArray: Array<Any> = []
            var array = [DataSnapshot]()
            
            // 取得データを配列に代入
            for snap in snapshot.children {
                snapArray.append(snap as! DataSnapshot)
            }
            // 配列からevent_idを取り出す
            for snap in snapArray {
                let id = snap.childSnapshot(forPath: "event_id").value as! String
                idArray.append(id)
            }
            // event_idから各eventの情報を取得しテーブルに反映
            for id in idArray {
                self.ref.child("events").child(id as! String).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                    array.append(snapshot)
                    self.tableData = array.reversed()
                    self.tableView.reloadData()
                })
            }
        })
    }
    
}

