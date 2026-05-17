import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HapticService {
  /// Light impact for minor interactions (e.g., tap, toggle)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
    if (kDebugMode) debugPrint("[Haptic] lightImpact");
  }

  /// Medium impact for standard interactions (e.g., buttons, card taps)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
    if (kDebugMode) debugPrint("[Haptic] mediumImpact");
  }

  /// Heavy impact for significant actions (e.g., long press, delete, commit)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
    if (kDebugMode) debugPrint("[Haptic] heavyImpact");
  }

  /// Selection click for scrolling lists, pickers, or sliders
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
    if (kDebugMode) debugPrint("[Haptic] selectionClick");
  }

  /// Success feedback for completed actions
  static Future<void> success() async {
    // There isn't a direct "success" method in HapticFeedback, 
    // but typically a light then medium pattern or just medium works well.
    // However, on iOS/Android standard patterns often exist implicitly or we can simulate.
    // We'll use mediumImpact for now as a distinct "done" feel or 
    // a double tap pattern if needed, but let's stick to simple standard first.
    // Actually, `vibrate` is often too strong. Let's do a medium impact.
    await HapticFeedback.mediumImpact();
    if (kDebugMode) debugPrint("[Haptic] success");
  }

  /// Error feedback for failures or validations
  static Future<void> error() async {
    // Heavy impact often signifies warning/error.
    // Double heavy impact could be better but let's start with single heavy.
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    if (kDebugMode) debugPrint("[Haptic] error");
  }
}
