import 'package:flutter/material.dart';
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Authenticated but No Profile (Error State)
    // If firebaseUser is not null, but currentUser is null (and not loading), it means profile fetch failed or doesn't exist.
    if (authService.firebaseUser != null && authService.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  "Access Error",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "You are logged in, but your user profile was not found. Please contact support or try logging out.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    authService.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    authService.initializeUserProfile();
                  },
                  icon: const Icon(Icons.build),
                  label: const Text("Initialize as Super Admin (Repair)"),
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
