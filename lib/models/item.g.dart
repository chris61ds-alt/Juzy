// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String?,
      name: fields[1] as String,
      price: fields[2] as double,
      purchaseDate: fields[3] as DateTime,
      category: fields[4] as String,
      usageHistory: (fields[5] as List).cast<int>(),
      manualClicks: fields[6] as int,
      imagePath: fields[7] as String?,
      consumedDate: fields[8] as DateTime?,
      isSubscription: fields[9] as bool,
      subscriptionPeriod: fields[10] as String?,
      emoji: fields[11] as String?,
      projectedLifespanDays: fields[12] as int?,
      estimatedUsageCount: fields[13] as int,
      usagePeriod: fields[14] as String,
      targetCost: fields[15] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.purchaseDate)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.usageHistory)
      ..writeByte(6)
      ..write(obj.manualClicks)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.consumedDate)
      ..writeByte(9)
      ..write(obj.isSubscription)
      ..writeByte(10)
      ..write(obj.subscriptionPeriod)
      ..writeByte(11)
      ..write(obj.emoji)
      ..writeByte(12)
      ..write(obj.projectedLifespanDays)
      ..writeByte(13)
      ..write(obj.estimatedUsageCount)
      ..writeByte(14)
      ..write(obj.usagePeriod)
      ..writeByte(15)
      ..write(obj.targetCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
