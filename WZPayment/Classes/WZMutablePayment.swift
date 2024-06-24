//
//  WZMutablePayment.swift
//  Created by ___ORGANIZATIONNAME___ on 2024/6/24
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2024. All rights reserved.
//  @author qiuqixiang(739140860@qq.com)   
//

import UIKit
import StoreKit

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

