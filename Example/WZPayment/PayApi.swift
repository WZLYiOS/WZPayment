//
//  PayApi.swift
//  Created by CocoaPods on 2023/12/25
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023. All rights reserved.
//  @author qiuqixiang(739140860@qq.com)   
//

import Foundation
import Moya
import Foundation

public enum PayApi {
    case upload(orderId: String, transactionId: String, productId: String, originalTransactionId: String, receipt: String)
}

extension PayApi: TargetType{
    
    public var baseURL: URL { return URL(string: "http://192.168.2.7:8081")! }
    
    public var path: String {
        
        switch self {
        case .upload: return "/apple/pay/iPayNotify"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .upload: return .post
        }
    }
    
    public var task: Task {
        switch self {
        case .upload(orderId: let orderId, transactionId: let transactionId, productId: let productId, originalTransactionId: let originalTransactionId, receipt: let receipt):
            return Task.requestParameters(parameters: ["orderNo": orderId, "payId": transactionId, "productId": productId, "originalTransactionId": originalTransactionId, "transactionReceipt": receipt], encoding: JSONEncoding.default)
        }
    }
    
    public var headers: [String : String]? {
        return nil
    }
    
    public var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
}
