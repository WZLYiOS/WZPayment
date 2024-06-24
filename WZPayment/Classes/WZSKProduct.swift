//
//  WZSKProduct.swift
//  WZPayment
//
//  Created by qiuqixiang on 2021/5/13.
//

import Foundation
import StoreKit

// MARK - 获取苹果产品id请求
public class WZSKProduct: NSObject {
    
    public typealias ProductSucessBlock = (_ products: [SKProduct]) -> Void
    public typealias productFailBlock = (_ error: Error) -> Void
    
    /// 当前产品id列表
    public var sKProducts: [SKProduct] = []
    
    /// 成功请求数据
    private var productSucessHandler: ProductSucessBlock?
    
    /// 请求失败
    private var productFailHandler: productFailBlock?
    
    /// 请求类
    private var productsRequest: SKProductsRequest?
    
    /// 获取产品信息
    public func startGetProduct(productId: String, sucessHandler: ((_ products: SKProduct) -> Void)?, failHandler: productFailBlock?) {
        
        /// 获取支付
        guard let product = sKProducts.filter({$0.productIdentifier == productId}).first else {
            requestProducts(products: [productId], sucessHandler: { products in
                sucessHandler?(products.first!)
            }, failHandler: failHandler)
            return
        }
        sucessHandler?(product)
    }
    
    /// 获取产品列表
    public func requestProducts(products: [String], sucessHandler: ProductSucessBlock?, failHandler: productFailBlock?) {
        productSucessHandler = sucessHandler
        productFailHandler = failHandler
        
        let productArr: Array<String> = products
        let sets:Set<String> = NSSet.init(array: productArr) as! Set<String>
        
        /// 判断本地是否有
        let tem = sets.map({$0})
        let arr = sKProducts.filter { product in
            tem.contains { $0 == product.productIdentifier }
        }
        if arr.count == sets.count {
            sucessHandler?(arr)
            return
        }
        productsRequest = SKProductsRequest(productIdentifiers: sets)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// 获取商品
    func getProduct(product: String, comple: ((_ result: SKProduct?)-> Void)? = nil) {
        startGetProduct(productId: product) { products in
            comple?(products)
        } failHandler: { error in
            comple?(nil)
        }
    }
}

/// MARK - SKProductsRequestDelegate
extension WZSKProduct: SKProductsRequestDelegate {
    /// SKProductsRequestDelegate
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            if response.products.count == 0 {
                self.productFailHandler?(WZPaymentError.notproduct.err)
                return
            }
            
            /// 先去重再添加
            response.products.forEach { value in
                self.sKProducts.removeAll(where: {$0.productIdentifier == value.productIdentifier})
            }
            self.sKProducts.append(contentsOf: response.products)
            self.productSucessHandler?(response.products)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productFailHandler?(WZPaymentError.custom(error.localizedDescription).err)
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
    public var originalTransactionId: String
    
    /// 价格
    public var price: String
    
    /// 货币单位
    public var currency: String
    
    init(orderId: String, transactionId: String, productId: String, originalTransactionId: String = "", price: String = "", currency: String = "") {
        self.orderId = orderId
        self.transactionId = transactionId
        self.productId = productId
        self.originalTransactionId = originalTransactionId
        self.price = price
        self.currency = currency
    }
    
    enum CodingKeys: String, CodingKey {
        case orderId = "orderId"
        case transactionId = "transactionId"
        case productId = "productId"
        case originalTransactionId = "originalTransactionId"
        case price = "price"
        case currency = "currency"
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
        return orderId
    }
}

