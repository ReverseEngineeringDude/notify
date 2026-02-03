import 'package:flutter/material.dart';

class ModernScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  const ModernScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar || appBar != null,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF3F4F6), // Base light gray
                    Color(0xFFE0E7FF), // Light Indigo
                    Color(0xFFFCE7F3), // Light Pink
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Decorative Orbs (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Body Content
          Positioned.fill(
             child: Padding(
               padding: EdgeInsets.only(
                 top: (extendBodyBehindAppBar || appBar != null) 
                    ? MediaQuery.of(context).padding.top + (appBar?.preferredSize.height ?? 0) 
                    : 0
               ),
               child: body,
             ),
          ),
        ],
      ),
    );
  }
}
