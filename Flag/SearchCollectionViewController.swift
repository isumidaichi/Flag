//
//  SearchCollectionViewController.swift
//  Flag
//
//  Created by 小川大智 on 2018/08/25.
//  Copyright © 2018年 小川大智. All rights reserved.
//

import UIKit
import FirebaseDatabase

class SearchCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var ref: DatabaseReference!
    var defaultRef: DatabaseReference?
    var tableData:[DataSnapshot] = [DataSnapshot]()
    var tag: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // DB参照
        ref = Database.database().reference()
        
        observeData()
    }

    // section数の指定
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // sectionあたりのcell数の指定
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tableData.count
    }
    
    // cellの配置調整
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width / 3.5, height: self.view.frame.size.width / 7)
    }
    
    // cellの組み立て
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> SearchCollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as! SearchCollectionViewCell
        // tagCellにDBから取得したtag名を代入
        cell.tagButton.setTitle(tableData[indexPath.item].value as? String, for: .normal)
    
        return cell
    }
    
    // ボタンが押された際の処理
    @IBAction func tappedButton(_ sender: UIButton) {
        self.tag = sender.titleLabel?.text
        performSegue(withIdentifier: "goResult", sender: nil)
    }
    
    // segue呼ばれた際の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goResult" {
            let vc = segue.destination as! SearchTableViewController
            // 遷移先の変数に受け渡しデータを代入
            vc.tag = tag!
        }
    }
    
    // DBからtagを取得
    func observeData(){
        self.defaultRef = ref.child("tags")
        defaultRef?.observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            
            var array = [DataSnapshot]()
            for item in snapshot.children {
                let child = item as? DataSnapshot
                array.append(child!)
                self.tableData = array
                self.collectionView?.reloadData()
            }
        })
    }

}
