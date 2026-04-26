// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_chat_key.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveChatKeyAdapter extends TypeAdapter<HiveChatKey> {
  @override
  final int typeId = 0;

  @override
  HiveChatKey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveChatKey(
      chatId: fields[0] as String,
      sharedSecret: (fields[1] as List).cast<int>(),
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveChatKey obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.chatId)
      ..writeByte(1)
      ..write(obj.sharedSecret)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveChatKeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
