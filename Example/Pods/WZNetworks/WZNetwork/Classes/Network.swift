//
//  Network.swift
//  WZNetwork
//
//  Created by xiaobin liu on 2019/7/3.
//  Copyright © 2019 xiaobin liu. All rights reserved.
//

import Moya
import Alamofire
import WZDeviceKit

/// MARK - 我主良缘网络请求
open class Network {
    
    /// 单利
    public static let `default`: Network = {
        Network(configuration: Configuration.default)
    }()
    
    /// 供应商
    public let provider: MoyaProvider<MultiTarget>
    
    /// 初始化配置
    ///
    /// - Parameter configuration: configuration description
    public init(configuration: Configuration) {
        provider = MoyaProvider(configuration: configuration)
    }
}



// MARK: - MoyaProvider
public extension MoyaProvider {
    
    /// 自定义配置
    ///
    /// - Parameter configuration: configuration description
    convenience init(configuration: Network.Configuration) {
        
        let endpointClosure = { target -> Endpoint in
           return MoyaProvider.defaultEndpointMapping(for: target)
                .adding(newHTTPHeaderFields: configuration.addingHeaders(target))
                .replacing(task: configuration.replacingTask(target))
        }
        
        let requestClosure =  { (endpoint: Endpoint, closure: RequestResultClosure) -> Void in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = configuration.timeoutInterval
                closure(.success(request))
            } catch MoyaError.requestMapping(let url) {
                closure(.failure(.requestMapping(url)))
            } catch MoyaError.parameterEncoding(let error) {
                closure(.failure(.parameterEncoding(error)))
            } catch {
                closure(.failure(.underlying(error, nil)))
            }
        }
        
        self.init(endpointClosure: endpointClosure,
                  requestClosure: requestClosure,
                  session: MoyaProvider.customAlamofireManager(),
                  plugins: configuration.plugins)
    }
    
    /// 自定义alamofire管理
    ///
    /// - Returns: Session
    final class func customAlamofireManager() -> Session {

        let configuration = URLSessionConfiguration.default
        configuration.headers = [.defaultAcceptEncoding,
                                 .defaultAcceptLanguage,
                                 Network.Configuration.defaultUserAgent]
        return Session(configuration: configuration, startRequestsImmediately: false)
    }
}

