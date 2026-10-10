import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContactCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String phone;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onCall;
  final VoidCallback? onSms;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.phone,
    this.badgeText,
    this.badgeColor,
    required this.onCall,
    this.onSms,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
              foregroundColor: AppTheme.primaryNavy,
              radius: 22,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? AppTheme.tealAccent)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              color: badgeColor ?? AppTheme.tealAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_in_talk, color: AppTheme.tealAccent),
                  tooltip: 'Call',
                  onPressed: onCall,
                ),
                if (onSms != null)
                  IconButton(
                    icon: const Icon(Icons.sms_outlined, color: AppTheme.primaryNavy),
                    tooltip: 'Send SMS',
                    onPressed: onSms,
                  ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) onEdit!();
                      if (value == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 18, color: AppTheme.emergencyRed),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style:
                                      TextStyle(color: AppTheme.emergencyRed)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
