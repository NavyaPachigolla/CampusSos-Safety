import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'my_reports_screen.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ReportService _reportService = ReportService();
  final LocationService _locationService = LocationService();

  String _selectedCategory = 'Broken Streetlight';
  bool _attachLocation = true;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;
  double? _detectedLat;
  double? _detectedLng;
  String? _locationStatusMessage;

  final List<String> _categories = [
    'Broken Streetlight',
    'Poorly Lit Pathway',
    'Broken Door / Gate Lock',
    'Isolated Walkway',
    'Harassment Hotspot',
    'Damaged Footpath / Road',
    'Overgrown Shrubs / Blindspot',
    'Other Safety Hazard',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationStatusMessage = 'Obtaining GPS coordinates...';
    });

    final res = await _locationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _isDetectingLocation = false;
        if (res.hasLocation) {
          _detectedLat = res.latitude;
          _detectedLng = res.longitude;
          _locationStatusMessage =
              'Location acquired (${_detectedLat!.toStringAsFixed(4)}, ${_detectedLng!.toStringAsFixed(4)})';
        } else {
          _locationStatusMessage = res.errorMessage ?? 'Location unavailable';
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        reporterUid: uid,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        attachCurrentLocation: _attachLocation,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.tealAccent),
                SizedBox(width: 8),
                Text('Report Submitted'),
              ],
            ),
            content: const Text(
              'Thank you for keeping our campus safe! Your report has been logged and sent for administrative review.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  );
                },
                child: const Text('View My Reports'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Report Unsafe Area'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReportsScreen()),
              );
            },
            icon: const Icon(Icons.history, color: Colors.white, size: 18),
            label: const Text(
              'My Reports',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Campus Hazard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Help campus facility managers and safety officers identify and fix dangerous locations quickly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hazard Category
                      const Text(
                        'Hazard Category *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Hazard Description
                      const Text(
                        'Describe Location & Problem *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Streetlight pole #14 between Engineering Quad and North Canteen is dead. Very dark after 8 PM.',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please provide details of the hazard';
                          }
                          if (v.trim().length < 10) {
                            return 'Please provide more details (at least 10 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Location Toggle & Status
                      CheckboxListTile(
                        value: _attachLocation,
                        onChanged: (v) =>
                            setState(() => _attachLocation = v ?? true),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Attach Current GPS Coordinates',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _locationStatusMessage ??
                              'Enables maintenance team to locate exact hazard pin on map.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _detectedLat != null
                                ? AppTheme.tealAccent
                                : AppTheme.textMuted,
                          ),
                        ),
                        secondary: _isDetectingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Retry GPS fetch',
                                onPressed: _fetchCurrentLocation,
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tealAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined, size: 20),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting to Campus Security...'
                              : 'Submit Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
