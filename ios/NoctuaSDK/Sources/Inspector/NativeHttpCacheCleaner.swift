import Foundation
#if canImport(WebKit)
import WebKit
#endif

/// Wipes iOS HTTP caches — URLCache (NSURLConnection / URLSession default
/// cache) and WKWebsiteDataStore (WebView disk + memory cache). Sandbox-
/// only; called from the Inspector "Memory" tab's "Clear native HTTP
/// cache" action via `noctuaClearNativeHttpCache`.
///
/// Synchronous on the URLCache side, asynchronous on the WebKit side
/// (Apple does not expose a sync clear). We fire-and-forget the WebKit
/// removal since the Memory tab does not surface progress for it.
public enum NativeHttpCacheCleaner {

    public static func clear() {
        // 1. Foundation HTTP cache — sync, instant.
        URLCache.shared.removeAllCachedResponses()

        // 2. WebKit data store — covers WKWebView disk + memory cache,
        //    cookies, IndexedDB, local storage. We only target cache types
        //    here so we don't blow away login cookies for active sessions.
        #if canImport(WebKit)
        if #available(iOS 9.0, *) {
            let cacheTypes: Set<String> = [
                WKWebsiteDataTypeDiskCache,
                WKWebsiteDataTypeMemoryCache,
                WKWebsiteDataTypeOfflineWebApplicationCache,
                WKWebsiteDataTypeFetchCache,
            ]
            let store = WKWebsiteDataStore.default()
            store.fetchDataRecords(ofTypes: cacheTypes) { records in
                store.removeData(ofTypes: cacheTypes, for: records) { /* fire-and-forget */ }
            }
        }
        #endif
    }
}
