package com.noctuagames.sdk;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.util.DisplayMetrics;

import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import static android.content.res.Configuration.UI_MODE_TYPE_MASK;
import static android.content.res.Configuration.UI_MODE_TYPE_TELEVISION;
import static com.adjust.sdk.Constants.HIGH;
import static com.adjust.sdk.Constants.LARGE;
import static com.adjust.sdk.Constants.LONG;
import static com.adjust.sdk.Constants.LOW;
import static com.adjust.sdk.Constants.MEDIUM;
import static com.adjust.sdk.Constants.NORMAL;
import static com.adjust.sdk.Constants.SMALL;
import static com.adjust.sdk.Constants.XLARGE;

/**
 * Created by pfms on 06/11/14.
 */
public class DeviceInfo {

    public static final String OFFICIAL_FACEBOOK_SIGNATURE =
            "30820268308201d102044a9c4610300d06092a864886f70d0101040500307a310b3009060355040613" +
                    "025553310b3009060355040813024341311230100603550407130950616c6f20416c746f31" +
                    "183016060355040a130f46616365626f6f6b204d6f62696c653111300f060355040b130846" +
                    "616365626f6f6b311d301b0603550403131446616365626f6f6b20436f72706f726174696f" +
                    "6e3020170d3039303833313231353231365a180f32303530303932353231353231365a307a" +
                    "310b3009060355040613025553310b30090603550408130243413112301006035504071309" +
                    "50616c6f20416c746f31183016060355040a130f46616365626f6f6b204d6f62696c653111" +
                    "300f060355040b130846616365626f6f6b311d301b0603550403131446616365626f6f6b20" +
                    "436f72706f726174696f6e30819f300d06092a864886f70d010101050003818d0030818902" +
                    "818100c207d51df8eb8c97d93ba0c8c1002c928fab00dc1b42fca5e66e99cc3023ed2d214d" +
                    "822bc59e8e35ddcf5f44c7ae8ade50d7e0c434f500e6c131f4a2834f987fc46406115de201" +
                    "8ebbb0d5a3c261bd97581ccfef76afc7135a6d59e8855ecd7eacc8f8737e794c60a761c536" +
                    "b72b11fac8e603f5da1a2d54aa103b8a13c0dbc10203010001300d06092a864886f70d0101" +
                    "040500038181005ee9be8bcbb250648d3b741290a82a1c9dc2e76a0af2f2228f1d9f9c4007" +
                    "529c446a70175c5a900d5141812866db46be6559e2141616483998211f4a673149fb2232a1" +
                    "0d247663b26a9031e15f84bc1c74d141ff98a02d76f85b2c8ab2571b6469b232d8e768a7f7" +
                    "ca04f7abe4a775615916c07940656b58717457b42bd928a2";

    String playAdId;
    String playAdIdSource;
    int playAdIdAttempt = -1;
    Boolean isTrackingEnabled;
    private boolean nonGoogleIdsReadOnce = false;
    private boolean playIdsReadOnce = false;
    private boolean otherDeviceInfoParamsReadOnce = false;
    String androidId;
    String fbAttributionId;
    String clientSdk;
    String packageName;
    String appVersion;
    String deviceType;
    String deviceName;
    String deviceManufacturer;
    String osName;
    String osVersion;
    String apiLevel;
    String language;
    String country;
    String screenSize;
    String screenFormat;
    String screenDensity;
    String displayWidth;
    String displayHeight;
    String hardwareName;
    String abi;
    String buildName;
    String appInstallTime;
    String appUpdateTime;
    int uiMode;
    String appSetId;
    boolean isGooglePlayGamesForPC;
    Boolean isSamsungCloudEnvironment;

    Map<String, String> imeiParameters;
    Map<String, String> oaidParameters;
    String fireAdId;
    Boolean fireTrackingEnabled;
    int connectivityType;
    String mcc;
    String mnc;

    DeviceInfo(Context context, com.adjust.sdk.AdjustConfig adjustConfig) {
        Resources resources = context.getResources();
        DisplayMetrics displayMetrics = resources.getDisplayMetrics();
        Configuration configuration = resources.getConfiguration();
        Locale locale = com.adjust.sdk.Util.getLocale(configuration);
        PackageInfo packageInfo = getPackageInfo(context);
        int screenLayout = configuration.screenLayout;
        isGooglePlayGamesForPC = com.adjust.sdk.Util.isGooglePlayGamesForPC(context);

        packageName = getPackageName(context);
        appVersion = getAppVersion(packageInfo);
        deviceType = getDeviceType(configuration);
        deviceName = getDeviceName();
        deviceManufacturer = getDeviceManufacturer();
        osName = getOsName();
        osVersion = getOsVersion();
        apiLevel = getApiLevel();
        language = getLanguage(locale);
        country = getCountry(locale);
        screenSize = getScreenSize(screenLayout);
        screenFormat = getScreenFormat(screenLayout);
        screenDensity = getScreenDensity(displayMetrics);
        displayWidth = getDisplayWidth(displayMetrics);
        displayHeight = getDisplayHeight(displayMetrics);
        fbAttributionId = getFacebookAttributionId(context);
        hardwareName = getHardwareName();
        abi = getABI();
        buildName = getBuildName();
        appInstallTime = getAppInstallTime(packageInfo);
        appUpdateTime = getAppUpdateTime(packageInfo);
        uiMode = getDeviceUiMode(configuration);
    }

    public Map<String, String> getDeviceInfoMap(final Context context) {
        Resources resources = context.getResources();
        DisplayMetrics displayMetrics = resources.getDisplayMetrics();
        Configuration configuration = resources.getConfiguration();
        Locale locale = com.adjust.sdk.Util.getLocale(configuration);
        PackageInfo packageInfo = DeviceInfo.getPackageInfo(context);
        int screenLayout = configuration.screenLayout;

        Map<String, String> map = new HashMap<>();
        map.put("package_name", DeviceInfo.getPackageName(context));
        map.put("app_version", DeviceInfo.getAppVersion(packageInfo));
        //map.put("device_type", DeviceInfo.getDeviceType(configuration));
        map.put("device_name", getDeviceName());
        //map.put("device_manufacturer", deviceManufacturer);
        map.put("os_version", getOsVersion());
        map.put("api_level", getApiLevel());
        map.put("language", getLanguage(locale));
        map.put("country", getCountry(locale));
        map.put("screen_size", getScreenSize(screenLayout));
        map.put("screen_format", getScreenFormat(screenLayout));
        map.put("screen_density", getScreenDensity(displayMetrics));
        map.put("display_width", getDisplayWidth(displayMetrics));
        map.put("display_height", getDisplayHeight(displayMetrics));
        //map.put("client_sdk", getClientSdk(adjustConfig.sdkPrefix));
        map.put("fb_attribution_id", getFacebookAttributionId(context));
        map.put("hardware_name", getHardwareName());
        map.put("abi", getABI());
        map.put("build_name", getBuildName());
        map.put("app_install_time", getAppInstallTime(packageInfo));
        map.put("app_update_time", getAppUpdateTime(packageInfo));
        //map.put("ui_mode", getDeviceUiMode(configuration).toString());
	    //map.put("screen_layout", screenLayout.toString());
        //if (Reflection.isAppRunningInSamsungCloudEnvironment(context, adjustConfig.logger)) {
	    //    map.put("is_samsung_cloud_environment", "true");
	    //    map.put("play_adid_source", "samsung_cloud_sdk");
        //}
        //if (Util.canReadPlayIds(adjustConfig)) {
	    //    map.put("app_set_id", appSetId);
        //}
        return map;
    }

    public static String getPackageName(Context context) {
        return context.getPackageName();
    }

    public static PackageInfo getPackageInfo(Context context) {
        try {
            PackageManager packageManager = context.getPackageManager();
            String name = context.getPackageName();
            return packageManager.getPackageInfo(name, PackageManager.GET_PERMISSIONS);
        } catch (Exception e) {
            return null;
        }
    }

    public static String getAppVersion(PackageInfo packageInfo) {
        try {
            return packageInfo.versionName;
        } catch (Exception e) {
            return null;
        }
    }

    public String getDeviceType(Configuration configuration) {
        if (isGooglePlayGamesForPC) {
            return "pc";
        }

        int uiMode = configuration.uiMode & UI_MODE_TYPE_MASK;
        if (uiMode == UI_MODE_TYPE_TELEVISION) {
            return "tv";
        }

        int screenSize = configuration.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;
        switch (screenSize) {
            case Configuration.SCREENLAYOUT_SIZE_SMALL:
            case Configuration.SCREENLAYOUT_SIZE_NORMAL:
                return "phone";
            case Configuration.SCREENLAYOUT_SIZE_LARGE:
            case 4:
                return "tablet";
            default:
                return null;
        }
    }

    public static int getDeviceUiMode(Configuration configuration) {
        return configuration.uiMode & UI_MODE_TYPE_MASK;
    }

    public String getDeviceName() {
        if (isGooglePlayGamesForPC) {
            return null;
        }
        return Build.MODEL;
    }

    public static String getDeviceManufacturer() {
        return Build.MANUFACTURER;
    }

    public String getOsName() {
        if (isGooglePlayGamesForPC) {
            return "windows";
        }
        return "android";
    }

    public String getOsVersion() {
        if (isGooglePlayGamesForPC) {
            return null;
        }
        return Build.VERSION.RELEASE;
    }

    public static String getApiLevel() {
        return "" + Build.VERSION.SDK_INT;
    }

    public static String getLanguage(Locale locale) {
        return locale.getLanguage();
    }

    public static String getCountry(Locale locale) {
        return locale.getCountry();
    }

    public static String getBuildName() {
        return Build.ID;
    }

    public static String getHardwareName() {
        return Build.DISPLAY;
    }

    public static String getScreenSize(int screenLayout) {
        int screenSize = screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK;

        switch (screenSize) {
            case Configuration.SCREENLAYOUT_SIZE_SMALL:
                return SMALL;
            case Configuration.SCREENLAYOUT_SIZE_NORMAL:
                return NORMAL;
            case Configuration.SCREENLAYOUT_SIZE_LARGE:
                return LARGE;
            case 4:
                return XLARGE;
            default:
                return null;
        }
    }

    public static String getScreenFormat(int screenLayout) {
        int screenFormat = screenLayout & Configuration.SCREENLAYOUT_LONG_MASK;

        switch (screenFormat) {
            case Configuration.SCREENLAYOUT_LONG_YES:
                return LONG;
            case Configuration.SCREENLAYOUT_LONG_NO:
                return NORMAL;
            default:
                return null;
        }
    }

    public static String getScreenDensity(DisplayMetrics displayMetrics) {
        int density = displayMetrics.densityDpi;
        int low = (DisplayMetrics.DENSITY_MEDIUM + DisplayMetrics.DENSITY_LOW) / 2;
        int high = (DisplayMetrics.DENSITY_MEDIUM + DisplayMetrics.DENSITY_HIGH) / 2;

        if (density == 0) {
            return null;
        } else if (density < low) {
            return LOW;
        } else if (density > high) {
            return HIGH;
        }
        return MEDIUM;
    }

    public static String getDisplayWidth(DisplayMetrics displayMetrics) {
        return String.valueOf(displayMetrics.widthPixels);
    }

    public static String getDisplayHeight(DisplayMetrics displayMetrics) {
        return String.valueOf(displayMetrics.heightPixels);
    }

    public static String getClientSdk(String sdkPrefix) {
        if (sdkPrefix == null) {
            return com.adjust.sdk.Constants.CLIENT_SDK;
        } else {
            return com.adjust.sdk.Util.formatString("%s@%s", sdkPrefix, com.adjust.sdk.Constants.CLIENT_SDK);
        }
    }

    @SuppressWarnings("deprecation")
    public static String getFacebookAttributionId(final Context context) {
        try {
            @SuppressLint("PackageManagerGetSignatures")
            Signature[] signatures = null;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                SigningInfo signingInfo = context.getPackageManager().getPackageInfo(
                        "com.facebook.katana",
                        PackageManager.GET_SIGNING_CERTIFICATES).signingInfo;
                if (signingInfo != null) {
                    signatures = signingInfo.getApkContentsSigners();
                }
            } else {
                signatures = context.getPackageManager().getPackageInfo(
                "com.facebook.katana",
                PackageManager.GET_SIGNATURES).signatures;
            }

            if (signatures == null || signatures.length != 1) {
                // Unable to find the correct signatures for this APK
                return null;
            }
            Signature facebookApkSignature = signatures[0];
            if (!OFFICIAL_FACEBOOK_SIGNATURE.equals(facebookApkSignature.toCharsString())) {
                // not the official Facebook application
                return null;
            }

            final ContentResolver contentResolver = context.getContentResolver();
            final Uri uri = Uri.parse("content://com.facebook.katana.provider.AttributionIdProvider");
            final String columnName = "aid";
            final String[] projection = {columnName};
            final Cursor cursor = contentResolver.query(uri, projection, null, null, null);

            if (cursor == null) {
                return null;
            }
            if (!cursor.moveToFirst()) {
                cursor.close();
                return null;
            }

            @SuppressLint("Range") final String attributionId = cursor.getString(cursor.getColumnIndex(columnName));
            cursor.close();
            return attributionId;
        } catch (Exception e) {
            return null;
        }
    }

    public static String getABI() {
        String[] SupportedABIS = com.adjust.sdk.Util.getSupportedAbis();

        // SUPPORTED_ABIS is only supported in API level 21
        // get CPU_ABI instead
        if (SupportedABIS == null || SupportedABIS.length == 0) {
            return com.adjust.sdk.Util.getCpuAbi();
        }

        return SupportedABIS[0];
    }

    public static String getAppInstallTime(PackageInfo packageInfo) {
        try {
            return com.adjust.sdk.Util.dateFormatter.format(new Date(packageInfo.firstInstallTime));
        } catch (Exception ex) {
            return null;
        }
    }

    public static String getAppUpdateTime(PackageInfo packageInfo) {
        try {
            return com.adjust.sdk.Util.dateFormatter.format(new Date(packageInfo.lastUpdateTime));
        } catch (Exception ex) {
            return null;
        }
    }
}
