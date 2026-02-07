import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/connectivity_service.dart';
import 'widgets/common/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
    initError = e.toString();
  }

  runApp(MyApp(initError: initError));
}

class MyApp extends StatelessWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text("Firebase Initialization Failed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(initError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  const Text("Please run 'flutterfire configure' to generate the correct options for this platform.", textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }
    

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return CupertinoApp(
            title: 'Dynamic Panchayath',
            debugShowCheckedModeBanner: false,
            // Use builder to wrap the entire app with the OfflineBanner
            builder: (context, child) {
              return Stack(
                textDirection: TextDirection.ltr,
                children: [
                  if (child != null) child,
                  const OfflineBanner(),
                ],
              );
            },
            theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panchayath Manager")),
      body: const Center(child: Text("Initializing...")),
    );
  }
}
