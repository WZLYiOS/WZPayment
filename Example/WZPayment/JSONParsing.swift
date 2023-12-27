//
//  JSONParsing.swift
//  WZStore
//
//  Created by xiaobin liu on 2019/7/5.
//  Copyright © 2019 我主良缘. All rights reserved.
//

import UIKit
import Moya
import RxSwift
import CleanJSON
import Foundation

/// MARK - 服务端统一返回实体
public struct WZResult<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T?
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case msg = "msg"
        case data = "data"
    }
}


// MARK: - PrimitiveSequence + JSONParsing
public extension ObservableType where Element == Response {
    
    /// MARK - 转换数据为Result实体
    ///
    /// - Parameter type: 类型
    /// - Returns: Result
    func mapResult<T: Decodable>(_ type: T.Type, isDebug: Bool = false) -> Observable<WZResult<T>> {
        
        return Observable.create { (observable) -> Disposable in
            let disposable = asObservable().subscribe { (response) in
                
                // 因为服务端把所有的类型都以字符串来传递。。。。。。
                let decoder = CleanJSONDecoder()
                decoder.valueNotFoundDecodingStrategy = .custom(CustomAdapter())
                
                do {
                    let value = try decoder.decode(WZResult<T>.self, from: response.data)
                    if isDebug {
                        response.showApiDebug()
                    }
                    observable.onNext(value)
                } catch {
                    #if DEBUG
                    response.showApiDebug()
                    WZToast.showText(withStatus: "解析错误: URL地址:\(response.request?.url?.absoluteString ?? "") 数据:\(String(data: response.data, encoding: .utf8) ?? "")")
                    #endif
                    observable.onError(WZError.responseFailed(reason: .dataParsingFailed(T.self, response.data, error)))
                }
                
            } onError: { (error) in
                
                if let temError = error as? CustomNSError {
                    observable.onError(WZError.unknownFailed(reason: .systemError(code: temError.errorCode, reason: error.localizedDescription)))
                } else {
                    observable.onError(WZError.unknownFailed(reason: .unknown))
               }
            } onCompleted: {
                observable.onCompleted()
            }
            return Disposables.create([disposable])
        }
    }
    
    
    /// 转换为单独的实体
    ///
    /// - Parameter type: type description
    /// - Returns: return value description
    func mapModel<T: Decodable>(_ type: T.Type, isDebug: Bool = false) -> Observable<T> {
        
        return mapResult(T.self, isDebug: isDebug)
            .map { result -> T in
                
                try self.checkCode(result.code, msg: result.msg)
                guard let temData = result.data else {
                    throw WZError.responseFailed(reason: .emptyData)
                }
                return temData
            }
    }
    
    
    /// 可选实体
    ///
    /// - Parameter type: 类型
    /// - Returns: 可选实体的对象
    func mapOptionalModel<T: Decodable>(_ type: T.Type, isDebug: Bool = false) -> Observable<T?> {
        
        return mapResult(T.self, isDebug: isDebug)
            .map { result -> T? in
                
                try self.checkCode(result.code, msg: result.msg)
                return result.data
            }
    }
    
    
    /// 判断成功
    ///
    /// - Returns: 观察者成功
    func mapSuccess(isDebug: Bool = false) -> Observable<Bool> {
        
        return mapResult(String.self, isDebug: isDebug)
            .map { result -> Bool in
                
                try self.checkCode(result.code, msg: result.msg)
                return true
            }
    }
    
    
    /// 转换为整个实体(不过错误编码逻辑也已经处理)
    ///
    /// - Parameter type: type description
    /// - Returns: return value description
    func mapResultModel<T: Decodable>(_ type: T.Type,
                                      isDebug: Bool = false) -> Observable<(code: Int, msg: String, data: T)> {
        
        return mapResult(T.self, isDebug: isDebug)
            .map { (result) -> (code: Int, msg: String, data: T) in
                
                try self.checkCode(result.code, msg: result.msg)
                guard let data = result.data else {
                    throw WZError.responseFailed(reason: .emptyData)
                }
                return (result.code, result.msg, data)
            }
    }
    
    /// 校验编码
    ///
    /// - Parameters:
    ///   - code: 编码
    ///   - msg: 信息
    /// - Throws: throws value description
    private func checkCode(_ code: Int, msg: String) throws {
        
        guard code != WZError.BusinessErrorReason.tokenExpired.errorCode else {
//            WZTask.logOut.post(object: msg)
            throw WZError.businessFailed(reason: .tokenExpired)
        }
        
        guard code == 200 else {
            throw WZError.businessFailed(reason: .customError(code: code, reason: msg))
        }
    }
}


struct CustomAdapter: JSONAdapter {
    
    // 由于 Swift 布尔类型不是非 0 即 true，所以默认没有提供类型转换。
    // 如果想实现 Int 转 Bool 可以自定义解码。
    func adapt(_ decoder: CleanDecoder) throws -> Bool {
        // 值为 null
        if decoder.decodeNil() {
            return false
        }
        
        if let intValue = try decoder.decodeIfPresent(Int.self) {
            // 类型不匹配，期望 Bool 类型，实际是 Int 类型
            return intValue == 1 ? true : false
        }
        
        if let intValue = try decoder.decodeIfPresent(String.self) {
            // 类型不匹配，期望 Bool 类型，实际是 Int 类型
            return intValue == "1" ? true : false
        }
        
        return false
    }
}


/// MARK - 响应数据
public extension Response {
    
    func showApiDebug() {
    
        debugPrint(">>>>>>请求信息调试<<<<<<")
        
        debugPrint(">>>>>>请求地址<<<<<<")
        if let urlStr = self.request?.url?.absoluteString {
            debugPrint(urlStr)
        }
        
        debugPrint(">>>>>>请求头<<<<<<")
        if let header = self.request?.allHTTPHeaderFields {
//            debugPrint(header)
            let headerDIc = NSDictionary(dictionary: header)
//            headerDIc.debugLog()
        }
        
        debugPrint(">>>>>>请求参数<<<<<<")
        
        if let paramsData = self.request?.httpBody {

            if  let a = try? JSONSerialization.jsonObject(with: paramsData, options: .fragmentsAllowed) as? NSDictionary {
//                a.debugLog()
            } else {
                let obj = String(data: paramsData, encoding: String.Encoding.utf8) ?? "无请求参数"//
                debugPrint(obj)
            }
        } else if let absoluteString = self.request?.url?.absoluteString,
            let urlComponents = NSURLComponents(string: absoluteString),
            let queryItems = urlComponents.queryItems {
            queryItems.forEach { debugPrint("\($0.name) = \($0.value ?? "")") }
        } else {
            debugPrint("无请求参数")
        }
        
        debugPrint(">>>>>>响应状态码<<<<<<")
        debugPrint(response?.statusCode ?? 200)
        
        debugPrint(">>>>>>响应数据<<<<<<")
        let obj = NSMutableString(string: String(data: self.data, encoding: String.Encoding.utf8) ?? "无返回信息")
        if let dict = try? JSONSerialization.jsonObject(with: self.data,
                        options: .fragmentsAllowed) as? NSDictionary {
//            dict.debugLog()
        }else{
            debugPrint(obj)
        }
        debugPrint(">>>>>>请求信息调试完成<<<<<<")
    }
}
