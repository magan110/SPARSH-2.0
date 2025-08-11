import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SPARSH App Theme - Professional Design System
/// Modern, beautiful, and eye-pleasing theme with sophisticated color palette
class SparshTheme {
  // ===== MODERN COLOR PALETTE =====
  
  // Primary Colors - Professional Blue Palette
  static const Color primaryBlue = Color(0xFF2196F3); // Unified blue
  static const Color primaryBlueLight = Color(0xFF2196F3);
  static const Color primaryBlueAccent = Color(0xFF2196F3);
  static const Color primaryBlueShade700 = Color(0xFF2196F3);
  static const Color primaryBlueShade400 = Color(0xFF2196F3);
  static const Color primaryBlueShade100 = Color(0xFF2196F3);
  
  // Secondary Colors - Elegant Purple Palette
  // static const Color deepPurple = Color(0xFF7C3AED); // Modern purple
  // static const Color deepPurpleShade700 = Color(0xFF5B21B6);
  // static const Color deepPurpleShade400 = Color(0xFFA78BFA);
  // static const Color deepPurpleShade100 = Color(0xFFEDE9FE);
  
  // Accent Colors - Vibrant but Professional
  // static const Color purple = Color(0xFF8B5CF6);
  // static const Color purpleShade300 = Color(0xFFC4B5FD);
  // static const Color purpleShade100 = Color(0xFFF3F4F6);
  
  // Background Colors - Clean and Modern
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Very light blue-grey
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color lightBlueBackground = Color(0xFFEFF6FF);
  static const Color lightGreenBackground = Color(0xFFF0FDF4);
  static const Color lightPurpleBackground = Color(0xFFFAF5FF);
  static const Color lighterPurpleBackground = Color(0xFFF3E8FF);
  static const Color lightGreyBackground = Color(0xFFF9FAFB);
  
  // Text Colors - High Contrast for Readability
  static const Color textPrimary = Color(0xFF1F2937); // Dark grey
  static const Color textSecondary = Color(0xFF6B7280); // Medium grey
  static const Color textTertiary = Color(0xFF9CA3AF); // Light grey
  static const Color textBlack = Color(0xFF111827);
  static const Color textBlack87 = Color(0xFF000000);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLightGrey = Color(0xFF9CA3AF);
  
  // Border Colors - Subtle and Professional
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color borderLightGrey = Color(0xFFF3F4F6);
  static const Color borderDarkGrey = Color(0xFFD1D5DB);
  
  // Status Colors - Modern and Accessible
  static const Color successGreen = Color(0xFF10B981); // Modern green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningOrange = Color(0xFFF59E0B); // Modern orange
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFEF4444); // Modern red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoBlue = Color(0xFF3B82F6); // Modern blue
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Seat Colors - Enhanced for better visibility
  static const Color seatAvailable = Color(0xFF10B981);
  static const Color seatSelected = Color(0xFFF59E0B);
  static const Color seatBooked = Color(0xFFEF4444);
  
  // ===== BEAUTIFUL GRADIENTS =====
  
  // Primary Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient primaryGradientDiagonal = LinearGradient(
    colors: [primaryBlue, primaryBlueAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  // Accent Gradients
  static const LinearGradient blueAccentGradient = LinearGradient(
    colors: [primaryBlueAccent, Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  // Special Gradients
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueAccent],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient drawerHeaderGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );
  
  // ===== MAIN APP THEME =====
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blue,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: primaryBlueAccent,
        surface: Colors.white,
        background: scaffoldBackground,
        brightness: Brightness.light,
      ),
      
      // App Bar Theme - Modern and Clean
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      
      // Text Theme - Professional Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.25,
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        titleSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.25,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelSmall: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      
      // Input Decoration Theme - Modern and Clean
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme - Modern with Subtle Shadows
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      
      // Elevated Button Theme - Professional and Modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),
      
      // Dialog Theme - Modern and Clean
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Color(0x26000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGreyBackground,
        selectedColor: primaryBlueShade100,
        disabledColor: borderLightGrey,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        pressElevation: 2,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderGrey,
        thickness: 1,
        space: 1,
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // Dark Theme - Modern Dark Mode
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryBlueAccent,
        surface: Color(0xFF1E293B),
        brightness: Brightness.dark,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Color(0x4D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFF1E293B),
      ),
    );
  }
}

/// Enhanced Typography System
class SparshTypography {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: SparshTheme.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: -0.25,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: 0,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.15,
  );
  
  static const TextStyle heading5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.15,
  );
  
  static const TextStyle heading6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.15,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.5,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SparshTheme.textSecondary,
    letterSpacing: 0.4,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.1,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SparshTheme.textPrimary,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: SparshTheme.textSecondary,
    letterSpacing: 0.5,
  );
  
  // Special Styles
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SparshTheme.textTertiary,
    letterSpacing: 0.4,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: SparshTheme.textSecondary,
    letterSpacing: 1.5,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  static const TextStyle italic = TextStyle(
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: SparshTheme.textSecondary,
    letterSpacing: 0.4,
  );
}

/// Enhanced Spacing System
class SparshSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Enhanced Border Radius System
class SparshBorderRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

/// Enhanced Shadow System
class SparshShadows {
  static const List<BoxShadow> none = [];
  
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
  
  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
  
  // Special Shadows
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> elevation = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

/// Border Width System
class SparshBorderWidth {
  static const double none = 0.0;
  static const double thin = 1.0;
  static const double sm = 1.5;
  static const double md = 2.0;
  static const double lg = 3.0;
  static const double xl = 4.0;
}

/// Icon Size System
class SparshIconSize {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Animation Durations
class SparshAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// Animation Curves
class SparshCurves {
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve bounceOut = Curves.bounceOut;
} 