import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter/material.dart' show Colors, Icons, CircleAvatar, LinearGradient, Alignment; // Minimal material
import 'package:provider/provider.dart';
import '../../models/program_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import 'create_program_screen.dart';
import 'user_management_screen.dart';
import '../public/public_stats_screen.dart';
import '../../providers/theme_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Programs'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.group), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const _AdminProgramsTab();
          case 1:
            return CupertinoTabView(builder: (context) => const UserManagementScreen());
          case 2:
            return const _AdminSettingsTab();
          default:
            return const _AdminProgramsTab();
        }
      },
    );
  }
}

class _AdminProgramsTab extends StatefulWidget {
  const _AdminProgramsTab();

  @override
  State<_AdminProgramsTab> createState() => _AdminProgramsTabState();
}

class _AdminProgramsTabState extends State<_AdminProgramsTab> {
  final Set<String> _selectedProgramIds = {};
  String _searchQuery = "";

  bool get _isSelectionMode => _selectedProgramIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedProgramIds.contains(id)) {
        _selectedProgramIds.remove(id);
      } else {
        _selectedProgramIds.add(id);
      }
    });
  }

  void _deleteSelected(FirestoreService db) async {
    final count = _selectedProgramIds.length;
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("Delete $count Programs?"),
        content: const Text("This action cannot be undone."),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedProgramIds) {
        await db.deleteProgram(id);
      }
      setState(() {
        _selectedProgramIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isSelectionMode ? "${_selectedProgramIds.length} Selected" : "Admin Dashboard"),
        leading: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text("Done"),
                onPressed: () => setState(() => _selectedProgramIds.clear()),
              )
            : null,
        trailing: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
                onPressed: () => _deleteSelected(firestoreService),
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(builder: (_) => const CreateProgramScreen())
                  );
                },
                child: const Icon(CupertinoIcons.add),
              ),
      ),
      child: SafeArea(
        child: StreamBuilder<List<ProgramModel>>(
          stream: firestoreService.getProgramsStream(),
          builder: (context, snapshot) {
            Widget contentSliver;

            if (snapshot.hasError) {
              contentSliver = SliverFillRemaining(child: Center(child: Text("Error: ${snapshot.error}")));
            } else if (!snapshot.hasData) {
              contentSliver = const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()));
            } else {
              final allPrograms = snapshot.data!;
              final programs = allPrograms.where((p) => 
                p.name.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList();

              if (programs.isEmpty) {
                 if (allPrograms.isEmpty) {
                     // No programs at all
                     contentSliver = SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.folder_open, size: 64, color: CupertinoColors.systemGrey),
                              const SizedBox(height: 16),
                              const Text("No active programs found."),
                              const SizedBox(height: 8),
                               CupertinoButton(
                                onPressed: () {
                                   Navigator.of(context, rootNavigator: true).push(
                                      CupertinoPageRoute(builder: (_) => const CreateProgramScreen())
                                    );
                                },
                                child: const Text("Create First Program"),
                              )
                            ],
                          ),
                        ),
                      );
                 } else {
                    // Search found nothing
                    contentSliver = const SliverFillRemaining(child: Center(child: Text("No programs found matching query.")));
                 }
              } else {
                 contentSliver = SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final program = programs[index];
                        final isSelected = _selectedProgramIds.contains(program.id);

                        return AnimatedEntry(
                          delay: Duration(milliseconds: index * 50),
                          child: GestureDetector(
                            onLongPress: () => _toggleSelection(program.id),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(program.id);
                              } else {
                                 Navigator.of(context, rootNavigator: true).push(
                                    CupertinoPageRoute(builder: (_) => CreateProgramScreen(programToEdit: program))
                                  );
                              }
                            },
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              opacity: isSelected ? 0.9 : 0.7,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeBlue),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                program.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17, 
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: program.isActive ? CupertinoColors.activeGreen.withOpacity(0.1) : CupertinoColors.systemGrey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                program.isActive ? "Active" : "Inactive",
                                                style: TextStyle(
                                                  color: program.isActive ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(CupertinoIcons.calendar, size: 14, color: CupertinoColors.systemGrey),
                                            const SizedBox(width: 4),
                                            Text(
                                              program.startDate.toIso8601String().split('T')[0],
                                              style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(CupertinoIcons.list_bullet, size: 14, color: CupertinoColors.systemGrey),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${program.fields.length} Fields",
                                              style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                         if (!_isSelectionMode) ...[ 
                                             Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(height: 1, color: CupertinoColors.separator),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Text("Status:", style: TextStyle(fontSize: 13)),
                                                      const SizedBox(width: 8),
                                                      CupertinoSwitch(
                                                        value: program.isActive,
                                                        onChanged: (val) {
                                                          firestoreService.toggleProgramStatus(program.id, val);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  const Row(
                                                    children: [
                                                      Text("Edit", style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 13)),
                                                      Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.activeBlue),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                         ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: programs.length,
                    ),
                  ),
                );
              }
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                     await Future.delayed(const Duration(seconds: 1));
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoSearchTextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "MANAGE PROGRAMS",
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                color: CupertinoColors.systemGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                contentSliver,
              ],
            );
          },
        ),
      ),
    );
  }
}


class _AdminSettingsTab extends StatelessWidget {
  const _AdminSettingsTab();

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
                    backgroundColor: CupertinoColors.systemGrey2, // No const here if needed, but color is const
                    child: Text(
                      user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : "A",
                      style: const TextStyle(fontSize: 40, color: CupertinoColors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? "Admin",
                    style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "",
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
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
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.chart_bar_alt_fill),
                  title: const Text("Public Statistics"),
                  trailing: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey3),
                  onTap: () {
                     Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(builder: (_) => const PublicStatsScreen())
                      );
                  },
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
