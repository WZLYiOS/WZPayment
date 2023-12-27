//
//  TargetType+Rx.swift
//  WZNetwork
//
//  Created by xiaobin liu on 2019/7/3.
//  Copyright © 2019 xiaobin liu. All rights reserved.
//

import Moya
import RxSwift

// MARK: 返回缓存数据类型
public enum CachePolicyType {
case nomar  /// 默认策略读取服务端数据
case cache  /// 先缓存后服务器, 回调2次
case cacheElseLoad /// 本地有缓存，返回缓存，无从服务端取
}


// MARK: - TargetType + Rx
public extension TargetType {
    
    /// 请求
    ///
    /// - Returns: Single<Moya.Response>
    func request(policyType: CachePolicyType = .nomar, cacheType: WZCache.CacheKeyType = .default) -> Observable<Moya.Response> {
        return Network.default.provider
            .rx
            .cacheRequest(.target(self), responseCache: policyType, cacheType: cacheType)
            .observeOn(MainScheduler.instance)
    }

    /// 公有参数
    var publicParameters: [String : String] {
        return Network.Configuration.default.publicParameters(self)
    }
    
    // 是否加密
    var isEncryption: Bool {
        if let mTarget = self as? MultiTarget,
            let encryption = mTarget.target as? EncryptionProtocol {
            return encryption.isEncryption
        }
        return false
    }
}

// MARK - 扩展
public extension Reactive where Base: MoyaProviderType {
    
    /**
     缓存网络请求:
     
     - 如果本地无缓存，直接返回网络请求到的数据
     - 如果本地有缓存，先返回缓存，再返回网络请求到的数据
     - 只会缓存请求成功的数据（缓存的数据 response 的状态码为 MMStatusCode.cache）
     - 适用于APP首页数据缓存
     
     */
    func cacheRequest(_ target: Base.Target, responseCache: CachePolicyType = .nomar, callbackQueue: DispatchQueue? = nil, cacheType: WZCache.CacheKeyType = .default) -> Observable<Response> {

        switch responseCache {
        case .nomar:
            return request(target, callbackQueue: callbackQueue).asObservable()
        case .cacheElseLoad:
            if let cacheResponse = WZCache.shared.fetchResponseCache(target: target) {
                return Observable.just(cacheResponse)
            }
            return request(target, callbackQueue: callbackQueue).asObservable()
        case .cache:
            var originRequest = request(target, callbackQueue: callbackQueue).asObservable()
            let cacheResponse = WZCache.shared.fetchResponseCache(target: target)
            // 更新缓存
            originRequest = originRequest.map { response -> Response in
                if let resp = try? response.filterSuccessfulStatusCodes() {
                    WZCache.shared.cacheResponse(resp, target: target)
                }
                return response
            }
            guard let lxf_cacheResponse = cacheResponse else {
                return originRequest
            }
            return Observable.just(lxf_cacheResponse).concat(originRequest)
        }
    }
}

