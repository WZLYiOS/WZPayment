//
//  ViewController.swift
//  WZPayment
//
//  Created by ppqx on 07/28/2020.
//  Copyright (c) 2020 ppqx. All rights reserved.
//

import UIKit
import WZPayment

public class ViewController: UIViewController {

    ///
    private lazy var paymentStore: WZPaymentStore = {
        return $0
    }(WZPaymentStore())
    
    /// 产品id
    public var dataList: [String] = ["a", "aa", "3333", "rrrrr"]
    
    /// 表格
    private lazy var tableView: UITableView = {
        $0.delegate = self
        $0.dataSource = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return $0
    }(UITableView())
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.frame = view.bounds
    }
}

// MARK - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = dataList[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        paymentStore.addPayment(productId: dataList[indexPath.row], orderId: "838383838") { (result) in
            
        } failHandler: { (error) in
            debugPrint(error.localizedDescription)
        }
    }
}




