import 'package:flutter/cupertino.dart';
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
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
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
