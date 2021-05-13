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
        guard let url = Bundle.main.appStoreReceiptURL else {
            return ""
        }
        let receiptData = try? Data(contentsOf: url)
        let base64String = receiptData?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
        return base64String
    }
    
    /// 保存钥匙串的key
    public var saveKey: String {
        if orderId.count > 0 {
            return "com.wzly.keych.orderId."+orderId
        }
        return "com.wzly.keych.transactionId."+transactionId
    }
}

// MARK - 错误
extension SKError {
    
    enum ErrorType: Int {
        case fail = 100330
        case order = 1002
        case canPay  = 1003
       
        func error() -> Error {
            switch self {
            case .order:
                return NSError(domain: "订单id返回空，请联系客服", code: self.rawValue, userInfo: nil)
            case .canPay:
                return NSError(domain: "请到系统设置，开启苹果支付功能", code: self.rawValue, userInfo: nil)
            case .fail:
                return NSError(domain: "支付失败，请检查网络是否正常", code: self.rawValue, userInfo: nil)
            }
        }
    }
    
    func getError() -> Error {
        switch self.code {
        case .unknown:
            return NSError(domain: "订单id返回空，请联系客服", code: self.code.rawValue, userInfo: nil)
        case .paymentCancelled:
            return NSError(domain: "购买失败，您取消了付款", code: self.code.rawValue, userInfo: nil)
        case .cloudServiceRevoked:
            return NSError(domain: "您已撤消使用此云服务的权限", code: self.code.rawValue, userInfo: nil)
        case .paymentInvalid:
            return NSError(domain: "App Store无法识别付款参数", code: self.code.rawValue, userInfo: nil)
        case .paymentNotAllowed:
            return NSError(domain: "请开启授权付款权限", code: self.code.rawValue, userInfo: nil)
        case .storeProductNotAvailable:
            return NSError(domain: "所请求的产品在商店中不可用。", code: self.code.rawValue, userInfo: nil)
        case .cloudServiceNetworkConnectionFailed:
            return NSError(domain: "设备无法连接到网络。", code: self.code.rawValue, userInfo: nil)
        default:
            return NSError(domain: "未知错误", code: self.code.rawValue, userInfo: nil)
        }
    }
}
