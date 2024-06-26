//
//  ViewController.swift
//  WZPayment
//
//  Created by ppqx on 07/28/2020.
//  Copyright (c) 2020 ppqx. All rights reserved.
//

import UIKit
import RxSwift
import WZPayment
import WZRxExtension
import WZProgressHUD
import WZNetworks
import Moya

public class ViewController: UIViewController {
    
    /// 产品id
    public var dataList: [String] = ["funfun_text_recharge_10000coins", "funfun_text_recharge_1800coins", "com.temtuux.1000", "2023120301", "2023120306", "2023120307"]
    
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
        
        WZPaymentStore.default.restoreTransaction { datas in
            datas.forEach {
                WZPaymentStore.default.remove(key: $0.orderId)
            }
        }
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
        
        let model = dataList[indexPath.row]
        WZProgressHUD.show()
//        let xx = \(arc4random_uniform(10199993))
        pay(orderId: "1739545410286882817", productId: model)
            .flatMap{ result in
                return PayApi.upload(orderId: result.orderId, transactionId: result.transactionId, productId: result.productId, originalTransactionId: result.originalTransactionId, receipt: result.receipt, price: result.price)
                    .request()
                    .mapSuccess(isDebug: true)
                    .map { _ in
                        WZPaymentStore.default.remove(key: result.orderId)
                    }
            }
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                WZProgressHUD.dismiss()
            }, onError: { (error) in
                WZProgressHUD.showError(withStatus: error.localizedDescription)
            }).disposed(by: rx.disposeBag)
    }
    
    /// 内购支付
    private func pay(orderId: String, productId: String) -> Observable<WZSKModel> {
        return Observable.create { (observable) -> Disposable in
            WZPaymentStore.default.addPayment(productId: productId, orderId: orderId, atomically: false) { model in
                observable.onNext((model))
                observable.onCompleted()
            } failHandler: { error in
                observable.onError(error)
                observable.onCompleted()
            }
            return Disposables.create {}
        }
    }
}





