// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_type, invalid_use_of_protected_member

part of 'check_in_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckInMethodAdapter extends TypeAdapter<CheckInMethod> {
  @override
  final int typeId = 2;

  @override
  CheckInMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CheckInMethod.qr;
      case 1:
        return CheckInMethod.manual;
      default:
        return CheckInMethod.manual;
    }
  }

  @override
  void write(BinaryWriter writer, CheckInMethod obj) {
    switch (obj) {
      case CheckInMethod.qr:
        writer.writeByte(0);
        break;
      case CheckInMethod.manual:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CheckInLogModelAdapter extends TypeAdapter<CheckInLogModel> {
  @override
  final int typeId = 3;

  @override
  CheckInLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckInLogModel(
      id: fields[0] as String,
      participantId: fields[1] as String,
      participantName: fields[2] as String,
      eventId: fields[3] as String,
      method: fields[5] as CheckInMethod,
      timestamp: fields[4] as DateTime,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CheckInLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.participantId)
      ..writeByte(2)
      ..write(obj.participantName)
      ..writeByte(3)
      ..write(obj.eventId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.method)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
