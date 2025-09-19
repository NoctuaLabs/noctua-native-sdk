Pod::Spec.new do |spec|
  spec.name         = "NoctuaSDK"
  spec.version      = "0.20.0"
  spec.summary      = "Noctua iOS SDK"
  spec.description  = "Noctua SDK is a framework to publish game in Noctua platform"
  spec.homepage     = "https://github.com/NoctuaLabs/noctua-native-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Noctua Labs" => "tech@noctua.gg" }

  spec.platform     = :ios, "15.0"
  spec.swift_version = "5.0"
  spec.static_framework = true
  
  spec.source       = { :git => "https://github.com/NoctuaLabs/noctua-native-sdk.git", :tag => "ios-sdk-v#{spec.version}" }
  spec.frameworks = "WebKit", "StoreKit", "AppTrackingTransparency", "AdServices", "AdSupport", "Security"
  spec.default_subspec = "Core"

  spec.subspec "Core" do |core|
    core.ios.source_files  = "ios/NoctuaSDK/Sources/**/*.{h,m,swift}"
  end
  
  spec.subspec "Adjust" do |adjust|
    adjust.dependency "Adjust", "~> 5.4.4"
  end
  
  spec.subspec "FirebaseAnalytics" do |firebase|
    firebase.dependency "FirebaseAnalytics", "~> 12.2.0"
  end

  spec.subspec "FirebaseCrashlytics" do |firebase|
    firebase.dependency "FirebaseCrashlytics", "~> 12.2.0"
  end
  
  spec.subspec "FirebaseMessaging" do |firmessaging|
    firmessaging.dependency "FirebaseMessaging", "~> 12.2.0"
    firmessaging.frameworks = "UserNotifications"
  end
  
  spec.subspec "FacebookSDK" do |facebook|
    facebook.platform     = :ios, "14.0"

    facebook.subspec "FBSDKCoreKit_Basics" do |corekit_basics|
      corekit_basics.vendored_frameworks = "ios/NoctuaSDK/XCFrameworks/FBSDKCoreKit_Basics.xcframework"
    end
    
    facebook.subspec "FBAEMKit" do |aemkit|
      aemkit.vendored_frameworks = "ios/NoctuaSDK/XCFrameworks/FBAEMKit.xcframework"
      aemkit.dependency "NoctuaSDK/FacebookSDK/FBSDKCoreKit_Basics"
    end
    
    facebook.subspec "FBSDKCoreKit" do |corekit|
      corekit.vendored_frameworks = "ios/NoctuaSDK/XCFrameworks/FBSDKCoreKit.xcframework"
      corekit.dependency "NoctuaSDK/FacebookSDK/FBSDKCoreKit_Basics"
      corekit.dependency "NoctuaSDK/FacebookSDK/FBAEMKit"
      corekit.frameworks = "Accelerate"
    end
  end
  
  # Download Facebook-Static XCFramwework from Facebook iOS SDK Github releases
  spec.prepare_command = <<-CMD
    echo "Downloading FacebookSDK-Static_XCFramework"
    VERSION="18.0.1"
    ZIPFILE="FacebookSDK-Static_XCFramework.zip"
    URL="https://github.com/facebook/facebook-ios-sdk/releases/download/v${VERSION}/${ZIPFILE}"
    DESTINATION="ios/NoctuaSDK"
    
    echo "Remove ${DESTINATION}/XCFrameworks"
    rm -rf "${DESTINATION}/XCFrameworks"
    
    echo "Create the ${DESTINATION}/XCFrameworks directory"
    mkdir -p "${DESTINATION}/XCFrameworks"
    
    echo "Download ${ZIPFILE} FROM ${URL}"
    curl -L "${URL}" -o "${ZIPFILE}"
    
    echo "Unzip ${ZIPFILE} to ${DESTINATION}"
    unzip -q "${ZIPFILE}" -d "${DESTINATION}"
    
    echo "Remove ${ZIPFILE} after extraction"
    rm "${ZIPFILE}"
  CMD
end
