# Noctua iOS SDK

## Development

- Your work email should be tied with the provisioning profile for development. Please login with your work email in XCode -> Settings -> Accounts
- Run `pod install --repo-update` before opening the project with XCode. Adjust if necessary.

## Manual Release Guide

### Release

1. **Navigate to the iOS directory:**
    ```sh
    cd ios
    ```

2. **Fetch tags and pull the latest changes:**
    ```sh
    git fetch --tags
    git checkout $CI_COMMIT_BRANCH
    git pull
    ```

3. **Update `NoctuaSDK.podspec` with the new version:**
    ```sh
    NEW_VERSION="x.y.z" # Replace x.y.z with the new version
    sed -r "s/(spec.version *= *)\".*\"/\1\"$NEW_VERSION\"/" ../NoctuaSDK.podspec > ../NoctuaSDK.podspec.tmp && mv ../NoctuaSDK.podspec.tmp ../NoctuaSDK.podspec
    ```

4. **Commit and tag the release:**
    ```sh
    git add ../NoctuaSDK.podspec
    git commit -m "Release $NEW_VERSION"
    git tag -a "ios-sdk-v$NEW_VERSION" -m "Release ios-sdk-v$NEW_VERSION"
    git push "https://$GITLAB_BUILDER_USER:$GITLAB_BUILDER_ACCESS_TOKEN@gitlab.com/evosverse/noctua/noctua-sdk-native.git" HEAD:$CI_COMMIT_BRANCH --follow-tags -o ci.skip
    ```

### Publish

1. **Create the release notes manually:**
    ```sh
    echo "Release notes for version x.y.z" > GithubRelease.md # Replace x.y.z with the new version
    ```

2. **Authenticate with GitHub and create the release:**
    ```sh
    curl -sS https://webi.sh/gh | sh
    echo $GITHUB_ACCESS_TOKEN | gh auth login --with-token
    git remote add github https://github.com/NoctuaLabs/noctua-native-sdk.git
    gh release create "ios-sdk-v$NEW_VERSION" --title "ios-sdk-v$NEW_VERSION" --notes-file GithubRelease.md
    git remote remove github
    ```

3. **Register the session with CocoaPods trunk:**
    ```sh
    pod trunk register youremail@noctua.gg "Your Name"
    ```

4. **Check if you are one of the pod owner, ask one of the owner to add you if you are not**
    ```sh
    pod trunk info NoctuaSDK
    ```

5. **Push the podspec to CocoaPods trunk:**
    ```sh
    pod trunk push ../NoctuaSDK.podspec --allow-warnings
    ```
