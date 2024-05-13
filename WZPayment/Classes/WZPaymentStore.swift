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
        
    /// 获取产品列表
    public lazy var productRequest: WZSKProduct = {
        return $0
    }(WZSKProduct())
    
    /// 获取钥匙串存储
    private lazy var keych: Keychain = {
        return Keychain(service:(Bundle.main.bundleIdentifier ?? "com.wzly.payment")+".WZStore.applePay")
    }()
    
    public typealias WZPaymentSucessBlock = (_ data: WZSKModel) -> Void
    public typealias WZPaymentFailBlock = (_ error: Error) -> Void
    
    /// 购买成功回调可能包含l历史订单
    private var paySucessHandler: WZPaymentSucessBlock?

    /// 购买失败回调
    private var payFailHandler: WZPaymentFailBlock?
    
    /// 补单回调
    private var restoreHandler: ((_ datas: [WZSKModel]) -> Void)?
    
    /// 订单id
    private var currentOrderId: String?
    private var currentProductId: String?
        
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    /// 开始下单
    /// - Parameters:
    ///   - productId: 苹果内购产品id
    ///   - tradeNoId: 订单编号
    public func addPayment(productId: String, orderId: String, sucessHandler: WZPaymentSucessBlock?, failHandler: WZPaymentFailBlock?) {
        paySucessHandler = sucessHandler
        payFailHandler = failHandler
        currentOrderId = orderId
        currentProductId = productId
        
        /// 0: 检测订单id
        if orderId.count == 0 || productId.count == 0 {
            payFailHandler?(WZPaymentError.orderNil.err)
            return
        }
     
        /// 1: 检测是否开启内购
        if !SKPaymentQueue.canMakePayments() {
            payFailHandler?(WZPaymentError.NoCanPay.err)
            return
        }
        
        /// 当前有未补的单
        if payments.filter({$0.transactionId.count > 0}).count > 0 {
            payFailHandler?(WZPaymentError.history.err)
            restoreHandler?(payments)
            return
        }
        
        /// 2：找苹果下单
        productRequest.startGetProduct(productId: productId, sucessHandler: { [weak self](product) in
            guard let self = self else { return }
            
            /// 保存钥匙串订单编号
            if !self.save(data: WZSKModel(orderId: orderId, transactionId: "", productId: productId)) {
                self.payFailHandler?(WZPaymentError.orderDb.err)
                return
            }
            
            /// 支付请求
            let payment = SKMutablePayment(product: product)
            payment.applicationUsername = orderId
            SKPaymentQueue.default().add(payment)
        }) { [weak self](error) in
            guard let self = self else { return }
            self.payFailHandler?(error.customError)
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
    public func remove(key: String) {
        if let model = payments.first(where: {$0.orderId == key}), 
            let transaction = SKPaymentQueue.default().transactions.first(where: {$0.payment.productIdentifier == model.productId}) {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        try? keych.remove(key)
        if key == currentOrderId {
            currentOrderId = nil
            currentProductId = nil
        }
        debugPrint("移除本地订单：\(key)")
    }
    
    /// 补单
    public func restoreTransaction(isRefreshApple: Bool = false, restoreHandler: ((_ datas: [WZSKModel]) -> Void)?){
        self.restoreHandler = restoreHandler
        if payments.count > 0 {
            restoreHandler?(payments)
        }else{
            if isRefreshApple {
                SKPaymentQueue.default().restoreCompletedTransactions()
            }else{
                restoreHandler?(payments)
            }
        }
    }
}

/// 系统代理
extension WZPaymentStore: SKPaymentTransactionObserver  {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for (_, tran) in transactions.enumerated() {
            switch tran.transactionState {
            case .restored:
                let isSave = save(data: WZSKModel(orderId: "",
                                     transactionId: tran.transactionIdentifier ?? "",
                                     productId: tran.payment.productIdentifier,
                                     originalTransactionId: tran.original?.transactionIdentifier ?? "", price: ""))
                if isSave {
                    if tran.payment.productIdentifier == transactions.last?.payment.productIdentifier {
                        restoreHandler?(payments)
                    }
                    SKPaymentQueue.default().finishTransaction(tran)
                }else{
                    payFailHandler?(WZPaymentError.db.err)
                }
            case .failed:
                if let model = payments.first(where: {$0.orderId == currentOrderId}) {
                    remove(key: model.saveKey)
                }
                payFailHandler?(tran.error?.customError ?? SKError(_nsError: NSError(domain: "Unknown error", code: 10001)))
                SKPaymentQueue.default().finishTransaction(tran)
            case .purchased:
                
                /// 判断是否正常下单逻辑
                ///1、 applicationUsername 设置为订单编号
                ///2、applicationUsername 为空，拿到本地订单编号
                ///3、保存新的支付数据存入数据库
                
                let orderId = tran.payment.applicationUsername ?? ""
                let productId = tran.payment.productIdentifier
                let transactionId = tran.transactionIdentifier ?? ""
                let originalTransactionId = tran.original?.transactionIdentifier ?? ""
                let products = productRequest.sKProducts.first(where: {$0.productIdentifier == productId})
                let price = products?.price.stringValue ?? ""
                let currencyCode = products?.formatter.currencyCode ?? ""
                
                /// 支付数据
                var model = WZSKModel(orderId: orderId,
                                      transactionId: transactionId,
                                      productId: productId,
                                      originalTransactionId: originalTransactionId,
                                      price: price, currency: currencyCode)
                
                /// 获取本地相同订单
                if orderId.count == 0, let data = payments.first(where: {$0.productId == tran.payment.productIdentifier && $0.orderId.count > 0 && $0.transactionId.count == 0}) {
                    data.transactionId = tran.transactionIdentifier ?? ""
                    model = data
                    debugPrint("支付成功，从本地拿订单编号\(model.orderId)")
                }else{
                    debugPrint("支付成功，苹果返回订单编号\(model.orderId)")
                }
                save(data: model)
                if model.orderId == currentOrderId || (originalTransactionId.count > 0&&currentProductId == productId) {
                    paySucessHandler?(model)
                }else{
                    if tran.payment.productIdentifier == transactions.last?.payment.productIdentifier {
                        restoreHandler?(payments)
                    }
                }
                SKPaymentQueue.default().finishTransaction(tran)
            case .deferred:
                SKPaymentQueue.default().finishTransaction(tran)
            case .purchasing: break
            @unknown default: break
            }
        }
    }
}







