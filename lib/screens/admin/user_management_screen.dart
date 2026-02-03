import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import 'create_user_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return ModernScaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!;
          if (users.isEmpty) return const Center(child: Text("No users found."));

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = users[index];
              return AnimatedEntry(
                delay: Duration(milliseconds: index * 50),
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                child: ExpansionTile(
                    shape: const Border(), // Remove default borders
                    leading: CircleAvatar(
                      backgroundColor: user.role == UserRole.superAdmin ? Colors.deepPurpleAccent : Colors.teal,
                      child: Icon(
                        user.role == UserRole.superAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user.name ?? "Unnamed",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${user.email}\n${user.role.name} ${user.wardId != null ? '(${user.wardId})' : ''}",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text("Edit Name"),
                              onPressed: () => _showEditDialog(context, user, firestoreService),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                              label: const Text("Reset Pass", style: TextStyle(color: Colors.orange)),
                              onPressed: () => _confirmResetPassword(context, user),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              label: const Text("Delete", style: TextStyle(color: Colors.red)),
                              onPressed: () => _confirmDelete(context, user, firestoreService),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen()),
          );
        },
        label: const Text("Add User"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, UserModel user, FirestoreService db) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit User"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              db.updateUser(user.copyWith(name: nameController.text));
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user, FirestoreService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User?"),
        content: Text("Are you sure you want to delete ${user.email}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              db.deleteUser(user.uid);
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _confirmResetPassword(BuildContext context, UserModel user) {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Password?"),
        content: Text("Send a password reset email to ${user.email}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<AuthService>(context, listen: false).sendPasswordResetEmail(user.email);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset email sent!")));
                }
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Send Email"),
          ),
        ],
      ),
    );
  }
}
