import 'package:hive/hive.dart';
import 'dart:math';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) double price;
  @HiveField(3) DateTime purchaseDate;
  @HiveField(4) String category;
  @HiveField(5) List<int> usageHistory; 
  @HiveField(6) int manualClicks;
  @HiveField(7) String? imagePath;
  @HiveField(8) DateTime? consumedDate;
  @HiveField(9) bool isSubscription;
  @HiveField(10) String? subscriptionPeriod; 
  @HiveField(11) String? emoji;
  @HiveField(12) int? projectedLifespanDays;
  @HiveField(13) int estimatedUsageCount; 
  @HiveField(14) String usagePeriod; 
  @HiveField(15) double? targetCost; 

  Item({
    String? id, required this.name, required this.price, required this.purchaseDate, required this.category,
    this.usageHistory = const [], this.manualClicks = 0, this.imagePath, this.consumedDate,
    this.isSubscription = false, this.subscriptionPeriod, this.emoji, this.projectedLifespanDays,
    this.estimatedUsageCount = 0, this.usagePeriod = 'week', this.targetCost,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get isActive => consumedDate == null;
  int get daysOwned => max(1, (consumedDate ?? DateTime.now()).difference(purchaseDate).inDays);
  double get pricePerDay => price / (isSubscription && subscriptionPeriod == 'month' ? 30 : (isSubscription && subscriptionPeriod == 'year' ? 365 : daysOwned));
  
  double get totalUsesCalculated {
    if (usageHistory.isNotEmpty) return usageHistory.length.toDouble();
    if (manualClicks > 0) return manualClicks.toDouble();
    if (isSubscription) return 0; 
    double dailyRate = 0;
    if (estimatedUsageCount > 0) {
      if (usagePeriod == 'day') dailyRate = estimatedUsageCount.toDouble();
      else if (usagePeriod == 'week') dailyRate = estimatedUsageCount / 7.0;
      else if (usagePeriod == 'month') dailyRate = estimatedUsageCount / 30.0;
      else if (usagePeriod == 'year') dailyRate = estimatedUsageCount / 365.0;
    }
    return daysOwned * dailyRate;
  }
  
  double get costPerUse {
    double uses = totalUsesCalculated;
    if (uses <= 0) return price;
    return price / uses;
  }
}