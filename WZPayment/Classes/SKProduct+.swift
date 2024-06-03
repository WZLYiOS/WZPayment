//
//  SKProduct+.swift
//  Created by ___ORGANIZATIONNAME___ on 2023/12/28
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023. All rights reserved.
//  @author qiuqixiang(739140860@qq.com)   
//

import Foundation
import StoreKit

// MARK - 产品信息
public extension SKProduct {
    
    /// 获取货币单位
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter 
    }
}
