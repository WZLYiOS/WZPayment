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
        
    public static let `default`: WZPaymentStore = {
        return $0
    }(WZPaymentStore())
    
    /// 获取产品列表
    public lazy var productRequest: WZSKProduct = {
        return $0
    }(WZSKProduct())
    
    /// 获取钥匙串存储
    private lazy var keych: Keychain = {
        return Keychain(service:(Bundle.main.bundleIdentifier ?? "com.wzly.payment")+".WZStore.applePay")
    }()
    
    /// 补单回调
    private var restoreHandler: ((_ datas: [WZSKModel]) -> Void)?
    
    /// 当前支付
    private var paymentArray: [WZMutablePayment] = []
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }

    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    /// 开始下单
    /// - Parameters:
    ///   - productId: 苹果内购产品id
    ///   - tradeNoId: 订单编号
    public func addPayment(productId: String,
                           orderId: String,
                           atomically: Bool = true,
                           sucessHandler: ((_ data: WZSKModel) -> Void)?,
                           failHandler: ((_ error: Error) -> Void)?) {
      
        
        /// 0: 检测订单id
        if orderId.count == 0 || productId.count == 0 {
            failHandler?(WZPaymentError.orderNil.err)
            return
        }
     
        /// 1: 检测是否开启内购
        if !SKPaymentQueue.canMakePayments() {
            failHandler?(WZPaymentError.NoCanPay.err)
            return
        }
        
        /// 当前有未补的单
        if getDBPayments().filter({$0.transactionId.count > 0}).count > 0 {
            failHandler?(WZPaymentError.history.err)
            restoreHandler?(getDBPayments())
            return
        }
        
        /// 2：找苹果下单
        productRequest.startGetProduct(productId: productId, sucessHandler: { [weak self](product) in
            guard let self = self else { return }
            
            /// 保存钥匙串订单编号
            if !self.save(data: WZSKModel(orderId: orderId, transactionId: "", productId: productId)) {
                failHandler?(WZPaymentError.orderDb.err)
                return
            }
            
            /// 支付请求
            let payment = WZMutablePayment(product: product, orderId: orderId, atomically: atomically) { result in
                
                switch result {
                case let .failed(error):
                        failHandler?(error)
                case let .purchased(data):
                    sucessHandler?(data)
                case let .restored(data):
                    sucessHandler?(data)
                default:
                    break
                }
            }
            SKPaymentQueue.default().add(payment.pay)
            paymentArray.append(payment)
        }) { (error) in
            failHandler?(error.customError)
        }
    }
}

// MARK - 扩展
extension WZPaymentStore {
    
    /// 保存
    @discardableResult
    private func save(data: WZSKModel) -> Bool {
        guard let jsonData = try? JSONEncoder().encode(data), let _ = try? keych.set(jsonData, key: data.orderId) else {
            debugPrint("添加本地订单失败：\(data.orderId)")
            return false
        }
        debugPrint("添加本地订单成功：\(data.orderId)")
        return true
    }
    
    /// 获取本地订单
    public func getDBPayments() -> [WZSKModel] {
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
        if let model = getDBPayments().first(where: {$0.orderId == key}),
            let transaction = SKPaymentQueue.default().transactions.first(where: {$0.payment.productIdentifier == model.productId}) {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        try? keych.remove(key)
        debugPrint("移除本地订单：\(key)")
    }
    
    /// 补单
    public func restoreTransaction(isRefreshApple: Bool = false, restoreHandler: ((_ datas: [WZSKModel]) -> Void)?){
        self.restoreHandler = restoreHandler
        let payments = getDBPayments()
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
    
    /// 获取沙河中凭证
    static public var receipt: String {
        let base64String = receiptData?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
        return base64String
    }
    
    /// 支付凭证
    static public var receiptData: Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        let receiptData = try? Data(contentsOf: url)
        return receiptData
    }
}

/// 系统代理
extension WZPaymentStore: SKPaymentTransactionObserver  {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        /// 获取正常支付中的
        let processTransactions = transactions.filter {!processTransaction($0, paymentQueue: queue)}
        
        /// 回调补单的
        restoreCompletedTransactions(processTransactions, paymentQueue: queue)
    }
}

extension WZPaymentStore {
        
    /// 获取
    private func findPaymentIndex(tran: SKPaymentTransaction) -> Int? {
        return paymentArray.firstIndex(where: {$0.product.productIdentifier == tran.payment.productIdentifier})
    }
    
    /// 完成交易
    private func processTransaction(_ tran: SKPaymentTransaction, paymentQueue: SKPaymentQueue) -> Bool {
        
        guard let index = findPaymentIndex(tran: tran) else {
            return false
        }
        let payment = paymentArray[index]
        let orderId = tran.payment.applicationUsername ?? payment.orderId
        let productId = tran.payment.productIdentifier
        let transactionId = tran.transactionIdentifier ?? ""
        let originalTransactionId = tran.original?.transactionIdentifier ?? ""
        let price = payment.product.price.stringValue
        let currencyCode = payment.product.formatter.currencyCode ?? ""
        
        /// 支付数据
        let model = WZSKModel(orderId: orderId,
                              transactionId: transactionId,
                              productId: productId,
                              originalTransactionId: originalTransactionId,
                              price: price, currency: currencyCode)
        
        switch tran.transactionState {
        case .purchased:

            /// 把支付记录保存本地
            save(data: model)
            if payment.atomically {
                paymentQueue.finishTransaction(tran)
            }
            payment.callback(.purchased(purchase: model))
            paymentArray.remove(at: index)
            return true
        case .failed:
            let message = "Unknown error"
            let altError = NSError(domain: SKErrorDomain, code: SKError.unknown.rawValue, userInfo: [NSLocalizedDescriptionKey: message ])
            let nsError = tran.error ?? altError
            paymentQueue.finishTransaction(tran)
            remove(key: orderId)
            payment.callback(.failed(error: nsError.customError))
            paymentArray.remove(at: index)
            return true
        case .restored:
            if payment.atomically {
                paymentQueue.finishTransaction(tran)
            }
            if originalTransactionId.count > 0 {
                model.transactionId = originalTransactionId
            }
            save(data: model)
            payment.callback(.purchased(purchase: model))
            paymentArray.remove(at: index)
            return true
        case .deferred:
            remove(key: orderId)
            payment.callback(.deferred(purchase: model))
            paymentArray.remove(at: index)
            return true
        default:
            return false
        }
    }
    
    /// 去重，并取最新的
    private func removeDuplicates(inputArray: [SKPaymentTransaction]) -> [SKPaymentTransaction] {
        let tempArray = inputArray
        var result: [SKPaymentTransaction] = []
        
        /// 反转一下取最近的
        for item in tempArray.reversed() {
            if !result.contains(where: {$0.payment.productIdentifier == item.payment.productIdentifier}) {
                result.append(item)
            }
        }
        return result
    }
    
    /// 补单
    private func restoreCompletedTransactions(_ trans: [SKPaymentTransaction], paymentQueue: SKPaymentQueue) {
        
        let personsArray = removeDuplicates(inputArray: trans.filter({$0.transactionState != .purchasing}))
        if personsArray.count == 0 {
            return
        }
        
        /// 获取商品
        productRequest.requestProducts(products: personsArray.map({$0.payment.productIdentifier})) { [self] products in
            
            /// 系统补单不存入db
            let results = personsArray.map { tran in
                let orderId = tran.payment.applicationUsername ?? ""
                let productId = tran.payment.productIdentifier
                let transactionId = tran.transactionIdentifier ?? ""
                let originalTransactionId = tran.original?.transactionIdentifier ?? ""
                let product = productRequest.sKProducts.first(where: {$0.productIdentifier == tran.payment.productIdentifier})
                let price = product?.price.stringValue ?? ""
                let currencyCode = product?.formatter.currencyCode ?? ""
                
                /// 本地查下订单有无为完成的单
                if let m = getDBPayments().first(where: {$0.orderId == orderId}) {
                    m.transactionId = transactionId
                    m.originalTransactionId = originalTransactionId
                    m.price = price
                    m.currency = currencyCode
                    return m
                }
                
                /// 支付数据
                let model = WZSKModel(orderId: orderId,
                                      transactionId: transactionId,
                                      productId: productId,
                                      originalTransactionId: originalTransactionId,
                                      price: price, currency: currencyCode)
                return model
            }
            personsArray.forEach {
                paymentQueue.finishTransaction($0)
            }
            restoreHandler?(results)
        } failHandler: { error in
            self.restoreHandler?([])
        }
    }
}

// MARK - 支付列表
public class WZMutablePayment: NSObject {
    
    public enum TransactionResult {
        case purchased(purchase: WZSKModel)
        case restored(purchase: WZSKModel)
        case deferred(purchase: WZSKModel)
        case failed(error: Error)
    }
    
    // 回调
    let callback: (TransactionResult) -> Void
    
    /// 购买记录
    let product: SKProduct
    
    /// 支付
    let pay: SKMutablePayment
    
    /// 订单编号
    let orderId: String
    
    /// 是否自动结单
    let atomically: Bool
    
    init(product: SKProduct, orderId: String, atomically: Bool,callback: @escaping (TransactionResult) -> Void) {
        self.callback = callback
        self.product = product
        self.pay = SKMutablePayment(product: product)
        self.orderId = orderId
        self.atomically = atomically
        super.init()
        self.pay.applicationUsername = orderId
    }
}
