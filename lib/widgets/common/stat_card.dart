import 'package:flutter/material.dart';
import '../../widgets/common/glass_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final double? height;

  const StatCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      height: height,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child), // Ensure child takes available space in height
        ],
      ),
    );
  }
}
