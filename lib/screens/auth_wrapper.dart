import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // For specific colors if needed, but prefer CupertinoColors
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'ward/ward_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    debugPrint("AuthWrapper Build: Current User is ${authService.currentUser}");

    // 1. Loading State (Fetching Firestore Profile)
    if (authService.isLoadingProfile) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(radius: 15),
        ),
      );
    }

    // 2. Authenticated but No Profile (Error State)
    if (authService.firebaseUser != null && authService.currentUser == null) {
      return CupertinoPageScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: CupertinoColors.activeOrange),
                const SizedBox(height: 16),
                Text(
                  "Access Error",
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  "You are logged in, but your user profile was not found. Please contact support or try logging out.",
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    authService.logout();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.square_arrow_right),
                      SizedBox(width: 8),
                      Text("Logout"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    authService.initializeUserProfile();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.hammer),
                      SizedBox(width: 8),
                      Text("Initialize as Super Admin"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Not Logged In
    if (authService.currentUser == null) {
      return const LoginScreen();
    }

    // 4. Logged In & Profile Loaded -> Role-based navigation
    if (authService.currentUser!.role == UserRole.superAdmin) {
      return const AdminDashboard();
    } else {
      return const WardDashboard();
    }
  }
}
