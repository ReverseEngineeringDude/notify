import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Haptics
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _wardIdController = TextEditingController();
  UserRole _selectedRole = UserRole.wardAdmin;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Create New User"),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Create a new administrator account.\nNOTE: You will be signed out to create this account.",
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text("ACCOUNT DETAILS"),
                    children: [
                      CupertinoTextFormFieldRow(
                        controller: _emailController,
                        placeholder: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(CupertinoIcons.mail, color: CupertinoColors.systemGrey),
                      ),
                      CupertinoTextFormFieldRow(
                        controller: _passwordController,
                        placeholder: "Password",
                        obscureText: true,
                         prefix: const Icon(CupertinoIcons.lock, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text("ROLE & PERMISSIONS"),
                    children: [
                      GestureDetector(
                        onTap: () => _showRolePicker(context),
                        child: CupertinoFormRow(
                          prefix: const Text("Role"),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _selectedRole.name.toUpperCase(),
                                style: const TextStyle(color: CupertinoColors.activeBlue),
                              ),
                              const SizedBox(width: 8),
                              const Icon(CupertinoIcons.chevron_up_chevron_down, size: 16, color: CupertinoColors.systemGrey),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedRole == UserRole.wardAdmin)
                        CupertinoTextFormFieldRow(
                          controller: _wardIdController,
                          placeholder: "Ward ID (e.g. Ward-01)",
                           prefix: const Icon(CupertinoIcons.map_pin, color: CupertinoColors.systemGrey),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : () {
                        HapticFeedback.mediumImpact();
                        _submit();
                      },
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text("Create User"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text("Done"),
                  onPressed: () => Navigator.pop(ctx),
                )
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedRole = UserRole.values[index];
                  });
                },
                children: UserRole.values.map((role) {
                  return Center(child: Text(role.name.toUpperCase()));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
       showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Invalid Input"),
          content: const Text("Please check email and password (min 6 chars)."),
          actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(ctx))],
        ),
      );
      return;
    }
    
    if (_selectedRole == UserRole.wardAdmin && _wardIdController.text.isEmpty) {
       showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Missing Ward ID"),
          content: const Text("Ward ID is required for Ward Admins."),
          actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(ctx))],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.createNewUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        wardId: _selectedRole == UserRole.wardAdmin ? _wardIdController.text.trim() : null,
      );

      if (mounted) {
         await showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("User Created"),
            content: const Text("User created successfully. You have been logged out."),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"), 
                onPressed: () {
                   Navigator.pop(ctx);
                   Navigator.popUntil(context, (route) => route.isFirst); // Go back to login
                }
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
         showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: ()=>Navigator.pop(ctx))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
