import 'dart:ui';

class AppColorsDark {
  // Primary Colors
  static const Color primary = Color(0xFFFFFFFF); // White for dark mode
  static const Color primaryLight = Color(0xFFF5F5F5); // Off-white
  static const Color primaryDark = Color(0xFFE0E0E0); // Light gray

  // Secondary Colors
  static const Color secondary = Color(0xFFB0B0B0); // Light gray
  static const Color secondaryLight = Color(0xFFD0D0D0); // Lighter gray
  static const Color secondaryDark = Color(0xFF8E8E8E); // Medium gray

  // Background Colors+
  static const Color background = Color(0xFF000000); // Pure Black (OLED)
  static const Color surface = Color(0xFF1A1A1A); // Elevated surface
  static const Color cardBackground = Color(0xFF1F1F1F); // Card background

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Primary text
  static const Color textSecondary = Color(0xFFB0B0B0); // Secondary text
  static const Color textDisabled = Color(0xFF6B6B6B); // Disabled text
  static const Color textHint = Color(0xFF757575); // Hint text

  // Accent Colors
  static const Color accent = Color(0xFF64B5F6); // Light blue
  static const Color accentRed = Color(0xFFEF5350); // Error/Delete
  static const Color accentGreen = Color(0xFF66BB6A); // Success
  static const Color accentOrange = Color(0xFFFFB74D); // Warning

  // UI Elements
  static const Color divider = Color(0xFF2D2D2D); // Dividers
  static const Color border = Color(0xFF2D2D2D); // Borders
  static const Color shadow = Color(0x40000000); // Shadows (25% opacity)
  static const Color overlay = Color(0xCC000000); // Overlay (80% opacity)

  // Progress/Indicators
  static const Color progressActive = Color(0xFFFFFFFF); // Active dots
  static const Color progressInactive = Color(0xFF3D3D3D); // Inactive dots

  // Floating Action Button
  static const Color fabBackground = Color(0xFFFFFFFF); // FAB background
  static const Color fabIcon = Color(0xFF000000); // FAB icon
}
