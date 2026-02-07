import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient, Alignment; // Keep minimal material for colors/gradients if needed

class ModernScaffold extends StatelessWidget {
  final Widget body;
  final ObstructingPreferredSizeWidget? navigationBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const ModernScaffold({
    super.key,
    required this.body,
    this.navigationBar,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: navigationBar, // Explicitly typed as ObstructedPreferredSizeWidget?
      backgroundColor: backgroundColor ?? CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
           // Optional: Subtle gradient background if desired for "Modern" feel, 
           // but tailored for iOS (very light/subtle).
           // If we want strict iOS system background, we can remove this container.
           // Leaving a very subtle one to match the "Modern" name, but closer to iOS.

          
          if (bottomNavigationBar != null)
             Align(alignment: Alignment.bottomCenter, child: bottomNavigationBar!),

          SafeArea(
            bottom: bottomNavigationBar == null, 
            child: body,
          ),
        ],
      ),
    );
  }
}
