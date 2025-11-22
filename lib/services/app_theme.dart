import 'package:flutter/material.dart';

class AppTheme extends InheritedWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const AppTheme({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required super.child,
  });

  static AppTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>();
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

