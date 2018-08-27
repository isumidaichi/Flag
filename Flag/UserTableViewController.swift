//
//  UserTableViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class UserTableViewController: UITableViewController {
    
    let user = Auth.auth().currentUser
    let uid = Auth.auth().currentUser?.uid
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var hostTableData:[DataSnapshot] = [DataSnapshot]()
    var joinTableData:[DataSnapshot] = [DataSnapshot]()
    var eventId: String?
    var registerNum = 0
    let sectionTitle = ["開催予定", "参加予定"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // DB参照
        ref = Database.database().reference()
        // tableviewの設定
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        // 空のcellを消す
        view.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        tableView.tableFooterView = tableFooterView
        // ユーザー情報の表示
        if let name = user?.displayName {
            self.navigationItem.title = "\(name)のページ"
        }
        
        observeHostData()
        observeJoinData()
    }
    
    // ログアウトボタンの処理
    @IBAction func tappedLogoutButton(_ sender: UIButton) {
        _ = try? Auth.auth().signOut()
        let next = storyboard!.instantiateViewController(withIdentifier: "Login")
        self.present(next,animated: true, completion: nil)
    }
    
    // 退会ボタンの処理
    @IBAction func tappedQuitButton(_ sender: UIButton) {
        // 退会確認アラート
        let alert = UIAlertController(title: "退会確認", message: "退会手続きをされますと、サービス利用のために再度登録が必要になります。本当に退会してよろしいですか？", preferredStyle: .alert)
        // 退会処理
        let ok = UIAlertAction(title: "退会", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            let user = Auth.auth().currentUser
            
            user?.delete { error in
                if error != nil {
                    let alert = UIAlertController(title: "エラー", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // 削除完了
                    // 「events」「event_user_host」テーブルからデータ削除
                    self.ref.child("event_user_host").queryOrdered(byChild: "user_id").queryEqual(toValue: self.uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                        
                        var snapArray = [DataSnapshot]()
                        var idArray: Array<Any> = []
                        
                        for snap in snapshot.children {
                            snapArray.append(snap as! DataSnapshot)
                        }
                        // 配列からevent_idを取り出す
                        for snap in snapArray {
                            let id = snap.childSnapshot(forPath: "event_id").value as! String
                            idArray.append(id)
                        }
                        // event_idから各eventの情報を取得し削除
                        for id in idArray {
                            self.ref.child("events").child(id as! String).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                                let key = snapshot.key
                                self.ref.child("events/\(key)").removeValue()
                            })
                        }
                        // 「event_user_host」テーブルからデータ削除
                        for snap in snapArray {
                            let key = snap.key
                            self.ref.child("event_user_host/\(key)").removeValue()
                        }
                    })
                    
                    // 「event_user_join」テーブルからデータ削除
                    self.ref.child("event_user_join").queryOrdered(byChild: "user_id").queryEqual(toValue: self.uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                        
                        var snapArray = [DataSnapshot]()
                        for snap in snapshot.children {
                            snapArray.append(snap as! DataSnapshot)
                        }
                        for snap in snapArray {
                            let key = snap.key
                            self.ref.child("event_user_join/\(key)").removeValue()
                        }
                    })
                    // 「event_user_favorite」テーブルからデータ削除
                    self.ref.child("event_user_favorite").queryOrdered(byChild: "user_id").queryEqual(toValue: self.uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                        
                        var snapArray = [DataSnapshot]()
                        for snap in snapshot.children {
                            snapArray.append(snap as! DataSnapshot)
                        }
                        for snap in snapArray {
                            let key = snap.key
                            self.ref.child("event_user_favorite/\(key)").removeValue()
                        }
                    })
                    
                    // ログイン画面に戻る
                    let next = self.storyboard!.instantiateViewController(withIdentifier: "Login")
                    self.present(next,animated: true, completion: nil)
                }
            }
        }
        
        let cancel = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
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
        if (section == 0) {
            return self.hostTableData.count
        } else {
            return self.joinTableData.count
        }
    }
    
    // cellの組み立て
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        
        let titlelabel = cell.viewWithTag(1) as? UILabel
        let dateLabel = cell.viewWithTag(2) as? UILabel
        let placelabel = cell.viewWithTag(3) as? UILabel
        let joinCanLabel = cell.viewWithTag(4) as? UILabel
        var limitNum: String?
        
        if (indexPath.section == 0){
            titlelabel?.text = self.hostTableData[indexPath.row].childSnapshot(forPath: "title").value as? String
            dateLabel?.text = self.hostTableData[indexPath.row].childSnapshot(forPath: "date").value as? String
            placelabel?.text = self.hostTableData[indexPath.row].childSnapshot(forPath: "place").value as? String
            joinCanLabel?.isHidden = true
            
        } else {
            titlelabel?.text = self.joinTableData[indexPath.row].childSnapshot(forPath: "title").value as? String
            dateLabel?.text = self.joinTableData[indexPath.row].childSnapshot(forPath: "date").value as? String
            placelabel?.text = self.joinTableData[indexPath.row].childSnapshot(forPath: "place").value as? String
            // 参加可否の表示
            limitNum = self.joinTableData[indexPath.row].childSnapshot(forPath: "limitNum").value as? String
            if let limitNum = limitNum {
                if let limitNum = Int(limitNum) {
                    if self.registerNum <= limitNum {
                        joinCanLabel?.isHidden = false
                        joinCanLabel?.text = "参加できます"
                    } else {
                        joinCanLabel?.isHidden = false
                        joinCanLabel?.text = "キャンセル待ちです"
                    }                    
                }
            }
        }
        return cell
    }
    
    // ホストイベントのみ編集モードオンに
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return true
        }
        return false
    }
    
    // cellの削除機能
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            eventId = self.hostTableData[indexPath.row].key
            // 「events」テーブルからデータ削除
            if let key = eventId {
                self.ref.child("events/\(key)").removeValue()
            }
            // 「event_user_host」テーブルからデータ削除
            self.ref.child("event_user_host").queryOrdered(byChild: "event_id").queryEqual(toValue: eventId).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                
                var snapArray = [DataSnapshot]()
                for snap in snapshot.children {
                    snapArray.append(snap as! DataSnapshot)
                }
                for snap in snapArray {
                    let key = snap.key
                    self.ref.child("event_user_host/\(key)").removeValue()
                }
            })
            // 「event_user_join」テーブルからデータ削除
            self.ref.child("event_user_join").queryOrdered(byChild: "event_id").queryEqual(toValue: eventId).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                
                var snapArray = [DataSnapshot]()
                for snap in snapshot.children {
                    snapArray.append(snap as! DataSnapshot)
                }
                for snap in snapArray {
                    let key = snap.key
                    self.ref.child("event_user_join/\(key)").removeValue()
                }
            })
            // 「event_user_favorite」テーブルからデータ削除
            self.ref.child("event_user_favorite").queryOrdered(byChild: "event_id").queryEqual(toValue: eventId).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
                
                var snapArray = [DataSnapshot]()
                for snap in snapshot.children {
                    snapArray.append(snap as! DataSnapshot)
                }
                for snap in snapArray {
                    let key = snap.key
                    self.ref.child("event_user_favorite/\(key)").removeValue()
                }
            })
            // cell削除
            hostTableData.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    // cellが選択された場合
    override func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            eventId = self.hostTableData[indexPath.row].key
            performSegue(withIdentifier: "goManage",sender: nil)
        } else {
            eventId = self.joinTableData[indexPath.row].key
            performSegue(withIdentifier: "goDetail",sender: nil)
        }
    }
    
    // segue呼ばれた際の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goManage" {
            let HostTableViewController: HostTableViewController = segue.destination as! HostTableViewController
            HostTableViewController.eventId = self.eventId!
        } else if segue.identifier == "goDetail" {
            let DetailTableViewController: DetailTableViewController = segue.destination as! DetailTableViewController
            DetailTableViewController.eventId = self.eventId!
        }
    }
    
    // 作成したイベントを取得
    func observeHostData(){
        // 「event_user_host」テーブルからevent_idの取得
        self.defaultRef = ref.child("event_user_host")
        defaultRef?.queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            // 空の場合は空テーブルを表示
            guard snapshot.exists() else{
                self.hostTableData = []
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
                    self.hostTableData = array.reversed()
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    // 参加予定のイベントを取得
    func observeJoinData(){
        // 「event_user_join」テーブルからevent_idの取得
        self.defaultRef = ref.child("event_user_join")
        defaultRef?.queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            // 空の場合は空テーブルを表示
            guard snapshot.exists() else {
                self.joinTableData = []
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
                    self.joinTableData = array.reversed()
                    self.tableView.reloadData()
                })
            }
            
            // 参加可能かチェック
            for id in idArray {
                // 「event_user_join」テーブルからevent_idの取得
                self.ref.child("event_user_join").queryOrdered(byChild: "event_id").queryEqual(toValue: id).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                    // 空の場合は終了
                    guard snapshot.exists() else {
                        return
                    }
                    
                    var snapArray = [DataSnapshot]()
                    var num = 0
                    
                    // 取得データを配列に代入
                    for snap in snapshot.children {
                        snapArray.append(snap as! DataSnapshot)
                    }
                    // 配列の順番から何番目に登録したか判別
                    for snap in snapArray {
                        num += 1
                        if self.uid == snap.childSnapshot(forPath: "user_id").value as? String {
                            self.registerNum = num
                            self.tableView.reloadData()
                            break
                        }
                    }
                })
            }
        })
    }
}
