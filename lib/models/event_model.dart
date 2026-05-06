// ============================================================
// models/event_model.dart
// Hive model for an Event entity
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// ============================================================
import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 0)
class EventModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime dateTime;

  @HiveField(3)
  late int maxCapacity;

  @HiveField(4)
  late String description;

  @HiveField(5)
  late bool isActive;

  EventModel({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.maxCapacity,
    this.description = '',
    this.isActive = true,
  });

  /// Creates a copy with updated fields
  EventModel copyWith({
    String? id,
    String? name,
    DateTime? dateTime,
    int? maxCapacity,
    String? description,
    bool? isActive,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'EventModel(id: $id, name: $name, maxCapacity: $maxCapacity)';
}
