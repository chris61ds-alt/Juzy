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
      estimatedUsageCount: fields[4] as int,
      usagePeriod: fields[5] as String,
      isSubscription: fields[6] as bool,
      subscriptionPeriod: fields[7] as String,
      emoji: fields[8] as String?,
      imagePath: fields[9] as String?,
      category: fields[10] as String,
      manualClicks: fields[11] as int,
      consumedDate: fields[12] as DateTime?,
      targetCost: fields[13] as double?,
      projectedLifespanDays: fields[14] as int?,
      usageHistory: (fields[15] as List?)?.cast<int>(),
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
      ..write(obj.estimatedUsageCount)
      ..writeByte(5)
      ..write(obj.usagePeriod)
      ..writeByte(6)
      ..write(obj.isSubscription)
      ..writeByte(7)
      ..write(obj.subscriptionPeriod)
      ..writeByte(8)
      ..write(obj.emoji)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.manualClicks)
      ..writeByte(12)
      ..write(obj.consumedDate)
      ..writeByte(13)
      ..write(obj.targetCost)
      ..writeByte(14)
      ..write(obj.projectedLifespanDays)
      ..writeByte(15)
      ..write(obj.usageHistory);
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
