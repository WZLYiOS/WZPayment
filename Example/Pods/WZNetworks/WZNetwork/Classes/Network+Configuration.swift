//
//  Network+Configuration.swift
//  WZNetwork
//
//  Created by xiaobin liu on 2019/7/3.
//  Copyright © 2019 xiaobin liu. All rights reserved.
//

import Moya
import Alamofire
import WZDeviceKit

// MARK: - 网络请求配置扩展
public extension Network {
    
    /// 配置
    class Configuration {
        
        /// 默认配置
        public static var `default`: Configuration = Configuration()
        
        /// 全局追加header头部配置
        public var addingHeaders: (TargetType) -> [String: String] = { _ in [:] }
        
        /// 缓存token
        public var cacheUserId: (TargetType) -> String = { _ in "" }
        
        /// 更换任务
        public var replacingTask: (TargetType) -> Task = { $0.task }
        
        /// 超时时间
        public var timeoutInterval: TimeInterval = 30
        
        /// Token
//        public var token: String?
        
        /// 公有参数
        public var publicParameters: (TargetType) -> [String: String] = { _ in [:] }
        
        /// 插件
        public var plugins: [PluginType] = [NetworkIndicatorPlugin()]
        
        /// 初始化
        public init() {}
        
       /// Returns default `User-Agent` header.
       public static let defaultUserAgent: HTTPHeader = {
        
           let info = Bundle.main.infoDictionary
           let executable = (info?[kCFBundleExecutableKey as String] as? String) ??
               (ProcessInfo.processInfo.arguments.first?.split(separator: "/").last.map(String.init)) ??
               "Unknown"
           let bundle = info?[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
           let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
           let appBuild = info?[kCFBundleVersionKey as String] as? String ?? "Unknown"

           let osNameVersion: String = {
               let version = ProcessInfo.processInfo.operatingSystemVersion
               let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
               let osName: String = {
                   #if os(iOS)
                   #if targetEnvironment(macCatalyst)
                   return "macOS(Catalyst)"
                   #else
                   return "iOS"
                   #endif
                   #elseif os(watchOS)
                   return "watchOS"
                   #elseif os(tvOS)
                   return "tvOS"
                   #elseif os(macOS)
                   return "macOS"
                   #elseif os(Linux)
                   return "Linux"
                   #elseif os(Windows)
                   return "Windows"
                   #else
                   return "Unknown"
                   #endif
               }()

               return "\(osName) \(versionString)"
           }()
        
           let userAgent = "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(Device.current.description):\(osNameVersion))"

           return HTTPHeader.userAgent(userAgent)
       }()
    }
}
