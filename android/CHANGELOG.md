# Changelog

All notable changes to this project will be documented in this file.

## [android-sdk-v0.14.0] - 2025-09-16

### 🚀 Features

- Add get firebase installation id and session id - android

## [android-sdk-v0.13.1] - 2025-09-04

### 🚜 Refactor

- Change internalTrackerEnabled into nativeInternalTrackerEnabled

## [android-sdk-v0.13.0] - 2025-08-26

### 🚀 Features

- Remove adjust revenue parameters

## [android-sdk-v0.12.4] - 2025-08-14

### 🐛 Bug Fixes

- Downgrade minsdk

## [android-sdk-v0.12.3] - 2025-08-13

### 🐛 Bug Fixes

- Downgrade compile sdk and kotlin version

## [android-sdk-v0.12.2] - 2025-08-13

### 🐛 Bug Fixes

- Compilesdk is higher

## [android-sdk-v0.12.1] - 2025-08-13

### 🐛 Bug Fixes

- Firebase ad impression
- Remove built in event ad_revenue for firebase

## [android-sdk-v0.12.0] - 2025-08-07

### 🚀 Features

- Noctua internal tracker

## [android-sdk-v0.11.0] - 2025-07-31

### 🚀 Features

- Custom event with ad revenue

## [android-sdk-v0.10.2] - 2025-05-07

### 🐛 Bug Fixes

- Refactor configuration convention.

## [android-sdk-v0.10.1] - 2025-04-18

### 🐛 Bug Fixes

- Do not pull after checkout as it is already the latest since the fetch.

## [android-sdk-v0.10.0] - 2025-04-18

### 🚀 Features

- Add onOnline and onOffline API to control Adjust offline mode.

### 📚 Documentation

- Add comments.

## [android-sdk-v0.9.1] - 2024-12-20

### 🐛 Bug Fixes

- Use activity to ask permission instead of applicationContext

## [android-sdk-v0.9.0] - 2024-12-19

### 🚀 Features

- Add support for FIrebase Cloud Messaging

## [android-sdk-v0.8.1] - 2024-12-10

### 🐛 Bug Fixes

- Remove install conflict with other published game signed with different signature

## [android-sdk-v0.8.0] - 2024-11-29

### 🚀 Features

- Unified config android

### 🚜 Refactor

- "Purchase" to "purchase" android

## [android-sdk-v0.7.1] - 2024-11-28

### 🚜 Refactor

- Remove query all packages

## [android-sdk-v0.7.0] - 2024-11-27

### 🚀 Features

- Add multiple plaftorm support for event tracker in noctuagg.json.

## [android-sdk-v0.6.0] - 2024-11-12

### 🚀 Features

- Enable GWP-ASan

## [android-sdk-v0.5.0] - 2024-11-12

### 🚀 Features

- Crashlytics ndk android

### 🐛 Bug Fixes

- Remove enable crashlytics by programmatically

## [android-sdk-v0.4.2] - 2024-11-12

### 🐛 Bug Fixes

- Add isCrashlyticsCollectionEnabled = true

## [android-sdk-v0.4.1] - 2024-11-08

### 🐛 Bug Fixes

- Downgrade plugin crashlytics 3.0.2 -> 2.9.5

## [android-sdk-v0.4.0] - 2024-11-08

### 🚀 Features

- Android firebase crashlytics
- Add the Google services plugin and Crashlytics plugin
- Add button crash me android
- Google services json android

### 📚 Documentation

- Add manual release guide [skip ci]

## [android-sdk-v0.3.9] - 2024-11-02

### 🚜 Refactor

- Remove event map from Facebook and Firebase

## [android-sdk-v0.3.8] - 2024-10-28

### 🚜 Refactor

- Remove unused noctua tracker

## [android-sdk-v0.3.7] - 2024-10-18

### 🐛 Bug Fixes

- Use getInstalledApps instead of sending intent

## [android-sdk-v0.3.6] - 2024-10-16

### 🐛 Bug Fixes

- Makes content provider distributed across apps

## [android-sdk-v0.3.5] - 2024-10-15

### 🐛 Bug Fixes

- Use shared permission instead of app permission

## [android-sdk-v0.3.4] - 2024-10-15

### 🐛 Bug Fixes

- Add explicit Account constructor that receives 3 parameters

## [android-sdk-v0.3.3] - 2024-10-15

### 🐛 Bug Fixes

- Remove unneeded kotlin compose libs

## [android-sdk-v0.3.2] - 2024-10-15

### 🐛 Bug Fixes

- Add last_updated to account repository
- Save raw data instead of a lot of columns

## [android-sdk-v0.3.1] - 2024-10-10

### 🚜 Refactor

- Add columns to accounts that is useful to UI

## [android-sdk-v0.3.0] - 2024-10-09

### 🚀 Features

- Add AccountRepository to sdk

## [android-sdk-v0.2.1] - 2024-10-01

### 🐛 Bug Fixes

- Undo removing important permission gms.permission.AD_ID

## [android-sdk-v0.2.0] - 2024-09-19

### 🚀 Features

- Disable custom events on Android

## [android-sdk-v0.1.13] - 2024-09-17

### 🐛 Bug Fixes

- Fail Firebase initialization if not configured correctly

## [android-sdk-v0.1.12] - 2024-09-16

### 🚜 Refactor

- Add logging and change parameters to tracker

## [android-sdk-v0.1.11] - 2024-09-13

### 🐛 Bug Fixes

- Remove firebase bom to makes maven publish green

## [android-sdk-v0.1.10] - 2024-09-13

### 🐛 Bug Fixes

- Disable facebook temporarily so Maven will accept this version

## [android-sdk-v0.1.9] - 2024-09-13

### 🐛 Bug Fixes

- Use exact facebook version to be able to publish to maven central

## [android-sdk-v0.1.8] - 2024-09-12

### 🚜 Refactor

- Makes tracker initialization and tracking events more robust to errors

## [android-sdk-v0.1.7] - 2024-09-10

### ⚙️ Miscellaneous Tasks

- Add example config to example app

## [android-sdk-v0.1.6] - 2024-07-22

### 🐛 Bug Fixes

- Support lower API levels
- Remove unneeded dependencies

## [android-sdk-v0.1.5] - 2024-07-17

### 🚜 Refactor

- Decouple Adjust

## [android-sdk-v0.1.4] - 2024-07-14

### ⚙️ Miscellaneous Tasks

- *(ci)* Fix gh release

## [android-sdk-v0.1.3] - 2024-07-14

### ⚙️ Miscellaneous Tasks

- *(ci)* Makes gh release works
- *(ci)* Makes sure at the latest change before release

## [android-sdk-v0.1.2] - 2024-07-14

### ⚙️ Miscellaneous Tasks

- *(ci)* Fix publish
- *(ci)* Must checkout before release

## [android-sdk-v0.1.1] - 2024-07-14

### 🐛 Bug Fixes

- *(maven)* Put gitlab first

### ⚙️ Miscellaneous Tasks

- *(ci)* Bump version after release
- *(ci)* Fix alpine/git image entry point
- *(ci)* Fix deploy gitlab path and gitlab ci clone behavior
- *(ci)* Fix android folder pipeline rule
- *(ci)* Publish updated version
- *(ci)* Revamp release flow
- *(ci)* Pull before release
- *(ci)* Fix bump release version

## [android-sdk-v0.1.0] - 2024-07-14

### 🚀 Features

- *(adjust)* Add custom event tracking
- *(release)* Add publishing
- *(maven)* App depends on sdk via Gitlab package registry
- *(ci)* Publish to maven public repo
- *(ci)* Inject personal access token into repo

### 🐛 Bug Fixes

- *(adjust)* Add permissions
- *(ci)* Add workflow rules
- *(ci)* Move to root folder and build for android sdk exclusively
- *(ci)* Debug failed publish to gitlab
- *(ci)* Change Gitlab maven repo
- *(ci)* Change from groups to projects
- *(publish)* Skip signing
- *(publish)* Change repo to central

### 💼 Other

- *(adjust)* Add config file and support adjust

### 🚜 Refactor

- *(release)* Move to maven central

### 🧪 Testing

- Add test stage

### ⚙️ Miscellaneous Tasks

- *(ci)* Add test and release
- *(ci)* Add bump version

<!-- generated by git-cliff -->
