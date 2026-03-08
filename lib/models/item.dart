import 'package:hive/hive.dart';
import 'dart:math';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final double price;
  @HiveField(3) final DateTime purchaseDate;
  @HiveField(4) final int estimatedUsageCount;
  @HiveField(5) final String usagePeriod; 
  @HiveField(6) final bool isSubscription;
  @HiveField(7) final String subscriptionPeriod; 
  @HiveField(8) final String? emoji;
  @HiveField(9) final String? imagePath;
  @HiveField(10) final String category;
  @HiveField(11) int manualClicks;
  @HiveField(12) DateTime? consumedDate;
  @HiveField(13) final double? targetCost;
  @HiveField(14) final int? projectedLifespanDays;
  @HiveField(15) List<int> usageHistory;

  Item({
    String? id,
    required this.name,
    required this.price,
    required this.purchaseDate,
    this.estimatedUsageCount = 0,
    this.usagePeriod = 'week',
    this.isSubscription = false,
    this.subscriptionPeriod = 'month',
    this.emoji,
    this.imagePath,
    required this.category,
    this.manualClicks = 0,
    this.consumedDate,
    this.targetCost,
    this.projectedLifespanDays,
    List<int>? usageHistory,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       usageHistory = usageHistory ?? [];

  bool get isActive => consumedDate == null;

  int get daysOwned {
    final end = consumedDate ?? DateTime.now();
    final diff = end.difference(purchaseDate).inDays;
    return diff < 1 ? 1 : diff;
  }

  double get totalUsesCalculated {
    if (estimatedUsageCount > 0) {
      // 1. SCHÄTZUNGS-MODUS (Automatisch)
      // Wir rechnen live über die verstrichene Zeit mit Nachkommastellen.
      double usesPerDay = 0;
      switch (usagePeriod) {
        case 'day': usesPerDay = estimatedUsageCount.toDouble(); break;
        case 'week': usesPerDay = estimatedUsageCount / 7; break;
        case 'month': usesPerDay = estimatedUsageCount / 30; break;
        case 'year': usesPerDay = estimatedUsageCount / 365; break;
      }
      
      double estimatedTotal = usesPerDay * daysOwned;
      
      // Falls der User (oder die alten Demo-Daten) manuell mehr geklickt haben 
      // als die Schätzung hergibt, nehmen wir zur Sicherheit den höheren Wert.
      return max(estimatedTotal, manualClicks.toDouble());
    } else {
      // 2. MANUELLER MODUS & ABOS
      // Nur noch manualClicks zählt! Keine Doppel-Addition mehr mit der history-Länge.
      return manualClicks.toDouble();
    }
  }

  double get costPerUse {
    double uses = totalUsesCalculated;
    
    if (isSubscription) {
      double months = daysOwned / 30;
      if (months < 1) months = 1;
      double totalPaid = price * (subscriptionPeriod == 'year' ? (months / 12) : months);
      return uses <= 1 ? totalPaid : totalPaid / uses;
    }
    
    // T-Shirt Logik: Preis geteilt durch Nutzungen
    // Wir nehmen mindestens 1 Nutzung an, um astronomische Zahlen / Division durch 0 zu vermeiden
    if (uses <= 1) return price;
    return price / uses;
  }

  double get pricePerDay {
    if (isSubscription) {
       return subscriptionPeriod == 'year' ? price / 365 : price / 30;
    }
    return price / daysOwned;
  }

  DateTime? get lastUsedDate {
    if (usageHistory.isEmpty) return null;
    final List<int> sorted = List.from(usageHistory)..sort();
    return DateTime.fromMillisecondsSinceEpoch(sorted.last);
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'purchaseDate': purchaseDate.toIso8601String(),
    'estimatedUsageCount': estimatedUsageCount, 'usagePeriod': usagePeriod,
    'isSubscription': isSubscription, 'subscriptionPeriod': subscriptionPeriod,
    'emoji': emoji, 'imagePath': imagePath, 'category': category,
    'manualClicks': manualClicks, 'consumedDate': consumedDate?.toIso8601String(),
    'targetCost': targetCost, 'projectedLifespanDays': projectedLifespanDays,
    'usageHistory': usageHistory,
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'], name: json['name'], price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      estimatedUsageCount: json['estimatedUsageCount'] ?? 0,
      usagePeriod: json['usagePeriod'] ?? 'week',
      isSubscription: json['isSubscription'] ?? false,
      subscriptionPeriod: json['subscriptionPeriod'] ?? 'month',
      emoji: json['emoji'], imagePath: json['imagePath'],
      category: json['category'] ?? 'cat_misc', manualClicks: json['manualClicks'] ?? 0,
      consumedDate: json['consumedDate'] != null ? DateTime.parse(json['consumedDate']) : null,
      targetCost: (json['targetCost'] as num?)?.toDouble(),
      projectedLifespanDays: json['projectedLifespanDays'],
      usageHistory: (json['usageHistory'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }
}