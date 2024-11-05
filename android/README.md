# Noctua Android SDK

#: Notes from data team

Broker:
  - redpanda-0.broker.noctuaprojects.com:31092
  - redpanda-1.broker.noctuaprojects.com:31092
  - redpanda-2.broker.noctuaprojects.com:31092
topics naming: 
  - Template: "[env]-noctua.[team].[name_level_1].[name_level_2]"
  - prod without [env]- prefix
  - sample: dev-noctua.data.bronze.game_tracker.ashechoes
  - bisa lihat2 di sini: https://redpanda-ads.noctuaprojects.com/topics

## Manual Release Guide for Android SDK

1. Navigate to the `android` directory:
  ```sh
  cd android
  ```

2. Fetch the latest tags and pull the latest changes:
  ```sh
  git fetch --tags
  git checkout main
  git pull
  ```

3. Determine the new version tag (replace `NEW_VERSION_TAG` with the actual version):
  ```sh
  NEW_VERSION_TAG="android-sdk-vX.Y.Z"
  echo $NEW_VERSION_TAG | sed -r "s/android-sdk-v(.*)/\1/" > version.txt
  ```

4. Add, commit, and tag the new version:
  ```sh
  git add version.txt
  git commit -m "Release $NEW_VERSION_TAG"
  git tag -a $NEW_VERSION_TAG -m "Release $NEW_VERSION_TAG"
  git push origin main --follow-tags -o ci.skip
  ```

#### Publish Android SDK

1. Publish the SDK to Maven Central:
  ```sh
  ./gradlew :sdk:publishAndReleaseToMavenCentral
  ```

2. Generate the release notes manually and save them to `GithubRelease.md`.

3. Prepare the AAR file for release:
  ```sh
  cp ./sdk/build/outputs/aar/sdk-release.aar "./noctua-$NEW_VERSION_TAG.aar"
  ```

4. Authenticate with GitHub and create a new release:
  ```sh
  echo $GITHUB_ACCESS_TOKEN | gh auth login --with-token
  gh release create $NEW_VERSION_TAG --title $NEW_VERSION_TAG --notes-file GithubRelease.md "./noctua-$NEW_VERSION_TAG.aar"
  ```
