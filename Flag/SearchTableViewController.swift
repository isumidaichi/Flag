//
//  SearchTableViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SearchTableViewController: UITableViewController {
    
    let uid = Auth.auth().currentUser?.uid
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var tableData:[DataSnapshot] = [DataSnapshot]()
    var eventId: String?
    var tag: String?
    @IBAction func unwindEvent(segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // DB参照
        ref = Database.database().reference()
        
        // tableviewの設定
        tableView.rowHeight = 100
        // cell下部を消す
        view.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        tableView.tableFooterView = tableFooterView
        
        observeData(tag!)
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
        
        let titleLabel = cell.viewWithTag(1) as? UILabel
        let dateLabel = cell.viewWithTag(2) as? UILabel
        let placeLabel = cell.viewWithTag(3) as? UILabel
        
        titleLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "title").value as? String
        dateLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "date").value as? String
        placeLabel?.text = self.tableData[indexPath.row].childSnapshot(forPath: "place").value as? String
        
        return cell
    }
    
    // cellが選択された場合
    override func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        eventId = self.tableData[indexPath.row].key
        if validateHost(eventId!) == "host" {
            performSegue(withIdentifier: "goManage",sender: nil)
        } else {
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
    
    // ホストイベントか否かの判別
    func validateHost(_ event_id: String) -> String {
        self.defaultRef = ref.child("event_user_host")
        defaultRef?.queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observeSingleEvent(of: DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            guard snapshot.exists() else {
                return
            }
            
            var array = [DataSnapshot]()
            for snap in snapshot.children {
                array.append(snap as! DataSnapshot)
            }
            for snap in array {
                guard (event_id == snap.childSnapshot(forPath: "event_id").key) else {
                    return
                }
            }
        })
        return "host"
    }
    
    // 検索処理
    func observeData(_ searchQuery: String) {
        // 「events」テーブルからクエリに一致するtagを持つイベントの取得
        self.defaultRef = ref.child("events")
        defaultRef?.queryOrdered(byChild: "tag").queryEqual(toValue: searchQuery).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            // 空の場合は空テーブルを表示
            guard snapshot.exists() else {
                let alert = UIAlertController(title: "Not Found", message: "検索語句に一致するイベントは見つかりませんでした。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            var snapArray = [DataSnapshot]()
            var idArray: Array<Any> = []
            var array = [DataSnapshot]()
            
            // 取得データを配列に代入
            for snap in snapshot.children {
                snapArray.append(snap as! DataSnapshot)
            }
            // 配列からeventのidを取り出す
            for snap in snapArray {
                let id = snap.key
                idArray.append(id)
            }
            // event_idから各eventの情報を取得しテーブルに反映
            for id in idArray {
                self.ref.child("events").child(id as! String).observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
                    array.append(snapshot)
                    self.tableData = array
                    self.tableView.reloadData()
                })
            }
        })
    }
    
}
