import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_alert.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/campus_directory_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';

class SosScreen extends StatefulWidget {
  final bool autoTriggerOnOpen;

  const SosScreen({super.key, this.autoTriggerOnOpen = false});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final AlertService _alertService = AlertService();
  bool _isTriggering = false;
  EmergencyAlert? _currentAlert;
  String? _deliveryNotice;

  @override
  void initState() {
    super.initState();
    if (widget.autoTriggerOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerEmergencyAlert();
      });
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to trigger an SOS alert')),
      );
      return;
    }

    setState(() {
      _isTriggering = true;
    });

    try {
      final studentName = auth.currentUser?.name ?? 'Student';
      final result = await _alertService.triggerSosAlert(
        ownerUid: uid,
        studentName: studentName,
      );

      setState(() {
        _currentAlert = result.alert;
        _deliveryNotice = result.deliveryNotice;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency SOS logged securely to Firestore!'),
            backgroundColor: AppTheme.emergencyRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $err'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTriggering = false);
      }
    }
  }

  Future<void> _resolveAlert(EmergencyAlert alert) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency Alert?'),
        content: const Text(
          'Are you safe now? This will mark the emergency alert as resolved in Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tealAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I am Safe'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _alertService.resolveAlert(alertId: alert.id, ownerUid: uid);
      if (mounted) {
        setState(() {
          if (_currentAlert?.id == alert.id) {
            _currentAlert = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert marked as resolved. Glad you are safe!'),
            backgroundColor: AppTheme.tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve alert: $e'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = LocationService.makeMapsUrl(lat, lng);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
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
        title: const Text('Emergency SOS Center'),
        backgroundColor: AppTheme.emergencyRed,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Emergency Trigger Card
            Card(
              color: AppTheme.emergencyRedLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.emergencyRed, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppTheme.emergencyRed,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'INSTANT CAMPUS SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emergencyRed,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record emergency incident with real-time GPS coordinates to Firestore and broadcast instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _isTriggering ? null : _triggerEmergencyAlert,
                      icon: _isTriggering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.touch_app, size: 22),
                      label: Text(
                        _isTriggering ? 'Recording Incident...' : 'TRIGGER SOS NOW',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emergencyRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Alert Panel (if triggered in this view)
            if (_currentAlert != null) ...[
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.tealAccent, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppTheme.tealAccent),
                          const SizedBox(width: 8),
                          const Text(
                            'Active Incident Logged',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.tealAccent,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentAlert!.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (_currentAlert!.latitude != null &&
                          _currentAlert!.longitude != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _openGoogleMaps(
                            _currentAlert!.latitude!,
                            _currentAlert!.longitude!,
                          ),
                          icon: const Icon(Icons.map_outlined,
                              size: 18, color: AppTheme.tealAccent),
                          label: Text(
                            'View GPS in Google Maps (${_currentAlert!.latitude!.toStringAsFixed(4)}, ${_currentAlert!.longitude!.toStringAsFixed(4)})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_deliveryNotice != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            _deliveryNotice!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _alertService.shareEmergencyMessage(
                                  message: _currentAlert!.message,
                                );
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share / SMS'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolveAlert(_currentAlert!),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('I am Safe'),
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
              ),
              const SizedBox(height: 16),
            ],

            // Direct Call Actions
            const Text(
              'Immediate Telephone Desks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final securityPhone =
                          CampusDirectoryService.fallbackContacts[0].phone;
                      _alertService.callEmergencyPhone(securityPhone);
                    },
                    icon: const Icon(Icons.phone_in_talk, size: 18),
                    label: const Text('Campus Security'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _alertService.callEmergencyPhone('911');
                    },
                    icon: const Icon(Icons.local_police, size: 18),
                    label: const Text('Police 911'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emergencyRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Alert History
            const Text(
              'Your SOS Incident History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<EmergencyAlert>>(
              stream: _alertService.getAlertsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading incidents...');
                }

                final alerts = snapshot.data ?? [];
                if (alerts.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'No Emergency Incidents',
                    message:
                        'You have not triggered any SOS alerts. Stay safe!',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final item = alerts[index];
                    final isResolved = item.status == 'resolved';
                    final dateStr = item.createdAt != null
                        ? DateFormat('MMM d, yyyy • h:mm a')
                            .format(item.createdAt!)
                        : 'Recent';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isResolved
                              ? AppTheme.tealLight
                              : AppTheme.emergencyRedLight,
                          child: Icon(
                            isResolved
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: isResolved
                                ? AppTheme.tealAccent
                                : AppTheme.emergencyRed,
                          ),
                        ),
                        title: Text(
                          item.alertType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item.message, maxLines: 2),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        trailing: isResolved
                            ? const Chip(
                                label: Text(
                                  'Resolved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.tealAccent,
                                  ),
                                ),
                                backgroundColor: AppTheme.tealLight,
                                side: BorderSide.none,
                              )
                            : OutlinedButton(
                                onPressed: () => _resolveAlert(item),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  side: const BorderSide(
                                      color: AppTheme.tealAccent),
                                ),
                                child: const Text(
                                  'Resolve',
                                  style: TextStyle(
                                    color: AppTheme.tealAccent,
                                    fontSize: 12,
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
