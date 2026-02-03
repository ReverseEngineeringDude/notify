import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/program_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/modern_scaffold.dart';
import '../../widgets/common/animated_entry.dart';
import '../../widgets/common/interactive_graph.dart';
import '../../widgets/common/stat_card.dart';
import '../../screens/admin/program_details_screen.dart';
import '../../services/auth_service.dart';

class PublicStatsScreen extends StatelessWidget {
  const PublicStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = Provider.of<AuthService>(context).currentUser;
    final isAdmin = user?.role == UserRole.superAdmin || user?.role == UserRole.wardAdmin; // Basic check

    // Grid Layout Delegate
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 600,
      mainAxisExtent: 380, // Slightly increased for better spacing
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );

    return ModernScaffold(
      appBar: AppBar(
        title: const Text("Public Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<ProgramModel>>(
        stream: firestoreService.getProgramsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          print("Error: ${snapshot.error}");
          final programs = snapshot.data!.where((p) => p.isActive).toList();

          if (programs.isEmpty) {
            return const Center(child: Text("No active programs to display."));
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      "Live Statistics",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final program = programs[index];

                      return StreamBuilder<List<SubmissionModel>>(
                        stream: firestoreService.getSubmissionsForProgram(program.id),
                        builder: (context, submissionSnapshot) {
                           // Default / Empty State
                           List<double> dataPoints = List.filled(7, 0.0);
                           List<String> labels = List.generate(7, (i) {
                             final d = DateTime.now().subtract(Duration(days: 6 - i));
                             return DateFormat.E().format(d);
                           });
                           int totalEntries = 0;
                           String growthText = "0%";
                           bool isPositiveGrowth = true;

                           if (submissionSnapshot.hasError) {
                             debugPrint("Firestore Error (PublicStats): ${submissionSnapshot.error}");
                             return AnimatedEntry(
                               delay: Duration(milliseconds: index * 100),
                               child: StatCard(
                                 title: program.name,
                                 trailing: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                 child: Center(
                                   child: Text(
                                     "Error loading data",
                                     style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                                   ),
                                 ),
                               ),
                             );
                           }

                           if (submissionSnapshot.hasData) {
                             final submissions = submissionSnapshot.data!;
                             totalEntries = submissions.length;
                             
                             final stats = _aggregateData(submissions);
                             dataPoints = stats.dataPoints;
                             labels = stats.labels;
                             growthText = stats.growthPercentage;
                             isPositiveGrowth = stats.isPositiveGrowth;
                           }

                           return AnimatedEntry(
                            delay: Duration(milliseconds: index * 100),
                            child: GestureDetector(
                              onTap: () {
                                if (isAdmin) {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => ProgramDetailsScreen(program: program))
                                  );
                                }
                              },
                              child: StatCard(
                                title: program.name,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text("ACTIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: InteractiveGraph(
                                        dataPoints: dataPoints,
                                        labels: labels,
                                        color: (index % 2 == 0) ? Colors.indigo : Colors.purple,
                                        maxHeight: 180,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Weekly Growth", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                growthText, 
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  color: isPositiveGrowth ? Colors.green : Colors.red
                                                )
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text("Total Entries", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text("$totalEntries", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        } // End Submission Stream Builder
                      );
                    },
                    childCount: programs.length,
                  ),
                  gridDelegate: gridDelegate,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }

  // Aggregation Logic
  _StatsResult _aggregateData(List<SubmissionModel> submissions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Initialize Last 7 Days Buckets
    final Map<DateTime, int> dailyCounts = {};
    final List<String> labels = [];
    final List<double> dataPoints = [];

    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dailyCounts[d] = 0;
      labels.add(DateFormat.E().format(d));
    }

    // 2. Populate Buckets from Data
    int currentPeriodCount = 0;
    int previousPeriodCount = 0;
    
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final fourteenDaysAgo = today.subtract(const Duration(days: 13));

    for (var s in submissions) {
      final d = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      
      // Fill Graph Data (Last 7 Days)
      if (dailyCounts.containsKey(d)) {
         dailyCounts[d] = dailyCounts[d]! + 1;
      }

      // Calculate Growth (Last 7 Days vs Previous 7 Days)
      // Check if within last 7 days (inclusive of today)
      if (!d.isBefore(sevenDaysAgo) && !d.isAfter(today.add(const Duration(days: 1)))) {
        currentPeriodCount++;
      }
      // Check if within previous 7 days
      else if (!d.isBefore(fourteenDaysAgo) && d.isBefore(sevenDaysAgo)) {
        previousPeriodCount++;
      }
    }

    // Convert Map to List
    dailyCounts.forEach((key, value) {
      dataPoints.add(value.toDouble());
    });

    // 3. Calculate Growth %
    double growth = 0.0;
    if (previousPeriodCount > 0) {
      growth = ((currentPeriodCount - previousPeriodCount) / previousPeriodCount) * 100;
    } else if (currentPeriodCount > 0) {
      growth = 100.0; // 100% growth if started from 0
    }

    return _StatsResult(
      dataPoints: dataPoints,
      labels: labels,
      growthPercentage: "${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%",
      isPositiveGrowth: growth >= 0,
    );
  }
}

class _StatsResult {
  final List<double> dataPoints;
  final List<String> labels;
  final String growthPercentage;
  final bool isPositiveGrowth;

  _StatsResult({
    required this.dataPoints,
    required this.labels,
    required this.growthPercentage,
    required this.isPositiveGrowth,
  });
}
