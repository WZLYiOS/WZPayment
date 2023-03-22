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

/// MARK - 错误码
public enum WZPaymentError: Int {
case orderNil = 120001     
case productNil = 120002
case orderDb = 120003
case NoCanPay = 120004
case history = 120005
case db = 120006
    
    /// 错误文案
    var name: String {
        switch self {
        case .orderNil: return "订单id返回空，请联系客服"
        case .productNil: return "产品id返回空，请联系客服"
        case .orderDb: return "订单db保存失败，无法继续购买，请联系客服"
        case .NoCanPay: return "请到系统设置，开启苹果支付功能"
        case .history: return "当前有历史订单未补,已上报中...，请稍后再购买"
        case .db: return "支付凭证存入db失败"
        }
    }
    
    /// 错误
    var err: NSError {
       return NSError(domain: name, code: self.rawValue)
    }
}


// MARK - 错误
extension SKError {
    
    /// 苹果服务器返回错误
    var wzError: NSError {
        switch self.code {
        case .unknown:
            return NSError(domain: "苹果服务器：未知错误，请联系客服", code: self.code.rawValue, userInfo: nil)
        case .paymentCancelled:
            return NSError(domain: "苹果服务器：购买失败，您取消了付款", code: self.code.rawValue, userInfo: nil)
        case .cloudServiceRevoked:
            return NSError(domain: "苹果服务器：您已撤消使用此云服务的权限", code: self.code.rawValue, userInfo: nil)
        case .paymentInvalid:
            return NSError(domain: "苹果服务器：App Store无法识别付款参数", code: self.code.rawValue, userInfo: nil)
        case .paymentNotAllowed:
            return NSError(domain: "苹果服务器：请开启授权付款权限", code: self.code.rawValue, userInfo: nil)
        case .storeProductNotAvailable:
            return NSError(domain: "苹果服务器：所请求的产品在商店中不可用。", code: self.code.rawValue, userInfo: nil)
        case .cloudServiceNetworkConnectionFailed:
            return NSError(domain: "苹果服务器：设备无法连接到网络。", code: self.code.rawValue, userInfo: nil)
        default:
            return NSError(domain: "苹果服务器：未知错误", code: self.code.rawValue, userInfo: nil)
        }
    }
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
