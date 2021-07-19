#
# Be sure to run `pod lib lint WZPayment.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WZPayment'
  s.version          = '3.0.3'
  s.summary          = '内购组件：支持自动补单，漏单可继续购买,订阅自动回调上报'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://code.aliyun.com/wzlyios/WZPayment.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qiuqixiang' => '739140860@qq.com' }
  s.source           = { :git => 'https://code.aliyun.com/wzlyios/WZPayment.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.requires_arc = true
  s.static_framework = true
  s.swift_version         = '5.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'WZPayment/Classes/*.swift'
  
  # s.resource_bundles = {
  #   'WZPayment' => ['WZPayment/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'KeychainAccess', '~> 3.2.0'
end
