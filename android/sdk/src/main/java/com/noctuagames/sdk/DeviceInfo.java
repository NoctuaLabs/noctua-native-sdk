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
import android.os.LocaleList;
import android.util.DisplayMetrics;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;

import static android.content.res.Configuration.UI_MODE_TYPE_MASK;
import static android.content.res.Configuration.UI_MODE_TYPE_TELEVISION;

/**
 * Created by pfms on 06/11/14.
 */
public class DeviceInfo {
    private static final String HIGH = "high";
    private static final String LARGE = "large";
    private static final String LONG = "long";
    private static final String LOW = "low";
    private static final String MEDIUM = "medium";
    private static final String NORMAL = "normal";
    private static final String SMALL = "small";
    private static final String XLARGE = "xlarge";

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

    DeviceInfo(Context context) {
        Resources resources = context.getResources();
        DisplayMetrics displayMetrics = resources.getDisplayMetrics();
        Configuration configuration = resources.getConfiguration();
        Locale locale = getLocale(configuration);
        PackageInfo packageInfo = getPackageInfo(context);
        int screenLayout = configuration.screenLayout;
        isGooglePlayGamesForPC = isGooglePlayGamesForPC(context);

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

    public Map<String, String> getDeviceInfoMap() {
        Map<String, String> map = new HashMap<>();
        map.put("package_name", packageName);
        map.put("app_version", appVersion);
        map.put("device_type", deviceType);
        map.put("device_name", deviceName);
        map.put("device_manufacturer", deviceManufacturer);
        map.put("os_version", osVersion);
        map.put("api_level", apiLevel);
        map.put("language", language);
        map.put("country", country);
        map.put("screen_size", screenSize);
        map.put("screen_format", screenFormat);
        map.put("screen_density", screenDensity);
        map.put("display_width", displayWidth);
        map.put("display_height", displayHeight);
        //map.put("client_sdk", getClientSdk(adjustConfig.sdkPrefix));
        map.put("fb_attribution_id", fbAttributionId);
        map.put("hardware_name", hardwareName);
        map.put("abi", abi);
        map.put("build_name", buildName);
        map.put("app_install_time", appInstallTime);
        map.put("app_update_time", appUpdateTime);
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

    @SuppressLint("ObsoleteSdkInt")
    public static String getABI() {
        if (Build.VERSION.SDK_INT >= 21 && Build.SUPPORTED_ABIS != null && Build.SUPPORTED_ABIS.length > 0) {
            return Build.SUPPORTED_ABIS[0];
        }
        else {
            return Build.CPU_ABI;
        }
    }

    public static String getAppInstallTime(PackageInfo packageInfo) {
        try {
            return formatEpochMilli(packageInfo.firstInstallTime);
        } catch (Exception ex) {
            return null;
        }
    }

    public static String getAppUpdateTime(PackageInfo packageInfo) {
        try {
            return formatEpochMilli(packageInfo.lastUpdateTime);
        } catch (Exception ex) {
            return null;
        }
    }

    private static String formatEpochMilli(long epochMilli) {
        ZoneId zoneId = TimeZone.getDefault().toZoneId();
        ZonedDateTime dateTime = Instant.ofEpochMilli(epochMilli).atZone(zoneId);

        return DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(dateTime);
    }

    public static boolean isGooglePlayGamesForPC(Context context) {
        return context.getPackageManager().hasSystemFeature("com.google.android.play.feature.HPE_EXPERIENCE");
    }

    @SuppressLint("ObsoleteSdkInt")
    public static Locale getLocale(Configuration config) {
        LocaleList localeList = config.getLocales();
        if (Build.VERSION.SDK_INT >= 24 && !localeList.isEmpty()) {
            return localeList.get(0);
        }
        else {
            return config.locale;
        }
    }
}
