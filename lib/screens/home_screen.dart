import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/safety_session.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/safety_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safety_status_card.dart';
import '../widgets/sos_button.dart';
import 'campus_directory_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'report_issue_screen.dart';
import 'safe_arrival_screen.dart';
import 'sos_screen.dart';
import 'trusted_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SafetySessionService _sessionService = SafetySessionService();
  final AlertService _alertService = AlertService();

  void _triggerSosFlow() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.emergencyRed),
            SizedBox(width: 8),
            Text(
              'Confirm Emergency SOS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Do you need immediate assistance? This will log your GPS coordinates to Firestore and open emergency broadcast actions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SosScreen(autoTriggerOnOpen: true),
                ),
              );
            },
            child: const Text('YES, TRIGGER SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final uid = auth.currentUid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: AppTheme.tealAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CampusSOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Safe Campus Companion',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryNavy, Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(" ").first ?? "Student"} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.college ?? 'College Campus',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MyReportsScreen()),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'My Reports',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Safety Status Card
              StreamBuilder<SafetySession?>(
                stream: _sessionService.getActiveSessionStream(uid),
                builder: (context, snapshot) {
                  final activeSession = snapshot.data;
                  return SafetyStatusCard(
                    activeSession: activeSession,
                    onActionTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SafeArrivalScreen()),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Prominent Animated SOS Section
              Center(
                child: Column(
                  children: [
                    SosButton(
                      size: 160,
                      onPressed: _triggerSosFlow,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Press for immediate emergency assistance',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Core Safety Features Grid
              const Text(
                'Safety Hub',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.25,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.directions_walk,
                    iconColor: AppTheme.tealAccent,
                    title: 'Safe Journey',
                    subtitle: 'Check in on arrival',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SafeArrivalScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.people_alt_outlined,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Trusted Contacts',
                    subtitle: 'Manage safe circle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TrustedContactsScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.local_police_outlined,
                    iconColor: AppTheme.emergencyRed,
                    title: 'Campus Directory',
                    subtitle: 'Security & Wardens',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CampusDirectoryScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.report_problem_outlined,
                    iconColor: AppTheme.warningAmber,
                    title: 'Report Unsafe Area',
                    subtitle: 'Report streetlights & roads',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReportIssueScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Emergency Alerts Stream / Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Emergency Incidents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SosScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),

              StreamBuilder(
                stream: _alertService.getAlertsStream(uid),
                builder: (context, snapshot) {
                  final alerts = snapshot.data ?? [];
                  if (alerts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.tealAccent, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No active emergencies recorded. You are safe.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final latest = alerts.first;
                  final isResolved = latest.status == 'resolved';

                  return Card(
                    color: isResolved
                        ? Colors.white
                        : AppTheme.emergencyRedLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isResolved
                            ? AppTheme.borderLight
                            : AppTheme.emergencyRed,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isResolved
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: isResolved
                            ? AppTheme.tealAccent
                            : AppTheme.emergencyRed,
                      ),
                      title: Text(
                        latest.alertType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        latest.createdAt != null
                            ? DateFormat('MMM d • h:mm a')
                                .format(latest.createdAt!)
                            : 'Recent',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        latest.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isResolved
                              ? AppTheme.tealAccent
                              : AppTheme.emergencyRed,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
