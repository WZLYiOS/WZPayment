//
//  SalesError.swift
//  WZSales
//
//  Created by xiaobin liu on 2020/9/8.
//  Copyright © 2020 xiaobin liu. All rights reserved.
//

import Foundation


/// MARK - 握住良缘错误编码
public enum WZError: Swift.Error {
    
    /// 请求错误原因(错误编码2011001开始)
    ///
    /// - missingURL: 对象在编码请求时丢失 code: 2011001
    /// - lackOfAccessToken: 缺少访问令牌 code: 2011002
    public enum RequestErrorReason {
        case missingURL
        case lackOfAccessToken
    }
    
    /// 响应错误原因(错误编码从2012001开始)
    ///
    /// - dataParsingFailed: 数据解析错误 code: 2012001
    /// - emptyData: 空的数据 code： 2012002
    public enum ResponseErrorReason {
        
        case dataParsingFailed(Any.Type, Data, Error)
        case emptyData
    }
    
    /// 上传签名错误原因(错误编码从2013001开始)
    ///
    /// - imageCompression: 图片压缩失败
    /// - initQiNiu: 初始化七牛失败
    /// - keyEmpty: 通过key获取value值为空
    /// - qiNiuError: 七牛错误编码
    public enum UploadSignatureErrorReason {
        case imageCompression
        case initQiNiu
        case keyEmpty
        case qiNiuError(code: Int, reason: String)
    }
    
    
    /// 业务错误原因(错误编码由服务端下发)
    ///
    /// - tokenExpired: token过期
    /// - forceLogout: 被踢下线
    /// - customError: 自定义错误
    public enum BusinessErrorReason {
        case tokenExpired
        case forceLogout
        case customError(code: Int, reason: String)
    }
    
    
    /// 未知错误原因
    ///
    /// - unknown: 完全未知
    /// - systemError: 系统的错误
    public enum UnknownErrorReason {
        case unknown
        case systemError(code: Int, reason: String)
    }
    
    case requestFailed(reason: RequestErrorReason)
    case responseFailed(reason: ResponseErrorReason)
    case uploadSignatureFailed(reason: UploadSignatureErrorReason)
    case businessFailed(reason: BusinessErrorReason)
    case unknownFailed(reason: UnknownErrorReason)
}


// MARK: - LocalizedError
extension WZError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .requestFailed(reason: let reason): return reason.errorDescription
        case .responseFailed(reason: let reason): return reason.errorDescription
        case .uploadSignatureFailed(reason: let reason): return reason.errorDescription
        case .businessFailed(reason: let reason): return reason.errorDescription
        case .unknownFailed(reason: let reason): return reason.errorDescription
        }
    }
    
    public var debugDescription: String? {
        switch self {
        case .requestFailed(reason: let reason): return reason.debugDescription
        case .responseFailed(reason: let reason): return reason.debugDescription
        case .uploadSignatureFailed(reason: let reason): return reason.debugDescription
        case .businessFailed(reason: let reason): return reason.debugDescription
        case .unknownFailed(reason: let reason): return reason.debugDescription
        }
    }
}


// MARK: - CustomNSError
extension WZError: CustomNSError {
    
    public var errorCode: Int {
        switch self {
        case .requestFailed(reason: let reason): return reason.errorCode
        case .responseFailed(reason: let reason): return reason.errorCode
        case .uploadSignatureFailed(reason: let reason): return reason.errorCode
        case .businessFailed(reason: let reason): return reason.errorCode
        case .unknownFailed(reason: let reason): return reason.errorCode
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        #if DEBUG
        userInfo[NSLocalizedDescriptionKey] = "\([errorCode])\(String(describing: debugDescription ?? ""))"
        #else
        userInfo[NSLocalizedDescriptionKey] = errorDescription ?? ""
        #endif
        return userInfo
    }
}


// MARK: - Private Definition
extension WZError.RequestErrorReason {
    
    var debugDescription: String? {
        switch self {
        case .missingURL:
            return "URL在编码请求时丢失"
        case .lackOfAccessToken:
            return "请求需要一个访问令牌，但是没有"
        }
    }
    
    var errorDescription: String? {
        return "服务错误"
    }
    
    var errorCode: Int {
        switch self {
        case .missingURL:         return 2011001
        case .lackOfAccessToken:  return 2011002
        }
    }
}

// MARK: - Private Definition
extension WZError.UploadSignatureErrorReason {
    
    var debugDescription: String? {
        switch self {
        case .imageCompression:
            return "图片压缩失败"
        case .initQiNiu:
            return "七牛初始化失败"
        case .keyEmpty:
            return "获取七牛参数Key为空"
        case .qiNiuError(_, let reason):
            return reason
        }
    }
    
    var errorDescription: String? {
        return "上传签名失败"
    }
    
    var errorCode: Int {
        switch self {
        case .imageCompression:         return 2013001
        case .initQiNiu:                return 2013002
        case .keyEmpty:                 return 2013003
        case .qiNiuError(let code, _):  return code
        }
    }
}



// MARK: - Private Definition
extension WZError.ResponseErrorReason {
    
    var debugDescription: String? {
        switch self {
        case .dataParsingFailed(let type, let data, let error):
            let result = "解析响应数据到 \(type) 错误: \(error)."
            if let text = String(data: data, encoding: .utf8) {
                return result + "\n原始: \(text)"
            } else {
                return result
            }
        case .emptyData:
            return "空数据"
        }
    }
    
    var errorDescription: String? {
        return "解析错误"
    }
    
    var errorCode: Int {
        switch self {
        case .dataParsingFailed:         return 2012001
        case .emptyData:                 return 2012002
        }
    }
}

// MARK: - Private Definition
extension WZError.BusinessErrorReason {
    
    var debugDescription: String? {
        switch self {
        case .tokenExpired:
            return "登录信息已经失效，请重新登录"
        case .forceLogout:
            return "您的帐号已在其它终端登录"
        case .customError(_, reason: let reason):
            return reason
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return "登录信息已经失效，请重新登录"
        case .forceLogout:
            return "您的帐号已在其它终端登录"
        case .customError(_, reason: let reason):
            return reason
        }
    }
    
    var errorCode: Int {
        switch self {
        case .tokenExpired:             return 401
        case .forceLogout:              return 100101
        case .customError(let code, _): return code
        }
    }
}


// MARK: - 未知错误扩展
extension WZError.UnknownErrorReason {
    
    var defaultMsg: String {
        return "网络异常"
    }
    
    var debugDescription: String? {
        switch self {
        case .unknown:
            return defaultMsg
        case .systemError(_, let  reason):
            debugPrint(reason)
            return defaultMsg
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return defaultMsg
        case .systemError:
            return defaultMsg
        }
    }
    
    var errorCode: Int {
        switch self {
        case .unknown:                      return 00000
        case .systemError(let code, _):     return code
        }
    }
}

