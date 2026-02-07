import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter/material.dart' show Colors, Icons, Theme, CircleAvatar; // Minimal material
import 'package:provider/provider.dart';
import '../../models/program_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import 'submission_screen.dart';
import '../public/public_stats_screen.dart';

class WardDashboard extends StatelessWidget {
  const WardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        onTap: (index) => HapticFeedback.lightImpact(),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.graph_circle), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const _WardHomeTab();
          case 1:
            return CupertinoTabView(builder: (context) => const PublicStatsScreen());
          case 2:
            return const _WardSettingsTab();
          default:
            return const _WardHomeTab();
        }
      },
    );
  }
}

class _WardHomeTab extends StatelessWidget {
  const _WardHomeTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<AuthService>(context).currentUser;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Ward ${user?.wardId ?? ''} Dashboard"),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Text(
                "Active Programs",
                 style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ProgramModel>>(
                stream: firestoreService.getProgramsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: CupertinoColors.destructiveRed)));
                  if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());

                  // Filter only active programs for Ward Admin
                  final programs = snapshot.data!.where((p) => p.isActive).toList();
                  
                  if (programs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.doc_checkmark, size: 64, color: CupertinoColors.systemGrey),
                          const SizedBox(height: 16),
                          Text("No active programs assigned.", style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: programs.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final program = programs[index];
                      return AnimatedEntry(
                        delay: Duration(milliseconds: index * 100),
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              CupertinoPageRoute(
                                builder: (_) => SubmissionScreen(program: program),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.doc_text, 
                                  color: CupertinoColors.activeBlue
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      program.name, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Due: ${program.endDate.toIso8601String().split('T')[0]}",
                                      style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardSettingsTab extends StatelessWidget {
  const _WardSettingsTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = auth.currentUser;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Settings"),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Centered Profile Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: CupertinoColors.systemGrey2, 
                    child: Text(
                      user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : "W",
                      style: const TextStyle(fontSize: 40, color: CupertinoColors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? "Ward Admin",
                    style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ward ${user?.wardId ?? 'Unknown'}",
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user?.email ?? "",
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.moon_fill, color: CupertinoColors.systemIndigo),
                  title: const Text("Dark Mode"),
                  trailing: CupertinoSwitch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ),
              ],
            ),
            
            const Spacer(),

             CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.arrow_right_square, color: CupertinoColors.destructiveRed),
                  title: const Text("Logout", style: TextStyle(color: CupertinoColors.destructiveRed)),
                  onTap: () {
                    auth.logout();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
