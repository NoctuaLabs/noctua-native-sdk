Pod::Spec.new do |spec|
  spec.name         = "NoctuaSDK"
  spec.version      = "0.1.4"
  spec.summary      = "Noctua iOS SDK"
  spec.description  = "Noctua SDK is a framework to publish game in Noctua platform"
  spec.homepage     = "https://github.com/NoctuaLabs/noctua-native-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Noctua Labs" => "tech@noctua.gg" }

  spec.platform     = :ios, "14.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/NoctuaLabs/noctua-native-sdk.git", :tag => "ios-sdk-v#{spec.version}" }
  
  spec.frameworks = "WebKit", "StoreKit", "AppTrackingTransparency", "AdServices", "AdSupport"
  spec.static_framework = true

  spec.subspec 'Core' do |core|
    core.ios.source_files  = "ios/NoctuaSDK/Sources/**/*.{h,m,swift}"
  end
  spec.subspec 'Adjust' do |adjust|
    adjust.dependency "Adjust", "~> 4.38.4"
  end
  
  spec.default_subspec = 'Core'
end
