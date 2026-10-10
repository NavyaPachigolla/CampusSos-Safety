import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/safety_session.dart';
import '../services/auth_service.dart';
import '../services/safety_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import 'sos_screen.dart';

class SafeArrivalScreen extends StatefulWidget {
  const SafeArrivalScreen({super.key});

  @override
  State<SafeArrivalScreen> createState() => _SafeArrivalScreenState();
}

class _SafeArrivalScreenState extends State<SafeArrivalScreen> {
  final SafetySessionService _sessionService = SafetySessionService();
  final _destinationController = TextEditingController();
  int _selectedMinutes = 20;
  bool _isStarting = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _startNewJourney() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your destination')),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    setState(() => _isStarting = true);

    try {
      await _sessionService.startSession(
        ownerUid: uid,
        destination: destination,
        estimatedDuration: Duration(minutes: _selectedMinutes),
      );

      _destinationController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safe journey started! Countdown active.'),
            backgroundColor: AppTheme.tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _checkInSafely(SafetySession session) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    try {
      await _sessionService.checkInSafely(sessionId: session.id, ownerUid: uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in safely! Great job reaching your destination.'),
            backgroundColor: AppTheme.tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _cancelJourney(SafetySession session) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Journey?'),
        content: const Text(
          'Are you sure you want to stop this safe-arrival session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _sessionService.cancelSession(sessionId: session.id, ownerUid: uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey cancelled.'),
            backgroundColor: AppTheme.primaryNavy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Safe-Arrival Companion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Session Stream
            StreamBuilder<SafetySession?>(
              stream: _sessionService.getActiveSessionStream(uid),
              builder: (context, snapshot) {
                final activeSession = snapshot.data;

                if (activeSession != null) {
                  final isOverdue = activeSession.isOverdue;
                  final remaining = activeSession.remainingDuration;
                  final mins = remaining.inMinutes;
                  final secs = remaining.inSeconds % 60;
                  final timeFormatted =
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

                  return Card(
                    color: isOverdue
                        ? AppTheme.emergencyRedLight
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isOverdue
                            ? AppTheme.emergencyRed
                            : AppTheme.tealAccent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.timer,
                                color: isOverdue
                                    ? AppTheme.emergencyRed
                                    : AppTheme.tealAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOverdue
                                    ? 'JOURNEY OVERDUE'
                                    : 'ACTIVE JOURNEY COUNTDOWN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isOverdue
                                      ? AppTheme.emergencyRed
                                      : AppTheme.tealAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isOverdue ? 'EXPIRED' : timeFormatted,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: isOverdue
                                  ? AppTheme.emergencyRed
                                  : AppTheme.primaryNavy,
                              fontFeatures: const [],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Destination: ${activeSession.destination}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expected by: ${DateFormat('h:mm a').format(activeSession.expectedArrival)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You have not checked in within your expected travel time. If you need help, tap Emergency SOS immediately.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.emergencyRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SosScreen(
                                      autoTriggerOnOpen: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.warning, size: 18),
                              label: const Text('EMERGENCY SOS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emergencyRed,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _cancelJourney(activeSession),
                                  child: const Text('Cancel Journey'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _checkInSafely(activeSession),
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 18),
                                  label: const Text('I\'ve Arrived'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.tealAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // If no active session, show Start Journey Form
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_walk,
                                color: AppTheme.tealAccent),
                            SizedBox(width: 8),
                            Text(
                              'Start a Safe Journey',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tell CampusSOS where you are walking and your estimated arrival time. Check in when you get there safely!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _destinationController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Destination',
                            hintText: 'e.g. North Hostel, Library, Bus Stand',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Estimated Walking Duration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [10, 15, 20, 30, 45, 60].map((mins) {
                            final isSelected = _selectedMinutes == mins;
                            return ChoiceChip(
                              label: Text('$mins min'),
                              selected: isSelected,
                              selectedColor: AppTheme.tealLight,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.tealAccent
                                    : AppTheme.textDark,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedMinutes = mins);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isStarting ? null : _startNewJourney,
                          icon: _isStarting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.navigation_outlined, size: 20),
                          label: Text(_isStarting
                              ? 'Starting...'
                              : 'Begin Safe Journey'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.tealAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Foreground Check: Overdue tracking runs actively while the application is open. Real-time background notifications require OS background service permissions.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Journey History
            const Text(
              'Past Journeys',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<SafetySession>>(
              stream: _sessionService.getSessionHistoryStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading journeys...');
                }

                final allJourneys = snapshot.data ?? [];
                final pastJourneys =
                    allJourneys.where((s) => s.status != 'active').toList();

                if (pastJourneys.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.history,
                    title: 'No Completed Journeys',
                    message:
                        'Your completed and checked-in journeys will appear here.',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pastJourneys.length,
                  itemBuilder: (context, index) {
                    final item = pastJourneys[index];
                    final dateStr =
                        DateFormat('MMM d • h:mm a').format(item.startTime);

                    Color statusColor = AppTheme.tealAccent;
                    String statusLabel = 'Arrived';
                    if (item.status == 'cancelled') {
                      statusColor = AppTheme.textMuted;
                      statusLabel = 'Cancelled';
                    } else if (item.status == 'overdue') {
                      statusColor = AppTheme.emergencyRed;
                      statusLabel = 'Overdue';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              statusColor.withValues(alpha: 0.12),
                          child: Icon(
                            item.status == 'arrived'
                                ? Icons.check_circle_outline
                                : item.status == 'overdue'
                                    ? Icons.timer_off_outlined
                                    : Icons.cancel_outlined,
                            color: statusColor,
                          ),
                        ),
                        title: Text(
                          item.destination,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
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
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
