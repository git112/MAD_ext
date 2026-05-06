// ============================================================
// widgets/participant_tile.dart
// List tile for displaying participant info with check-in status
// ============================================================
import 'package:flutter/material.dart';
import '../models/participant_model.dart';
import '../utils/app_theme.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final VoidCallback? onTap;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = participant.isCheckedIn;
    final statusColor =
        isCheckedIn ? AppTheme.successColor : Colors.grey.shade400;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            participant.name.isNotEmpty
                ? participant.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          participant.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          'ID: ${participant.id}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                color: statusColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isCheckedIn ? 'Checked In' : 'Pending',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
