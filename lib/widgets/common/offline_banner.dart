import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (!connectivity.isOffline) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              color: CupertinoColors.destructiveRed,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.wifi_slash, color: CupertinoColors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "You are offline",
                    style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
