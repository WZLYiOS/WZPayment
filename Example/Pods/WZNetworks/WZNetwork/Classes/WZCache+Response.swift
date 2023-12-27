//
//  WZCache+Response.swift
//  Created on 2023/4/14
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 WZLY. All rights reserved.
//  @author 邱啟祥(739140860@qq.com)   
//

import Foundation
import Moya
import Cache

/// MARK - WZCache+Moya.Response
extension WZCache {
    @discardableResult
    func cacheResponse(
        _ response: Moya.Response,
        target: TargetType,
        cacheKey: CacheKeyType = .default
    ) -> Bool {
        do {
            try WZCache.shared.responseStorage?.setObject(response, forKey: target.fetchCacheKey(cacheKey))
            return true
        }
        catch { return false }
    }
    
    func fetchResponseCache(
        target: TargetType,
        cacheKey: CacheKeyType = .default
    ) -> Moya.Response? {
        
        guard let response = try? WZCache.shared.responseStorage?.object(forKey: target.fetchCacheKey(cacheKey))
        else { return nil }
        
        /*
         TransformerFactory.forResponse中的fromData仅执行一次
         导致无法更改 Response.statusCode 为 MMStatusCode.cache.rawValue，遂在此再次进行修改
        */
        let cacheResp = Response(statusCode: WZStatusCode.cache.rawValue, data: response.data)
        return cacheResp
    }
    
    @discardableResult
    func removeResponseCache(_ key: String) -> Bool {
        do {
            try WZCache.shared.responseStorage?.removeObject(forKey: key)
            return true
        }
        catch { return false }
    }
    
    @discardableResult
    func removeAllResponseCache() -> Bool {
        do {
            try WZCache.shared.responseStorage?.removeAll()
            return true
        }
        catch { return false }
    }
}
