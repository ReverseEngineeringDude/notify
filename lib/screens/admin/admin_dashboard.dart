import 'package:flutter/material.dart';
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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Set<String> _selectedProgramIds = {};

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete $count Programs?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count programs deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return ModernScaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? "${_selectedProgramIds.length} Selected" : "Admin Dashboard"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedProgramIds.clear()),
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSelected(firestoreService),
            )
        ],
      ),
      drawer: _isSelectionMode ? null : Drawer(
        child: Consumer<AuthService>(
          builder: (context, auth, _) {
            final user = auth.currentUser;
            final name = user?.name ?? "Admin";
            final email = user?.email ?? "";
            final initials = name.isNotEmpty ? name[0].toUpperCase() : "A";

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, color: Colors.indigo),
                  title: const Text("Public Statistics"),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicStatsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
                  title: const Text("Manage Members"),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
                  },
                ),
                /*
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.indigo),
                  title: const Text("Export Report"),
                  onTap: () {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Exporting Report to PDF... (Simulation)")),
                    );
                  },
                ),
                */
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    auth.logout();
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          }
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              "Manage Programs",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProgramModel>>(
              stream: firestoreService.getProgramsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final programs = snapshot.data!;
                if (programs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("No active programs found."),
                        const SizedBox(height: 8),
                         ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProgramScreen()));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Create First Program"),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: programs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    final isSelected = _selectedProgramIds.contains(program.id);

                    return AnimatedEntry(
                       // Stagger animations slightly
                      delay: Duration(milliseconds: index * 50),
                      child: GestureDetector(
                        onLongPress: () => _toggleSelection(program.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(program.id);
                          } else {
                            // Navigate to Edit
                             Navigator.push(context, MaterialPageRoute(builder: (_) => CreateProgramScreen(programToEdit: program)));
                          }
                        },
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.zero, // Use padding inside stack or column
                          // Highlight if selected
                          opacity: isSelected ? 0.9 : 0.7,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            program.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                           const Icon(Icons.check_circle, color: Colors.indigo, size: 28)
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: program.isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: program.isActive ? Colors.green : Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              program.isActive ? "Active" : "Inactive",
                                              style: TextStyle(
                                                color: program.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Started: ${program.startDate.toIso8601String().split('T')[0]}",
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${program.fields.length} Fields",
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                     if (!_isSelectionMode) ...[ // Hide these controls during selection to prevent accidental taps
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Switch(
                                              value: program.isActive,
                                              onChanged: (val) {
                                                firestoreService.toggleProgramStatus(program.id, val);
                                              },
                                              activeColor: Theme.of(context).primaryColor,
                                            ),
                                            Text(
                                              "Tap to Edit Details", 
                                              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                                            ),
                                          ],
                                        ),
                                     ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.indigo, width: 2),
                                      color: Colors.indigo.withOpacity(0.05),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProgramScreen()));
        },
        label: const Text("New Program"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
