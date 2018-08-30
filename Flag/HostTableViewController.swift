//
//  HostTableViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class HostTableViewController: UITableViewController {

    let uid = Auth.auth().currentUser?.uid
    var eventId: String?
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var joinRef: DatabaseReference?
    let sectionTitle = ["タイトル", "詳細", "日時", "住所", "キーワード", "参加人数","参加者一覧"]
    var tableData: [String : Any] = [
        "title": "",
        "detail": "",
        "place": "",
        "tag": "",
        "joinNum": 0,
        "limitNum": "",
        "date": ""
    ]
    var joinTableData:[DataSnapshot] = [DataSnapshot]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // DB参照
        ref = Database.database().reference()
        // tableviewの設定
        tableView.delegate = self
        tableView.dataSource = self
        // cell下部を消す
        view.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        tableView.tableFooterView = tableFooterView
        
        observeData()
    }
    
    // 参加ボタンを押した際の処理
    @IBAction func tappedJoinBottun(_ sender: UIButton) {
        // データセット作成
        let data : [String : Any] = [
            "user_id": uid as Any,
            "event_id": self.eventId as Any
        ]
        // データ保存
        let newChild = self.ref.child("event_user_join").childByAutoId()
        newChild.setValue(data)
        // サクセスアラート
        let alert = UIAlertController(title: "登録完了", message: "イベントに参加登録しました。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
  
    }
    
    // 参加しないボタン押した際の処理
    @IBAction func tappedNoJoinButton(_ sender: UIButton) {
        // 「event_user_join」テーブルからデータ削除
        self.ref.child("event_user_join").queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
            var snapArray = [DataSnapshot]()
            for snap in snapshot.children {
                snapArray.append(snap as! DataSnapshot)
                
            }
            for snap in snapArray {
                if self.eventId == snap.childSnapshot(forPath: "event_id").value as? String {
                    let key = snap.key
                    self.ref.child("event_user_join/\(key)").removeValue()
                }
            }
        })
        // サクセスアラート
        let alert = UIAlertController(title: "登録解除", message: "イベントの参加登録を解除しました。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    // お気に入りボタンを押した際の処理
    @IBAction func tappedFavoriteButton(_ sender: UIButton) {
        // データセット作成
        let data : [String : Any] = [
            "user_id": uid as Any,
            "event_id": self.eventId as Any
        ]
        // データ保存
        let newChild = self.ref.child("event_user_favorite").childByAutoId()
        newChild.setValue(data)
        // サクセスアラート
        let alert = UIAlertController(title: "登録完了", message: "イベントをお気に入り登録しました。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    // お気に入り解除ボタンを押した際の処理
    @IBAction func tappedNoFavoriteButton(_ sender: UIButton) {
        // 「event_user_join」テーブルからデータ削除
        self.ref.child("event_user_favorite").queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            var snapArray = [DataSnapshot]()
            for snap in snapshot.children {
                snapArray.append(snap as! DataSnapshot)
            }
            for snap in snapArray {
                if self.eventId == snap.childSnapshot(forPath: "event_id").value as? String {
                    let key = snap.key
                    self.ref.child("event_user_favorite/\(key)").removeValue()
                }
            }
        })
        // サクセスアラート
        let alert = UIAlertController(title: "登録解除", message: "イベントのお気に入り登録を解除しました。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    // section数の指定
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    
    // sectionタイトルの指定
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    
    // sectionあたりのcell数の指定
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 6) {
            return self.joinTableData.count
        } else {
            return 1
        }
    }
    
    // cellの組み立て
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // cellを複数行に
        cell.textLabel?.numberOfLines = 0
        
        if (indexPath.section == 0) {
            cell.textLabel?.text = self.tableData["title"] as? String
        } else if(indexPath.section == 1) {
            cell.textLabel?.text = self.tableData["detail"] as? String
        } else if(indexPath.section == 2) {
            cell.textLabel?.text = self.tableData["date"] as? String
        } else if(indexPath.section == 3) {
            cell.textLabel?.text = self.tableData["place"] as? String
        } else if(indexPath.section == 4) {
            cell.textLabel?.text =  self.tableData["tag"] as? String
        } else if(indexPath.section == 5) {
            if let joinNum = tableData["joinNum"], let limitNum = tableData["limitNum"] {
                cell.textLabel?.text = "\(joinNum)人 / \(limitNum)人"
            }
        } else if(indexPath.section == 6) {
            cell.textLabel?.text =  self.joinTableData[indexPath.row].childSnapshot(forPath: "name").value as? String
        }
        return cell
    }
    
    // eventの詳細取得
    func observeData(){
        self.defaultRef = ref.child("events")
        self.defaultRef?.observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            let detail:DataSnapshot = snapshot.childSnapshot(forPath: self.eventId!)
            self.tableData["title"] = detail.childSnapshot(forPath: "title").value as? String
            self.tableData["detail"] = detail.childSnapshot(forPath: "detail").value as? String
            self.tableData["place"] = detail.childSnapshot(forPath: "place").value as? String
            self.tableData["tag"] = detail.childSnapshot(forPath: "tag").value as? String
            self.tableData["limitNum"] = detail.childSnapshot(forPath: "limitNum").value as? String
            self.tableData["date"] = detail.childSnapshot(forPath: "date").value as? String
            
            self.joinRef = self.ref.child("event_user_join")
            self.joinRef?.queryOrdered(byChild: "event_id").queryEqual(toValue: self.eventId).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                
                // 参加者の一覧を取得
                var snapArray = [DataSnapshot]()
                var idArray: Array<Any> = []
                var array = [DataSnapshot]()
                
                // 取得データを配列に代入
                for snap in snapshot.children {
                    snapArray.append(snap as! DataSnapshot)
                }
                // 配列からuser_idを取り出す
                for snap in snapArray {
                    let id = snap.childSnapshot(forPath: "user_id").value as! String
                    idArray.append(id)
                }
                // user_idから各userの情報を取得しテーブルに反映
                for id in idArray {
                    self.ref.child("users").queryOrdered(byChild: "user_id").queryEqual(toValue: id).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                        // 取得データを配列に代入
                        for snap in snapshot.children {
                            array.append(snap as! DataSnapshot)
                        }
                        self.joinTableData = array
                        self.tableView.reloadData()
                    })
                }
                
                // 参加人数
                self.tableData["joinNum"] = snapshot.childrenCount
                self.tableView.reloadData()
            })
            self.tableView.reloadData()
        })
    }
}
