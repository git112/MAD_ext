// ============================================================
// models/check_in_log_model.dart
// Hive model for a check-in log entry
// ============================================================
import 'package:hive/hive.dart';

part 'check_in_log_model.g.dart';

/// Enum representing how a participant was checked in
@HiveType(typeId: 2)
enum CheckInMethod {
  @HiveField(0)
  qr,

  @HiveField(1)
  manual,
}

@HiveType(typeId: 3)
class CheckInLogModel extends HiveObject {
  @HiveField(0)
  late String id; // Unique log entry ID

  @HiveField(1)
  late String participantId;

  @HiveField(2)
  late String participantName;

  @HiveField(3)
  late String eventId;

  @HiveField(4)
  late DateTime timestamp;

  @HiveField(5)
  late CheckInMethod method;

  @HiveField(6)
  late bool isSynced; // Whether synced to cloud

  CheckInLogModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.eventId,
    required this.method,
    DateTime? timestamp,
    this.isSynced = false,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'CheckInLogModel(participantId: $participantId, timestamp: $timestamp, isSynced: $isSynced)';
}
