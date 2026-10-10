import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trusted_contact.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/trusted_contact_service.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final TrustedContactService _contactService = TrustedContactService();
  final AlertService _alertService = AlertService();

  void _showContactDialog({TrustedContact? existingContact}) {
    final isEditing = existingContact != null;
    final nameController =
        TextEditingController(text: existingContact?.name ?? '');
    final phoneController =
        TextEditingController(text: existingContact?.phone ?? '');
    String selectedRelationship = existingContact?.relationship ?? 'Roommate';

    final relationships = [
      'Roommate',
      'Parent',
      'Sibling',
      'Friend',
      'Hostel Warden',
      'Guardian',
      'Other',
    ];

    if (!relationships.contains(selectedRelationship)) {
      relationships.add(selectedRelationship);
    }

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Trusted Contact'
                              : 'Add Trusted Contact',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter contact name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '+1 234 567 8900',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRelationship,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                      items: relationships.map((rel) {
                        return DropdownMenuItem(value: rel, child: Text(rel));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedRelationship = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final auth = context.read<AuthService>();
                        final uid = auth.currentUid;
                        if (uid == null) return;
                        final messenger = ScaffoldMessenger.of(context);

                        Navigator.pop(ctx);

                        try {
                          if (isEditing) {
                            await _contactService.updateContact(
                              contactId: existingContact.id,
                              ownerUid: uid,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              relationship: selectedRelationship,
                            );
                          } else {
                            await _contactService.addContact(
                              ownerUid: uid,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              relationship: selectedRelationship,
                            );
                          }

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? 'Contact updated successfully'
                                    : 'Trusted contact added'),
                                backgroundColor: AppTheme.tealAccent,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppTheme.emergencyRed,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Contact',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteContact(TrustedContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text(
          'Are you sure you want to remove ${contact.name} from your trusted emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final auth = context.read<AuthService>();
    final uid = auth.currentUid;
    if (uid == null) return;

    try {
      await _contactService.deleteContact(
        contactId: contact.id,
        ownerUid: uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact removed'),
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
        title: const Text('Trusted Contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppTheme.tealAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Contact'),
      ),
      body: StreamBuilder<List<TrustedContact>>(
        stream: _contactService.getContactsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading contacts...');
          }

          final contacts = snapshot.data ?? [];
          if (contacts.isEmpty) {
            return EmptyStateView(
              icon: Icons.people_outline,
              title: 'No Trusted Contacts Yet',
              message:
                  'Add friends, roommates, or family members who should be reached in case of an emergency.',
              actionLabel: 'Add First Contact',
              onAction: () => _showContactDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ContactCard(
                name: contact.name,
                subtitle: contact.relationship,
                phone: contact.phone,
                badgeText: contact.relationship,
                badgeColor: AppTheme.tealAccent,
                onCall: () => _alertService.callEmergencyPhone(contact.phone),
                onSms: () => _alertService.sendEmergencySms(
                  contact.phone,
                  'CampusSOS Alert: ${auth.currentUser?.name ?? "I"} am reaching out for safety check-in.',
                ),
                onEdit: () => _showContactDialog(existingContact: contact),
                onDelete: () => _deleteContact(contact),
              );
            },
          );
        },
      ),
    );
  }
}
