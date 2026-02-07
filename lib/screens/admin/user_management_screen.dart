import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, CircleAvatar; // Minimal material
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import 'create_user_screen.dart';

import '../../services/export_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = "";
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("User Management"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (_isExporting)
              const CupertinoActivityIndicator()
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.share),
                onPressed: () async {
                  setState(() => _isExporting = true);
                  try {
                    final users = await firestoreService.getUsersFuture();
                    await _exportService.exportUsersToPdf(users);
                  } catch (e) {
                     if (context.mounted) {
                        showCupertinoDialog(context: context, builder: (c) => CupertinoAlertDialog(
                          title: const Text("Export Failed"),
                          content: Text(e.toString()),
                          actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(c))],
                        ));
                     }
                  } finally {
                    if (mounted) setState(() => _isExporting = false);
                  }
                },
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.person_add),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(builder: (_) => const CreateUserScreen()),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: firestoreService.getUsersStream(),
          builder: (context, snapshot) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                   onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CupertinoSearchTextField(
                      onChanged: (value) {
                         setState(() {
                           _searchQuery = value;
                         });
                      },
                    ),
                  ),
                ),

                if (snapshot.hasError) 
                  SliverFillRemaining(child: Center(child: Text("Error: ${snapshot.error}")))
                else if (!snapshot.hasData) 
                  const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
                else
                  _buildUserListSliver(snapshot.data!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserListSliver(List<UserModel> allUsers) {
    final users = allUsers.where((u) => 
      (u.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    if (users.isEmpty) {
       return const SliverFillRemaining(child: Center(child: Text("No users found.")));
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = users[index];
            return AnimatedEntry(
              delay: Duration(milliseconds: index * 50),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CupertinoListTile(
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leadingSize: 40,
                  leading: CircleAvatar(
                    backgroundColor: user.role == UserRole.superAdmin ? CupertinoColors.systemPurple : CupertinoColors.systemTeal,
                    child: Icon(
                      user.role == UserRole.superAdmin ? CupertinoIcons.shield_fill : CupertinoIcons.person_fill,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    user.name ?? "Unnamed",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${user.email}\n${user.role.name} ${user.wardId != null ? '(${user.wardId})' : ''}",
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                  ),
                  trailing: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.systemGrey),
                  onTap: () => _showUserActions(context, user, Provider.of<FirestoreService>(context, listen: false)),
                ),
              ),
            );
          },
          childCount: users.length,
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, UserModel user, FirestoreService db) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text("Manage ${user.name ?? 'User'}"),
        message: Text(user.email),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditDialog(context, user, db);
            },
            child: const Text("Edit Name"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmResetPassword(context, user);
            },
            child: const Text("Reset Password"),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, user, db);
            },
            child: const Text("Delete User"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, UserModel user, FirestoreService db) {
    final nameController = TextEditingController(text: user.name);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Edit User"),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: "Full Name",
          ),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          CupertinoDialogAction(
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
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete User?"),
        content: Text("Are you sure you want to delete ${user.email}? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          CupertinoDialogAction(
            isDestructiveAction: true,
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
     showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Reset Password?"),
        content: Text("Send a password reset email to ${user.email}?"),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<AuthService>(context, listen: false).sendPasswordResetEmail(user.email);
                // No SnackBar in Cupertino, using a dialog or ignored as user will check email
                // showing a success dialog
                 if (context.mounted) {
                   showCupertinoDialog(context: context, builder: (c) => CupertinoAlertDialog(
                     title: const Text("Email Sent"), 
                     content: const Text("Password reset email has been sent."),
                     actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(c))],
                   ));
                 }
              } catch (e) {
                 if (context.mounted) {
                    showCupertinoDialog(context: context, builder: (c) => CupertinoAlertDialog(
                     title: const Text("Error"), 
                     content: Text(e.toString()),
                     actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(c))],
                   ));
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
