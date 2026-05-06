// ============================================================
// models/participant_model.dart
// Hive model for a Participant entity
// ============================================================
import 'package:hive/hive.dart';

part 'participant_model.g.dart';

@HiveType(typeId: 1)
class ParticipantModel extends HiveObject {
  @HiveField(0)
  late String id; // Unique participant ID (used in QR)

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String email;

  @HiveField(3)
  late String phone;

  @HiveField(4)
  late String eventId; // Foreign key to EventModel

  @HiveField(5)
  late bool isCheckedIn;

  @HiveField(6)
  late DateTime registeredAt;

  ParticipantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.eventId,
    this.isCheckedIn = false,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  ParticipantModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? eventId,
    bool? isCheckedIn,
    DateTime? registeredAt,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      eventId: eventId ?? this.eventId,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  String toString() =>
      'ParticipantModel(id: $id, name: $name, isCheckedIn: $isCheckedIn)';
}
