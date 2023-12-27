//
//  WZCache.swift
//  Created on 2023/4/14
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2023 WZLY. All rights reserved.
//  @author 邱啟祥(739140860@qq.com)   
//

import Foundation
import Cache
import Moya

public enum WZStatusCode: Int {
    case cache = 230
    case loadFail = 700
}

// MARK: 缓存
public struct WZCache {
    
    /**
     let cacheKey = [method]baseURL/path
     
     - default : cacheKey + "?" + parameters
     - base : cacheKey
     - custom : cacheKey + "?" + customKey
     */
    public enum CacheKeyType {
        case `default`
        case base
        case custom(String)
    }
    
    public static let shared = WZCache()
    private init() {}
    
    public enum CacheContainer {
        case RAM
        case hybrid
    }

    internal let responseStorage = try? Storage<String, Response>(
        diskConfig: DiskConfig(name: "WZCache.lxf.MoyaResponse"),
        memoryConfig: MemoryConfig(),
        transformer: TransformerFactory.forResponse(Moya.Response.self)
    )
    
    /// 清理缓存
    public func clear() {
       try? responseStorage?.removeAll()
    }
}

/// MARK - 扩展数据
extension TransformerFactory {
    static func forResponse<T: Moya.Response>(_ type : T.Type) -> Transformer<T> {
        let toData: (T) throws -> Data = { $0.data }
        let fromData: (Data) throws -> T = {
            T(statusCode:  WZStatusCode.cache.rawValue, data: $0)
        }
        return Transformer<T>(toData: toData, fromData: fromData)
    }
    
    /// 模型
    public static func forCodable<U: Codable>(ofType: U.Type) -> Transformer<U> {
      let toData: (U) throws -> Data = { object in
        let wrapper = TypeWrapper<U>(object: object)
        let encoder = JSONEncoder()
        return try encoder.encode(wrapper)
      }

    
      let fromData: (Data) throws -> U = { data in
        let decoder = JSONDecoder()
        return try decoder.decode(TypeWrapper<U>.self, from: data).object
      }

      return Transformer<U>(toData: toData, fromData: fromData)
    }
}
