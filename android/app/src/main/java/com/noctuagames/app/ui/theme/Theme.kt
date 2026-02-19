package com.noctuagames.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = SoftIndigo,
    onPrimary = StarlightWhite,
    primaryContainer = MidnightBlue,
    onPrimaryContainer = StarlightWhite,
    secondary = LightPurple,
    onSecondary = StarlightWhite,
    secondaryContainer = TwilightPurple,
    onSecondaryContainer = StarlightWhite,
    tertiary = MoonlightAmber,
    onTertiary = NightBackground,
    tertiaryContainer = SoftAmber,
    onTertiaryContainer = NightBackground,
    background = NightBackground,
    onBackground = StarlightWhite,
    surface = NightSurface,
    onSurface = StarlightWhite,
    surfaceVariant = ElevatedSurface,
    onSurfaceVariant = MoonlightGray,
    error = ErrorRed,
    onError = StarlightWhite,
    outline = DimStar,
    outlineVariant = ElevatedSurface
)

private val LightColorScheme = lightColorScheme(
    primary = MidnightBlue,
    onPrimary = StarlightWhite,
    primaryContainer = SoftIndigo,
    onPrimaryContainer = StarlightWhite,
    secondary = TwilightPurple,
    onSecondary = StarlightWhite,
    secondaryContainer = LightPurple,
    onSecondaryContainer = MidnightBlue,
    tertiary = MoonlightAmber,
    onTertiary = NightBackground,
    tertiaryContainer = LightAmber,
    onTertiaryContainer = MidnightBlue,
    background = Color(0xFFF8F9FA),
    onBackground = Color(0xFF1A1A2E),
    surface = Color(0xFFFFFFFF),
    onSurface = Color(0xFF1A1A2E),
    surfaceVariant = Color(0xFFE8EAF6),
    onSurfaceVariant = Color(0xFF4A4A6A),
    error = ErrorRed,
    onError = Color(0xFFFFFFFF),
    outline = Color(0xFF9AA0A6),
    outlineVariant = Color(0xFFE8EAF6)
)

@Composable
fun NoctuaandroidsdkTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
