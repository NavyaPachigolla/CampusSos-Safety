import 'package:flutter/material.dart';
import '../models/campus_contact.dart';
import '../services/alert_service.dart';
import '../services/campus_directory_service.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';

class CampusDirectoryScreen extends StatefulWidget {
  const CampusDirectoryScreen({super.key});

  @override
  State<CampusDirectoryScreen> createState() => _CampusDirectoryScreenState();
}

class _CampusDirectoryScreenState extends State<CampusDirectoryScreen> {
  final CampusDirectoryService _directoryService = CampusDirectoryService();
  final AlertService _alertService = AlertService();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Security',
    'Medical',
    'Hostel',
    'Support',
    'Police',
  ];

  @override
  void initState() {
    super.initState();
    _directoryService.seedDefaultContactsIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Campus Directory'),
      ),
      body: Column(
        children: [
          // Search & Category Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search campus security, warden, medical...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
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
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Notice banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.tealLight.withValues(alpha: 0.4),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 16, color: AppTheme.tealAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Official Campus Contacts • Managed by campus administration',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contacts List
          Expanded(
            child: StreamBuilder<List<CampusContact>>(
              stream: _directoryService.getContactsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading directory...');
                }

                final all = snapshot.data ?? [];
                final filtered = all.where((c) {
                  final matchesCat = _selectedCategory == 'All' ||
                      c.category.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                  final matchesSearch = _searchQuery.isEmpty ||
                      c.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      c.locationDescription
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      c.phone.contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No Contacts Found',
                    message:
                        'No campus contacts match your current category or search criteria.',
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return ContactCard(
                      name: contact.name,
                      subtitle: contact.locationDescription,
                      phone: contact.phone,
                      badgeText: contact.category,
                      badgeColor: contact.category == 'Security'
                          ? AppTheme.emergencyRed
                          : contact.category == 'Medical'
                              ? AppTheme.tealAccent
                              : AppTheme.primaryNavy,
                      onCall: () =>
                          _alertService.callEmergencyPhone(contact.phone),
                      onSms: () => _alertService.sendEmergencySms(
                        contact.phone,
                        'Campus Inquiry: Reaching out from CampusSOS app.',
                      ),
                      onEdit: null, // Read-only for ordinary students
                      onDelete: null,
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
