import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/program_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final ProgramModel program;

  const ProgramDetailsScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return ModernScaffold(
      appBar: AppBar(
        title: Text(program.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<SubmissionModel>>(
        stream: firestoreService.getSubmissionsForProgram(program.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Firestore Error (ProgramDetails): ${snapshot.error}");
            return Center(child: SelectableText("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final submissions = snapshot.data!;

          if (submissions.isEmpty) {
             return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("No submissions yet."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return AnimatedEntry(
                delay: Duration(milliseconds: index * 50),
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FutureBuilder<UserModel?>(
                              future: firestoreService.getUser(submission.submittedBy),
                              builder: (context, userSnapshot) {
                                final user = userSnapshot.data;
                                final userName = user?.name ?? "Unknown User";
                                final initial = userName.isNotEmpty ? userName[0].toUpperCase() : "?";

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.indigo.shade100,
                                      child: Text(
                                        initial,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "ID: ${submission.submittedBy.substring(0, 6)}...", // Short ID
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              submission.timestamp.toIso8601String().split('T')[0],
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...submission.data.entries.map((entry) {
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4),
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               SizedBox(
                                 width: 100,
                                 child: Text(
                                   entry.key, 
                                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700, fontSize: 13),
                                 ),
                               ),
                               Expanded(child: Text(entry.value.toString())),
                             ],
                           ),
                         );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
