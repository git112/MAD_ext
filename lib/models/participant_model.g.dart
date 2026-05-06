// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_type, invalid_use_of_protected_member

part of 'participant_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParticipantModelAdapter extends TypeAdapter<ParticipantModel> {
  @override
  final int typeId = 1;

  @override
  ParticipantModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParticipantModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String,
      eventId: fields[4] as String,
      isCheckedIn: fields[5] as bool,
      registeredAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ParticipantModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.eventId)
      ..writeByte(5)
      ..write(obj.isCheckedIn)
      ..writeByte(6)
      ..write(obj.registeredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
