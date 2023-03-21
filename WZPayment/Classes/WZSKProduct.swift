//
//  WZSKProduct.swift
//  WZPayment
//
//  Created by qiuqixiang on 2021/5/13.
//

import Foundation
import StoreKit

// MARK - 获取苹果产品id请求
public class WZSKProduct: NSObject, SKProductsRequestDelegate {
    
    typealias ProductSucessBlock = (_ products: SKProduct) -> Void
    typealias productFailBlock = (_ error: Error) -> Void
    
    /// 当前产品id列表
    public var sKProducts: [SKProduct] = []
    
    /// 成功请求数据
    private var productSucessHandler: ProductSucessBlock?
    
    /// 请求失败
    private var productFailHandler: productFailBlock?
    
    /// 请求类
    var productsRequest: SKProductsRequest?
    
    func startGetProduct(productId: String, sucessHandler: ProductSucessBlock?, failHandler: productFailBlock?) {
        productSucessHandler = sucessHandler
        productFailHandler = failHandler
        
        guard let product = sKProducts.filter({$0.productIdentifier == productId}).first else {
            requestProducts(products: [productId])
            return
        }
        productSucessHandler?(product)
    }
    
    /// 获取产品列表
    func requestProducts(products: [String]) {
        
        let productArr: Array<String> = products
        let sets:Set<String> = NSSet.init(array: productArr) as! Set<String>
        productsRequest = SKProductsRequest(productIdentifiers: sets)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// SKProductsRequestDelegate
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count == 0 {
            let err = NSError(domain: "未获取到该产品", code: 100020, userInfo: nil)
            productFailHandler?(err)
            return
        }
        sKProducts.append(contentsOf: response.products)
        productSucessHandler?(response.products.first!)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productFailHandler?(error)
    }
}

// MARK - 数据模型
public class WZSKModel: Codable {
    
    /// 订单id
    public var orderId: String
    
    /// 苹果支付id
    public var transactionId: String
    
    /// 产品id
    public let productId: String

    /// 原始id
    public var originalTransactionId: String?
    
    init(orderId: String, transactionId: String, productId: String, originalTransactionId: String? = nil) {
        self.orderId = orderId
        self.transactionId = transactionId
        self.productId = productId
        self.originalTransactionId = originalTransactionId
    }
    
    enum CodingKeys: String, CodingKey {
        case orderId = "orderId"
        case transactionId = "transactionId"
        case productId = "productId"
        case originalTransactionId = "originalTransactionId"
    }
    
    /// 获取沙河中凭证
    public var receipt: String {
        let base64String = receiptData?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
        return base64String
    }
    
    /// 支付凭证
    public var receiptData: Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        let receiptData = try? Data(contentsOf: url)
        return receiptData
    }
    
    /// 保存钥匙串的key
    public var saveKey: String {
        let orderKey = "com.wzly.keych.order."
        if orderId.count > 0 {
            return orderKey+orderId
        }
        return orderKey+"transactionId"+transactionId
    }
}

