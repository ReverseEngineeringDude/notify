import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/program_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/animated_entry.dart';
import 'submission_screen.dart';
import '../public/public_stats_screen.dart';

class WardDashboard extends StatelessWidget {
  const WardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<AuthService>(context).currentUser;

    return ModernScaffold(
      appBar: AppBar(
        title: Text("Ward ${user?.wardId ?? ''} Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: "View Public Stats",
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const PublicStatsScreen())
            ),
          ),
           IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Provider.of<AuthService>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              "Active Programs",
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

                // Filter only active programs for Ward Admin
                final programs = snapshot.data!.where((p) => p.isActive).toList();
                
                if (programs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("No active programs assigned."),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubmissionScreen(program: program),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_outlined, 
                                color: Theme.of(context).colorScheme.primary
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
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
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
    );
  }
}
