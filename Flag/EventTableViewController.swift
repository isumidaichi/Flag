//
//  EventTableViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EventTableViewController: UITableViewController {
    
    let uid = Auth.auth().currentUser?.uid
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var tableData:[DataSnapshot] = [DataSnapshot]()
    var eventId: String?
    @IBAction func unwindEvent(segue: UIStoryboardSegue) {
    }
    @IBOutlet weak var logInButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ログイン確認
        if Auth.auth().currentUser == nil {
            // ボタン非表示
            logInButton.isEnabled = false
            logInButton.tintColor = UIColor.clear
        }
        
        // DB参照
        ref = Database.database().reference()
        // tableviewの設定
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        // cell下部を消す
        view.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        tableView.tableFooterView = tableFooterView
        
        observeData()
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
        validateHost(eventId!)
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
    
    // ホストか否かの判別
    func validateHost(_ event_id: String) {
        self.defaultRef = ref.child("event_user_host")
        defaultRef?.queryOrdered(byChild: "user_id").queryEqual(toValue: uid).observeSingleEvent (of: DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            guard snapshot.exists() else {
                self.checkHost(false)
                return
            }
            
            var array = [DataSnapshot]()
            
            for snap in snapshot.children {
                array.append(snap as! DataSnapshot)
            }
            
            for snap in array {
                if snap.childSnapshot(forPath: "event_id").value as? String == self.eventId {
                    self.checkHost(true)
                    return
                }
            }
            self.checkHost(false)
        })
    }
    // 判別に基づいた画面繊維
    func checkHost(_ host: Bool) {
        if host {
            performSegue(withIdentifier: "goManage",sender: nil)
        } else {
            performSegue(withIdentifier: "goDetail",sender: nil)
        }
    }
    
    // eventデータの取得
    func observeData(){
        self.defaultRef = ref.child("events")
        self.defaultRef?.observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            var array = [DataSnapshot]()
            for item in snapshot.children {
                let child = item as! DataSnapshot
                array.append(child)
            }
            self.tableData = array.reversed()
            self.tableView.reloadData()
        })
    }

}
