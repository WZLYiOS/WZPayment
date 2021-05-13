//
//  WZSKPaymentStore.swift
//  WZSKPayment
//
//  Created by qiuqixiang on 2020/3/16.
//  Copyright © 2020 我主良缘. All rights reserved.
//

/* 支付流程：
  1：服务端获取订单编号 -> 2：向苹果请求产品id，并缓存 -> 3：向苹果发起购买 -> 4：上传支付凭证并校验
  丢单情况：
  1、APP外支付成功，未回调给APP，下次启动，会自动返回
  2、支付成功/支付失败APP已奔溃
  3、上传凭证失败
 */

import Foundation
import StoreKit
import KeychainAccess

// MAKR - 内购控制
public class WZPaymentStore: NSObject {
    
    /// 代理
    weak var delegate: WZPaymentStoreDelegate?
    
    /// 获取产品列表
    public lazy var productRequest: WZSKProduct = {
        return $0
    }(WZSKProduct())
    
    /// 获取钥匙串存储
    private lazy var keych: Keychain = {
        return Keychain(service:Bundle.main.bundleIdentifier ?? "com.wzly.payment"+".WZStore.applePay")
    }()
    
    typealias PaySucessBlock = (_ data: WZSKModel) -> Void
    typealias PayFailBlock = (_ error: Error) -> Void
    
    /// 购买成功回调可能包含l历史订单
    private var paySucessHandler: PaySucessBlock?

    /// 购买失败回调
    private var payFailHandler: PayFailBlock?
        
    init(cDlegate: WZPaymentStoreDelegate) {
        super.init()
        delegate = cDlegate
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    /// 开始下单
    /// - Parameters:
    ///   - productId: 苹果内购产品id
    ///   - tradeNoId: 订单编号
    func addPayment(productId: String, orderId: String, sucessHandler: PaySucessBlock?, failHandler: PayFailBlock?) {
        paySucessHandler = sucessHandler
        payFailHandler = failHandler
        
        /// 0: 检测订单id
        if productId.isEmpty || orderId.isEmpty {
            payFailHandler?(SKError.ErrorType.order.error())
            return
        }
        
        /// 1: 检测是否开启内购
        if !SKPaymentQueue.canMakePayments() {
            payFailHandler?(SKError.ErrorType.canPay.error())
            return
        }
        
        /// 2：检测是否有历史订单未完结，如果有，直接上传此订单
        if let model = payments.filter({$0.transactionId.count>0}).first {
            callBackPaySucess(data: model)
            return
        }
        
        /// 3：找苹果下单
        productRequest.startGetProduct(productId: productId, sucessHandler: { [weak self](product) in
            guard let self = self else { return }
            
            /// 保存钥匙串订单编号
            self.save(data: WZSKModel(orderId: orderId, transactionId: "", productId: productId))
            let payment = SKMutablePayment(product: product)
            payment.applicationUsername = orderId
            SKPaymentQueue.default().add(payment)
        }) { [weak self](error) in
            guard let self = self else { return }
            self.callBackPayFail(error: error)
        }
    }
}

// MARK - 扩展
extension WZPaymentStore {
    
    /// 保存
    @discardableResult
    private func save(data: WZSKModel) -> Bool {

        guard let jsonData = try? JSONEncoder().encode(data), let _ = try? keych.set(jsonData, key: data.saveKey) else {
            debugPrint("添加本地订单失败：\(data.saveKey)")
            return false
        }
        debugPrint("添加本地订单成功：\(data.saveKey)")
        return true
    }
    
    /// 获取支付数据
    public var payments: [WZSKModel] {
        var list: [WZSKModel] = []
        for key in keych.allKeys() {
            if let data =  try? keych.getData(key),
               let model = try? JSONDecoder().decode(WZSKModel.self, from: data) {
                list.append(model)
            }
        }
        return list
    }
    
    /// 移除本地订单
    func remove(data: WZSKModel) {
        try? keych.remove(data.saveKey)
        debugPrint("移除本地订单：\(data.saveKey)")
    }
    
    /// 支付成功回调
    private func callBackPaySucess(data: WZSKModel) {
        if paySucessHandler != nil, data.orderId.count > 0 {
            paySucessHandler?(data)
            return
        }
        delegate?.paymentStore(strore: self, data: data)
    }
    
    /// 支付失败回调
    private func callBackPayFail(error: Error)  {
        payFailHandler?(error)
    }
}

/// 系统代理
extension WZPaymentStore: SKPaymentTransactionObserver  {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    
        /// 按照时间排序
        let tranList = transactions.sorted(by: { (a, b) -> Bool in
            return a.transactionDate?.compare(b.transactionDate!) == .orderedDescending
        })
    
        for tran in tranList {
            switch tran.transactionState {
            case .restored:
                SKPaymentQueue.default().finishTransaction(tran)
            case .failed:
                
                if let model = payments.filter({$0.productId == tran.payment.productIdentifier}).first {
                    remove(data: model)
                }
                callBackPayFail(error: tran.error ?? SKError.ErrorType.fail.error())
                SKPaymentQueue.default().finishTransaction(tran)
            case .purchased:
                
                /// 判断是否正常下单逻辑
                ///1、 applicationUsername 设置为订单编号
                ///2、applicationUsername 为空，拿到本地订单编号
                ///3、保存新的支付数据存入数据库
        
                /// 支付数据
                let paymentModel = WZSKModel(orderId: tran.payment.applicationUsername ?? "", transactionId: tran.transactionIdentifier ?? "", productId: tran.payment.productIdentifier, originalTransactionId: tran.original?.transactionIdentifier)
                if paymentModel.orderId.isEmpty,
                   let model = payments.filter({$0.productId == tran.payment.productIdentifier}).first,
                   model.orderId.count > 0 {
                    paymentModel.orderId = model.orderId
                    debugPrint("支付成功，从本地拿订单编号\(model.orderId)")
                }else{
                    debugPrint("支付成功，苹果返回订单编号\(paymentModel.orderId)")
                }
                save(data: paymentModel)
                callBackPaySucess(data: paymentModel)
                SKPaymentQueue.default().finishTransaction(tran)
            case .deferred:
                SKPaymentQueue.default().finishTransaction(tran)
            case .purchasing: break
            @unknown default: break
            }
        }
    }
}

// MARK - WZSKPaymentStoreDelegate
protocol WZPaymentStoreDelegate: class {
    
    /// 补单回调
    /// - Parameters:
    ///   - strore: 管理
    ///   - transId: 苹果订单
    ///   - orderId: 订单
    ///   - productId: 产品id
    func paymentStore(strore: WZPaymentStore, data: WZSKModel)
}





