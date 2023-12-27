//
//  TargetType+Cache.swift
//  Created on 2023/4/14
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 WZLY. All rights reserved.
//  @author 邱啟祥(739140860@qq.com)   
//
import UIKit
import Foundation
import Moya

// MARK: 获取缓存
extension TargetType {
    func fetchCacheKey(_ type: WZCache.CacheKeyType) -> String {
        switch type {
        case .base:
            return baseCacheKey
        case .default:
            return cacheKey
        case let .custom(key):
            return cacheKey(with: key)
        }
    }
    
    var cacheParameterTypeKey : String {
        return cacheKey(with: "ParameterTypeKey")
    }
    
    private var baseCacheKey : String {
        return "[\(self.method)]\(self.baseURL.absoluteString)/\(self.path)"
    }
    
    private var cacheKey: String {
        let baseKey = baseCacheKey
        if parameters.isEmpty { return baseKey }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let token = Network.Configuration.default.cacheUserId(self)
        return baseKey + "?" + version + token + parameters
    }
    
    private func cacheKey(with customKey: String) -> String {
        return baseCacheKey + "?" + customKey
    }
    
    private var parameters: String {
        switch self.task {
        case let .requestParameters(parameters, _):
            return jsonString(parameters: parameters)
        case let .requestCompositeParameters(bodyParameters, _, urlParameters):
            var parameters = bodyParameters
            for (key, value) in urlParameters { parameters[key] = value }
            return jsonString(parameters: parameters)
        case let .downloadParameters(parameters, _, _):
            return jsonString(parameters: parameters)
        case let .uploadCompositeMultipart(_, urlParameters):
            return jsonString(parameters: urlParameters)
        case let .requestCompositeData(_, urlParameters):
            return jsonString(parameters: urlParameters)
        default: return ""
        }
    }
    
    /// 字典转string
    private func jsonString(parameters: [String: Any])-> String {
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted),
           let json = String(data: jsonData, encoding: .utf8){
            return json
        }
        return ""
    }
}


