import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campus_report.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import 'report_issue_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  Future<void> _openMaps(double lat, double lng) async {
    final url = LocationService.makeMapsUrl(lat, lng);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUid ?? '';
    final reportService = ReportService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Hazard Reports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
          );
        },
        backgroundColor: AppTheme.tealAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
      body: StreamBuilder<List<CampusReport>>(
        stream: reportService.getUserReportsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading your reports...');
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return EmptyStateView(
              icon: Icons.assignment_outlined,
              title: 'No Hazard Reports Yet',
              message:
                  'Help keep your campus safe by reporting broken lights, damaged roads, or poorly lit areas.',
              actionLabel: 'Report an Issue',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              Color statusColor = AppTheme.warningAmber;
              Color statusBg = AppTheme.warningLight;
              String statusLabel = 'Submitted';

              if (report.status == 'under_review') {
                statusColor = AppTheme.primaryNavy;
                statusBg = AppTheme.borderLight;
                statusLabel = 'Under Review';
              } else if (report.status == 'resolved') {
                statusColor = AppTheme.tealAccent;
                statusBg = AppTheme.tealLight;
                statusLabel = 'Resolved';
              }

              final dateStr = report.createdAt != null
                  ? DateFormat('MMM d, yyyy • h:mm a').format(report.createdAt!)
                  : 'Recent';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              report.category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          if (report.latitude != null &&
                              report.longitude != null)
                            TextButton.icon(
                              onPressed: () => _openMaps(
                                report.latitude!,
                                report.longitude!,
                              ),
                              icon: const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppTheme.tealAccent),
                              label: const Text(
                                'View on Map',
                                style: TextStyle(
                                  color: AppTheme.tealAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
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
