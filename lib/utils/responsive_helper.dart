import 'package:flutter/material.dart';

/// Responsive design helper class with standard breakpoints
class ResponsiveHelper {
  // Standard breakpoints
  static const double mobileBreakpoint = 576.0;
  static const double tabletBreakpoint = 768.0;
  static const double laptopBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;
  static const double largeDesktopBreakpoint = 1440.0;

  /// Get screen width from context
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height from context
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < tabletBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= tabletBreakpoint && width < laptopBreakpoint;
  }

  /// Check if current screen is laptop
  static bool isLaptop(BuildContext context) {
    final width = screenWidth(context);
    return width >= laptopBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopBreakpoint;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return screenWidth(context) >= largeDesktopBreakpoint;
  }

  /// Get responsive value based on screen size
  /// Returns different values for mobile, tablet, laptop, desktop
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? laptop,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isLaptop(context) && laptop != null) {
      return laptop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    final padding = responsiveValue<double>(
      context,
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      laptop: laptop ?? 32.0,
      desktop: desktop ?? 40.0,
    );
    return EdgeInsets.all(padding);
  }

  /// Get responsive font size using clamp
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      laptop: laptop ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.3,
    );
  }

  /// Get responsive width (percentage based)
  static double responsiveWidth(
    BuildContext context, {
    required double mobile, // percentage (0.0 - 1.0)
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    final width = responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 0.9,
      laptop: laptop ?? mobile * 0.85,
      desktop: desktop ?? mobile * 0.8,
    );
    return screenWidth(context) * width;
  }

  /// Get responsive column count for grid
  static int responsiveColumns(
    BuildContext context, {
    required int mobile,
    int? tablet,
    int? laptop,
    int? desktop,
  }) {
    return responsiveValue<int>(
      context,
      mobile: mobile,
      tablet: tablet ?? 2,
      laptop: laptop ?? 3,
      desktop: desktop ?? 4,
    );
  }

  /// Get responsive max width for containers
  static double responsiveMaxWidth(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile ?? double.infinity,
      tablet: tablet ?? 700.0,
      laptop: laptop ?? 900.0,
      desktop: desktop ?? 1200.0,
    );
  }

  /// Get responsive spacing
  static double responsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      laptop: laptop ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2.0,
    );
  }

  /// Get responsive border radius
  static double responsiveBorderRadius(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      laptop: laptop ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.3,
    );
  }

  /// Get responsive icon size
  static double responsiveIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      laptop: laptop ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.3,
    );
  }

  /// Get responsive dialog width
  static double responsiveDialogWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return width * 0.95;
    } else if (width < tabletBreakpoint) {
      return width * 0.85;
    } else if (width < laptopBreakpoint) {
      return 600.0;
    } else {
      return 700.0;
    }
  }

  /// Get responsive dialog height
  static double responsiveDialogHeight(BuildContext context) {
    final height = screenHeight(context);
    if (height < 600) {
      return height * 0.9;
    } else if (height < 800) {
      return height * 0.85;
    } else {
      return 700.0;
    }
  }

  /// Get responsive sidebar width
  static double responsiveSidebarWidth(
    BuildContext context, {
    bool collapsed = false,
  }) {
    if (collapsed) {
      return 80.0;
    }
    return responsiveValue<double>(
      context,
      mobile: 0.0, // Hidden on mobile
      tablet: 240.0,
      laptop: 260.0,
      desktop: 280.0,
    );
  }

  /// Get responsive card padding
  static EdgeInsets responsiveCardPadding(BuildContext context) {
    return responsivePadding(
      context,
      mobile: 12.0,
      tablet: 16.0,
      laptop: 20.0,
      desktop: 24.0,
    );
  }

  /// Get responsive grid spacing
  static double responsiveGridSpacing(BuildContext context) {
    return responsiveSpacing(
      context,
      mobile: 8.0,
      tablet: 12.0,
      laptop: 16.0,
      desktop: 20.0,
    );
  }
}

