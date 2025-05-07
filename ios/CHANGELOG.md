# Changelog

All notable changes to this project will be documented in this file.

## [ios-sdk-v0.14.1] - 2025-05-07

### 🐛 Bug Fixes

- Refactor configuration convention.

## [ios-sdk-v0.14.0] - 2025-04-30

### 🚀 Features

- Add log IAP is disabled by config

## [ios-sdk-v0.13.3] - 2025-04-30

### 🐛 Bug Fixes

- Handle modularization iap

## [ios-sdk-v0.13.2] - 2025-04-29

### 🐛 Bug Fixes

- Warning from Xcode linter.

## [ios-sdk-v0.13.1] - 2025-04-29

### 🐛 Bug Fixes

- Unwrap before check for empty.

## [ios-sdk-v0.13.0] - 2025-04-29

### 🚀 Features

- Add feature flag to disable config in IOS.

## [ios-sdk-v0.12.1] - 2025-04-21

### 🐛 Bug Fixes

- Update version 0.12.1

## [ios-sdk-v0.12.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline method to control Adjust offline mode .

## [ios-sdk-v0.11.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline method to control Adjust offline mode .

## [ios-sdk-v0.10.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline method to control Adjust offline mode .

## [ios-sdk-v0.9.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline method to control Adjust offline mode.

## [ios-sdk-v0.8.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline to support Adjust offline mode.
- Add onOnline and onOffline method to control Adjust offline mode.

### 🐛 Bug Fixes

- Add missing onOffline wrapper.

## [ios-sdk-v0.7.1] - 2025-01-14

### 🐛 Bug Fixes

- Update related firebase version to 11.6.0

## [ios-sdk-v0.7.0] - 2024-12-22

### 🚀 Features

- Enable FCM from sample app
- Add handler push notification message

## [ios-sdk-v0.6.0] - 2024-12-20

### 🚀 Features

- Add support for firebase messaging

## [ios-sdk-v0.5.7] - 2024-12-04

### 🐛 Bug Fixes

- Add more null check guard for Adjust tracker.

## [ios-sdk-v0.5.6] - 2024-12-04

### 🐛 Bug Fixes

- Guard Adjust event map with null check.

## [ios-sdk-v0.5.5] - 2024-11-29

### 🐛 Bug Fixes

- Reverse logic code environment mode adjust ios
- Change Purchase to purchase adjust ios

### 🚜 Refactor

- Refactor logic code environment check

## [ios-sdk-v0.5.4] - 2024-11-27

### 💼 Other

- Recheck platform specific config before init then pass the platform specific config as param.
- Recheck platform specific config before init then pass the platform specific config as param.

## [ios-sdk-v0.5.3] - 2024-11-20

### 🐛 Bug Fixes

- Use update instead of delete + add in AccountRepository

## [ios-sdk-v0.5.2] - 2024-11-11

### 🐛 Bug Fixes

- Split rawData and lastUpdated with correct separator index

## [ios-sdk-v0.5.1] - 2024-11-11

### ⚙️ Miscellaneous Tasks

- Fix CI GH release

## [ios-sdk-v0.5.0] - 2024-11-10

### 🚀 Features

- Save accounts in shared keychain

## [ios-sdk-v0.4.0] - 2024-11-08

### 🚀 Features

- IOS firebase crashlytics

### 🐛 Bug Fixes

- Rename Crashlytics to FirebaseCrashlytics

### 📚 Documentation

- Add manual release guide [skip ci]

## [ios-sdk-v0.3.0] - 2024-11-05

### 🚀 Features

- Add dynamic event suffix to facebook and firebase

## [ios-sdk-v0.2.5] - 2024-11-05

### 🐛 Bug Fixes

- Another attempt to fix version DSL in podspec

## [ios-sdk-v0.2.4] - 2024-11-04

### 🐛 Bug Fixes

- Fix CI version DSL error so that it can be pushed

## [ios-sdk-v0.2.3] - 2024-11-04

### 🐛 Bug Fixes

- Fix CI so at least it work when releasing

### ⚙️ Miscellaneous Tasks

- Add gitlab-ci for ios

## [ios-sdk-v0.2.2] - 2024-11-04

### 🚜 Refactor

- Removes unused internal tracker in iOS

## [ios-sdk-v0.2.0] - 2024-10-03

### 🚜 Refactor

- [**breaking**] Change FacebookSDK to static framework

## [ios-sdk-v0.1.26] - 2024-10-02

### 🐛 Bug Fixes

- Remove static_framework definition so that SDK can be linked either dynamically or statically

## [ios-sdk-v0.1.25] - 2024-10-01

### 🐛 Bug Fixes

- Set Firebase analytics collection enabled

## [ios-sdk-v0.1.24] - 2024-10-01

### 🚀 Features

- Disable custom event on iOS

### 🐛 Bug Fixes

- Always configure firebase

### ⚙️ Miscellaneous Tasks

- Bump version

## [ios-sdk-v0.1.22] - 2024-09-17

### 🐛 Bug Fixes

- Initialize Facebook SDK

### 🚜 Refactor

- Add logging and change parameters to tracker

## [ios-sdk-v0.1.21] - 2024-09-12

### 🐛 Bug Fixes

- Avoid configuring Firebase twice

## [ios-sdk-v0.1.20] - 2024-09-12

### 🐛 Bug Fixes

- Add facebook to NoctuaPlugin
- FirebaseAnalytics import macro

### ⚙️ Miscellaneous Tasks

- Bump version to 0.1.20

## [ios-sdk-v0.1.19] - 2024-09-11

### 🐛 Bug Fixes

- Use self.logger instead of print.

## [ios-sdk-v0.1.18] - 2024-09-11

### 🚀 Features

- Add getActiveCurrency().

## [ios-sdk-v0.1.16] - 2024-09-10

### ⚙️ Miscellaneous Tasks

- Bump to v0.1.16

## [ios-sdk-v0.1.15] - 2024-09-10

### 🚀 Features

- Catch receiptData after successful payment.

## [ios-sdk-v0.1.14] - 2024-09-10

### 🐛 Bug Fixes

- Use the real purchaseItem function. Bump to version 0.1.14.

## [ios-sdk-v0.1.13] - 2024-09-09

### 🐛 Bug Fixes

- Encode to JSON with best effort instead of coercing

## [ios-sdk-v0.1.12] - 2024-09-09

### 🐛 Bug Fixes

- Sync with unity data path

## [ios-sdk-v0.1.11] - 2024-09-09

### 🐛 Bug Fixes

- Fix config file path and add logging

## [ios-sdk-v0.1.7] - 2024-09-06

### 🐛 Bug Fixes

- Add simulation on the IAP bridge for testing purpose.

## [ios-sdk-v0.1.6] - 2024-09-05

### ⚙️ Miscellaneous Tasks

- Bump to 0.1.6

## [ios-sdk-v0.1.5] - 2024-08-07

### 🚀 Features

- Add objc bridge

### 🐛 Bug Fixes

- Serialize dictionary to json to cross .NET / obj-C boundary
- Use Any instead of the non compatible Encodable

## [ios-sdk-v0.1.4] - 2024-08-04

### 🐛 Bug Fixes

- Increment version because published 0.1.3 didn't work

## [ios-sdk-v0.1.3] - 2024-08-04

### 🐛 Bug Fixes

- Use default subspec so pod can be installed

### 🚜 Refactor

- Reconstruct workspace for development pods

### ⚙️ Miscellaneous Tasks

- Add logging

## [ios-sdk-v0.1.2] - 2024-08-02

### 🚀 Features

- Optionally depends on Adjust

### 🐛 Bug Fixes

- Bump version

## [ios-sdk-v0.1.1] - 2024-08-01

### 🐛 Bug Fixes

- Change to correct source path
- Add license file
- Podspec source path and license file
- Revert broken license and source files path
- Exclude xcodeworkspace files from source
- Bring back swift_version from the past
- Move podspec to root

## [ios-sdk-v0.1.0] - 2024-08-01

### 🚀 Features

- Integrate adjust
- Add example project

<!-- generated by git-cliff -->
