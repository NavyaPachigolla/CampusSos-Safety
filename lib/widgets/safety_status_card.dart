import 'package:flutter/material.dart';
import '../models/safety_session.dart';
import '../theme/app_theme.dart';

class SafetyStatusCard extends StatelessWidget {
  final SafetySession? activeSession;
  final VoidCallback onActionTap;

  const SafetyStatusCard({
    super.key,
    required this.activeSession,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeSession != null) {
      final isOverdue = activeSession!.isOverdue;
      final remaining = activeSession!.remainingDuration;
      final minutesLeft = remaining.inMinutes;

      final cardColor =
          isOverdue ? AppTheme.emergencyRedLight : AppTheme.tealLight;
      final borderColor =
          isOverdue ? AppTheme.emergencyRed : AppTheme.tealAccent;
      final iconColor =
          isOverdue ? AppTheme.emergencyRed : AppTheme.tealAccent;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                isOverdue ? Icons.timer_off_outlined : Icons.directions_walk,
                color: iconColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOverdue
                        ? 'OVERDUE JOURNEY'
                        : 'SAFE JOURNEY IN PROGRESS',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'To: ${activeSession!.destination}',
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOverdue
                        ? 'Expected arrival passed!'
                        : '$minutesLeft min remaining',
                    style: TextStyle(
                      color: isOverdue ? AppTheme.emergencyRed : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: borderColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isOverdue ? 'Alert' : 'View'),
            ),
          ],
        ),
      );
    }

    // Default: Safe status
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.tealAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY STATUS',
                  style: TextStyle(
                    color: AppTheme.tealAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ready & Protected',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Campus emergency services active',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppTheme.tealAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
