import Foundation

/// Read-only build / config metadata exposed for the Inspector "Build"
/// sanity panel. All values are pulled lazily on demand — no caching —
/// because the panel only renders when the user navigates to it.
///
/// Sandbox-only contract: callers must already have verified
/// `NoctuaInspectorBus.shared.isEnabled` before invoking. The values
/// themselves carry no PII (project ID is a non-secret routing key,
/// the Adjust app token suffix surfaced upstream is masked) but
/// shipping a "what's in this build?" panel in production would be
/// surprising for end users.
public enum BuildInfoProvider {

    /// SDK semver. Bumped in lockstep with the podspec.
    public static let nativeSdkVersion: String = "0.36.0"

    /// Reads `PROJECT_ID` from the bundled `GoogleService-Info.plist`.
    /// Returns "" when the plist isn't bundled (Firebase not configured).
    public static func firebaseProjectId() -> String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let id = dict["PROJECT_ID"] as? String
        else { return "" }
        return id
    }

    /// Counts entries in `Info.plist`'s `SKAdNetworkItems` array. Apple
    /// requires this for ad-driven attribution on iOS 14.5+ — a build
    /// missing this list silently fails to attribute installs.
    public static func skAdNetworksCount() -> Int32 {
        guard let arr = Bundle.main.infoDictionary?["SKAdNetworkItems"] as? [Any]
        else { return 0 }
        return Int32(arr.count)
    }
}
