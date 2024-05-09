//
//  WZPaymentError.swift
//  Created on 2023/3/21
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 WZLY. All rights reserved.
//  @author 邱啟祥(739140860@qq.com)   
//

import Foundation
import StoreKit

/// 错误码
public enum WZPaymentCode: Int {
case orderNil = 120001 // 订单id返回空
case productNil = 120002 // 产品id返回空
case orderDb = 120003 // 订单db保存失败
case NoCanPay = 120004 // 请到系统设置，开启苹果支付功能
case history = 120005 // 发起内购失败：当前有历史订单未补,已上报中...，请稍后再购买
case dbReceipt = 120006 // "内购支付失败：支付凭证存入db失败"
case notproduct = 120007 // "发起内购失败：未获取到该商品"
case other = 120008     // 发起内购失败：\(text)
case appleUnknown = 120009 // 苹果服务器：未知错误，请联系客服
case paymentCancelled = 120010 // "苹果服务器：购买失败，您取消了付款"
case cloudServiceRevoked = 120011 // "苹果服务器：您已撤消使用此云服务的权限"
case paymentInvalid = 120012 // 苹果服务器：App Store无法识别付款参数
case paymentNotAllowed = 120013// 苹果服务器：请开启授权付款权限
case storeProductNotAvailable = 120014 // 苹果服务器：所请求的产品在商店中不可用。
case cloudServiceNetworkConnectionFailed = 120015 // 苹果服务器：设备无法连接到网络
}

/// MARK - 错误码
public enum WZPaymentError {
case orderNil
case productNil
case orderDb
case NoCanPay
case history
case db
case notproduct
case custom(String)
    
    /// 错误
    var err: NSError {
        switch self {
        case .orderNil: return NSError(domain: "发起内购失败：订单id返回空，请联系客服", code: WZPaymentCode.orderNil.rawValue)
        case .productNil: return NSError(domain: "发起内购失败：产品id返回空，请联系客服", code: WZPaymentCode.productNil.rawValue)
        case .orderDb: return NSError(domain: "发起内购失败：订单db保存失败，无法继续购买，请联系客服", code: WZPaymentCode.orderDb.rawValue)
        case .NoCanPay: return NSError(domain: "发起内购失败：请到系统设置，开启苹果支付功能", code: WZPaymentCode.NoCanPay.rawValue)
        case .history: return NSError(domain: "发起内购失败：当前有历史订单未补,已上报中...，请稍后再购买", code: WZPaymentCode.history.rawValue)
        case .db: return NSError(domain: "内购支付失败：支付凭证存入db失败", code: WZPaymentCode.dbReceipt.rawValue)
        case .notproduct: return NSError(domain: "发起内购失败：未获取到该商品", code: WZPaymentCode.notproduct.rawValue)
        case let .custom(text): return NSError(domain: "发起内购失败：\(text)", code: WZPaymentCode.other.rawValue)
        }
    }
}


// MARK - 错误
extension SKError {
    
    /// 苹果服务器返回错误
    var wzError: NSError {
        switch self.code {
        case .unknown:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.appleUnknown.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .paymentCancelled:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.paymentCancelled.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .cloudServiceRevoked:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.cloudServiceRevoked.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .paymentInvalid:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.paymentInvalid.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .paymentNotAllowed:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.paymentNotAllowed.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .storeProductNotAvailable:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.storeProductNotAvailable.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        case .cloudServiceNetworkConnectionFailed:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.cloudServiceNetworkConnectionFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        default:
            return NSError(domain: SKErrorDomain, code: WZPaymentCode.appleUnknown.rawValue, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
        }
    }
    
//    /// 苹果服务器返回错误
//    var wzError: NSError {
//        switch self.code {
//        case .unknown:
//            return NSError(domain: "苹果服务器：未知错误，请联系客服", code: 120009, userInfo: nil)
//        case .paymentCancelled:
//            return NSError(domain: "苹果服务器：购买失败，您取消了付款", code: 120010, userInfo: nil)
//        case .cloudServiceRevoked:
//            return NSError(domain: "苹果服务器：您已撤消使用此云服务的权限", code: 120011, userInfo: nil)
//        case .paymentInvalid:
//            return NSError(domain: "苹果服务器：App Store无法识别付款参数", code: 120012, userInfo: nil)
//        case .paymentNotAllowed:
//            return NSError(domain: "苹果服务器：请开启授权付款权限", code: 120013, userInfo: nil)
//        case .storeProductNotAvailable:
//            return NSError(domain: "苹果服务器：所请求的产品在商店中不可用。", code: 120014, userInfo: nil)
//        case .cloudServiceNetworkConnectionFailed:
//            return NSError(domain: "苹果服务器：设备无法连接到网络。", code: 120015, userInfo: nil)
//        default:
//            return NSError(domain: "苹果服务器：未知错误", code: 12001016, userInfo: nil)
//        }
//    }
}

/// 扩展错误码
extension Error {
    
    /// 自定义错误码
    var customError: Error {
        if let x = self as? SKError {
            return x.wzError
        }
        return self
    }
}
