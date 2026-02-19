Pod::Spec.new do |spec|
  spec.name         = "NoctuaSDK"
  spec.version      = "0.27.0"
  spec.summary      = "Noctua iOS SDK"
  spec.description  = "Noctua SDK is a framework to publish game in Noctua platform"
  spec.homepage     = "https://github.com/NoctuaLabs/noctua-native-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Noctua Labs" => "tech@noctua.gg" }

  spec.platform     = :ios, "14.0"
  spec.swift_version = "5.0"
  spec.static_framework = true
  
  spec.source       = { :git => "https://github.com/NoctuaLabs/noctua-native-sdk.git", :tag => "ios-sdk-v#{spec.version}" }
  spec.frameworks = "WebKit", "StoreKit", "AppTrackingTransparency", "AdServices", "AdSupport", "Security"
  spec.default_subspec = "Core"

  spec.subspec "Core" do |core|
    core.ios.source_files  = "ios/NoctuaSDK/Sources/**/*.{h,m,swift}"
  end

  spec.subspec "NoctuaInternalSDK" do |noctuainternalsdk|
    noctuainternalsdk.vendored_frameworks = "ios/NoctuaSDK/XCFrameworks/NoctuaInternalSDK.xcframework"
  end

  spec.subspec "Adjust" do |adjust|
    adjust.dependency "Adjust", "~> 4.38.4"
  end
  
  spec.subspec "FirebaseAnalytics" do |firebase|
    firebase.dependency "FirebaseAnalytics", "~> 11.14.0"
  end

  spec.subspec "FirebaseCrashlytics" do |firebase|
    firebase.dependency "FirebaseCrashlytics", "~> 11.14.0"
  end
  
  spec.subspec "FirebaseMessaging" do |firmessaging|
    firmessaging.dependency "FirebaseMessaging", "~> 11.14.0"
    firmessaging.frameworks = "UserNotifications"
  end

  spec.subspec "FirebaseRemoteConfig" do |remoteconfig|
    remoteconfig.dependency "FirebaseRemoteConfig", "~> 11.14.0"
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
  
  # Download NoctuaInternal + Facebook Static XCFrameworks
  spec.prepare_command = <<-CMD
    echo "Downloading NoctuaInternalSDK.xcframework"
    VERSION="0.15.0"
    ZIPFILE="NoctuaInternalSDK.xcframework.zip"
    URL="https://github.com/NoctuaLabs/noctua-internal-native-sdk/releases/download/ios-sdk-v${VERSION}/${ZIPFILE}"
    DESTINATION="ios/NoctuaSDK"

    echo "Remove ${DESTINATION}/XCFrameworks"
    rm -rf "${DESTINATION}/XCFrameworks"

    echo "Create the ${DESTINATION}/XCFrameworks directory"
    mkdir -p "${DESTINATION}/XCFrameworks"

    echo "Download ${ZIPFILE} FROM ${URL}"
    curl -L "${URL}" -o "${ZIPFILE}"

    echo "Unzip ${ZIPFILE} to ${DESTINATION}/XCFrameworks"
    unzip -q "${ZIPFILE}" -d "${DESTINATION}/XCFrameworks"

    echo "Remove ${ZIPFILE} after extraction"
    rm "${ZIPFILE}"

    echo "Downloading FacebookSDK-Static_XCFramework"
    VERSION="17.0.2"
    ZIPFILE="FacebookSDK-Static_XCFramework.zip"
    URL="https://github.com/facebook/facebook-ios-sdk/releases/download/v${VERSION}/${ZIPFILE}"

    echo "Download ${ZIPFILE} FROM ${URL}"
    curl -L "${URL}" -o "${ZIPFILE}"

    echo "Unzip ${ZIPFILE} to ${DESTINATION}"
    unzip -q "${ZIPFILE}" -d "${DESTINATION}"

    echo "Remove ${ZIPFILE} after extraction"
    rm "${ZIPFILE}"
  CMD
end
