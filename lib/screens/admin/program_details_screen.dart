import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Theme, CircleAvatar; // Minimal material for compatibility
import 'package:provider/provider.dart';
import '../../models/program_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final ProgramModel program;

  const ProgramDetailsScreen({super.key, required this.program});

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  String? _selectedWardId; 
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  int _submissionLimit = 20; // Pagination limit

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final authService = Provider.of<AuthService>(context);
    final isSuperAdmin = authService.currentUser?.role == UserRole.superAdmin;

    return ModernScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.program.name),
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
                     final submissions = await firestoreService.getSubmissionsForProgramFuture(widget.program.id);
                     // Fetch users to map IDs to Names
                     final users = await firestoreService.getUsersFuture();
                     final userMap = {for (var u in users) u.uid: u.name ?? "Unknown"};
                     
                     await _exportService.exportSubmissionsToPdf(submissions, widget.program, userMap);
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
            if (_selectedWardId != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.clear_circled),
                onPressed: () => setState(() => _selectedWardId = null),
              ),
          ],
        ),
      ),
      body: StreamBuilder<List<SubmissionModel>>(
        stream: firestoreService.getSubmissionsForProgram(widget.program.id, limit: _submissionLimit),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: CupertinoColors.destructiveRed)));
          }
          if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());

          var submissions = snapshot.data!;

          // --- ANALYTICS LOGIC (Super Admin Only) ---
          List<Map<String, dynamic>> topWards = [];
          List<String> availableWards = [];

          if (isSuperAdmin) {
            // Aggregate Ward Stats
            final Map<String, int> wardCounts = {};
            final Map<String, double> wardAmounts = {}; 

            for (var s in submissions) {
              wardCounts[s.wardId] = (wardCounts[s.wardId] ?? 0) + 1;
              availableWards.add(s.wardId);
              
              for (var key in s.data.keys) {
                if (key.toLowerCase().contains('amount')) {
                  final amtStr = s.data[key].toString();
                  final amt = double.tryParse(amtStr) ?? 0.0;
                  wardAmounts[s.wardId] = (wardAmounts[s.wardId] ?? 0) + amt;
                }
              }
            }
            availableWards = availableWards.toSet().toList()..sort();

            // Create sorted list of top wards
            topWards = wardCounts.entries.map((e) {
              return {
                'wardId': e.key,
                'count': e.value,
                'totalAmount': wardAmounts[e.key] ?? 0.0,
              };
            }).toList();
            
            topWards.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
            if (topWards.length > 3) topWards = topWards.sublist(0, 3);
          }

          // --- FILTERING ---
          if (!isSuperAdmin) {
            // Ward Admin sees only their own submissions
            if (authService.currentUser != null) {
               submissions = submissions.where((s) => s.submittedBy == authService.currentUser!.uid).toList();
            }
          }

          if (_selectedWardId != null) {
            submissions = submissions.where((s) => s.wardId == _selectedWardId).toList();
          }

          if (submissions.isEmpty && _selectedWardId == null) {
             return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.tray, size: 64, color: CupertinoColors.systemGrey),
                  const SizedBox(height: 16),
                  Text("No submissions yet.", style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey)),
                ],
              ),
            );
          }

          return Container(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context), // Base background color
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                   onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                ),
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- ANALYTICS SECTION (Super Admin) ---
                          if (isSuperAdmin && topWards.isNotEmpty) ...[
                            Text("Top Performing Wards", style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 20)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150, // Increased height to prevent overflow
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: topWards.length,
                                itemBuilder: (context, index) {
                                  final ward = topWards[index];
                                  final isFirst = index == 0;
                                  // Gold, Silver, Bronze effect
                                  final Color medalColor = index == 0 
                                      ? const Color(0xFFFFD700) 
                                      : index == 1 
                                          ? const Color(0xFFC0C0C0) 
                                          : const Color(0xFFCD7F32);

                                  return Container(
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: isFirst ? Border.all(color: medalColor.withOpacity(0.5), width: 2) : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Ward ${ward['wardId']}", 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: CupertinoTheme.of(context).textTheme.textStyle.color)
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemIndigo.resolveFrom(context).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text("${ward['count']} entries", style: TextStyle(color: CupertinoColors.systemIndigo.resolveFrom(context), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        if (ward['totalAmount'] > 0) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            "₹${(ward['totalAmount'] as double).toStringAsFixed(0)}", 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.activeGreen, fontSize: 15)
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // --- FILTER ROW ---
                          if (isSuperAdmin && availableWards.isNotEmpty)
                            GestureDetector(
                               onTap: () => _showFilterPicker(context, availableWards),
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                 decoration: BoxDecoration(
                                   color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                                   borderRadius: BorderRadius.circular(10),
                                 ),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Row(
                                       children: [
                                         const Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: CupertinoColors.systemGrey),
                                         const SizedBox(width: 8),
                                         Text("Filter by Ward", style: CupertinoTheme.of(context).textTheme.textStyle),
                                       ],
                                     ),
                                     Row(
                                       children: [
                                         Text(
                                           _selectedWardId ?? "All", 
                                           style: const TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold)
                                         ),
                                         const SizedBox(width: 4),
                                         const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.activeBlue),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                            ),
                           if (isSuperAdmin && availableWards.isNotEmpty) const SizedBox(height: 20),
                           
                           Text("Recent Contributions", style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- SUBMISSIONS LIST ---
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final submission = submissions[index];
                      final isOwner = authService.currentUser?.uid == submission.submittedBy;
                      final canDelete = isSuperAdmin || isOwner;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER: User Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: FutureBuilder<UserModel?>(
                                  future: firestoreService.getUser(submission.submittedBy),
                                  builder: (context, userSnapshot) {
                                    final user = userSnapshot.data;
                                    final userName = user?.name ?? "Unknown User";
                                    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : "?";

                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: CupertinoColors.systemIndigo.resolveFrom(context),
                                          child: Text(initial, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                submission.timestamp.toIso8601String().split('T')[0],
                                                style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSuperAdmin) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: CupertinoColors.systemOrange.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Ward ${submission.wardId}", 
                                              style: const TextStyle(fontSize: 12, color: CupertinoColors.systemOrange, fontWeight: FontWeight.bold)
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        // DELETE BUTTON
                                        if (canDelete)
                                          CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 20),
                                            onPressed: () {
                                              showCupertinoDialog(
                                                context: context,
                                                builder: (ctx) => CupertinoAlertDialog(
                                                  title: const Text("Delete Submission?"),
                                                  content: const Text("Are you sure you want to delete this submission? This action cannot be undone."),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                      isDefaultAction: true,
                                                      child: const Text("Cancel"),
                                                      onPressed: () => Navigator.pop(ctx),
                                                    ),
                                                    CupertinoDialogAction(
                                                      isDestructiveAction: true,
                                                      child: const Text("Delete"),
                                                      onPressed: () async {
                                                        Navigator.pop(ctx);
                                                        try {
                                                          await firestoreService.deleteSubmission(submission.id);
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            // Show error
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              
                              // DIVIDER
                              Container(height: 1, color: CupertinoColors.separator.resolveFrom(context).withOpacity(0.5)),

                              // BODY: Data
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: submission.data.entries.map((entry) {
                                     final isAmount = entry.key.toLowerCase().contains('amount');
                                     final key = entry.key;
                                     final value = entry.value.toString();

                                     return Padding(
                                       padding: const EdgeInsets.only(bottom: 8.0),
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(key, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 15)),
                                           Text(
                                               value, 
                                               style: TextStyle(
                                                 fontWeight: FontWeight.w600, 
                                                 color: isAmount ? CupertinoColors.activeGreen : CupertinoTheme.of(context).textTheme.textStyle.color,
                                                  fontSize: 15
                                               )
                                           ),
                                         ],
                                       ),
                                     );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: submissions.length,
                  ),
                ),

                // Pagination Loader
                if (submissions.length >= _submissionLimit)
                  SliverToBoxAdapter(
                     child: Padding(
                       padding: const EdgeInsets.all(24.0),
                       child: Center(
                         child: CupertinoButton(
                           child: const Text("Load More"),
                           onPressed: () {
                              setState(() {
                                _submissionLimit += 20;
                              });
                           },
                         ),
                       ),
                     ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFilterPicker(BuildContext context, List<String> wards) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text("Filter by Ward"),
        actions: [
          CupertinoActionSheetAction(
             child: const Text("All Wards"),
             onPressed: () {
               setState(() => _selectedWardId = null);
               Navigator.pop(ctx);
             },
          ),
          ...wards.map((w) => CupertinoActionSheetAction(
            child: Text("Ward $w"),
            onPressed: () {
              setState(() => _selectedWardId = w);
              Navigator.pop(ctx);
            },
          )),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
      ),
    );
  }
}
