import 'dart:math';

class Item {
  String name;
  double price;
  DateTime purchaseDate;
  
  // Nutzung
  int estimatedUsageCount; // 0 = Manuelles Tracking
  String usagePeriod; // 'day', 'week', 'month', 'year'
  int manualClicks;
  
  // Abo
  bool isSubscription;
  String subscriptionPeriod; // 'month', 'year'
  
  // Metadaten
  String? emoji;
  String? imagePath;
  String category;
  
  // Analyse
  double? targetCost; // Ziel-Preis pro Nutzung
  int? projectedLifespanDays; // Geplante Lebensdauer
  DateTime? consumedDate; // Wann archiviert?

  Item({
    required this.name,
    required this.price,
    required this.purchaseDate,
    this.estimatedUsageCount = 0,
    this.usagePeriod = 'week',
    this.manualClicks = 0,
    this.isSubscription = false,
    this.subscriptionPeriod = 'month',
    this.emoji,
    this.imagePath,
    this.category = 'cat_misc',
    this.targetCost,
    this.projectedLifespanDays,
    this.consumedDate,
  });

  // Berechnete Eigenschaften
  bool get isActive => consumedDate == null;

  double get totalUsesCalculated {
    if (isSubscription) {
      DateTime endDate = consumedDate ?? DateTime.now();
      int days = endDate.difference(purchaseDate).inDays;
      if (days < 1) days = 1;
      
      if (subscriptionPeriod == 'year') {
        return days / 365.0;
      } else {
        return days / 30.0;
      }
    }
    
    if (estimatedUsageCount == 0) {
      return manualClicks.toDouble();
    } else {
      DateTime endDate = consumedDate ?? DateTime.now();
      int days = endDate.difference(purchaseDate).inDays;
      if (days < 1) days = 1;
      
      double dailyRate = 0;
      switch (usagePeriod) {
        case 'day': dailyRate = estimatedUsageCount.toDouble(); break;
        case 'week': dailyRate = estimatedUsageCount / 7.0; break;
        case 'month': dailyRate = estimatedUsageCount / 30.0; break;
        case 'year': dailyRate = estimatedUsageCount / 365.0; break;
      }
      return manualClicks + (dailyRate * days);
    }
  }

  double get costPerUse {
    double uses = totalUsesCalculated;
    if (uses < 1) uses = 1;
    if (isSubscription) return price; 
    return price / uses;
  }

  double get pricePerDay {
    if (isSubscription) {
      if (subscriptionPeriod == 'year') return price / 365.0;
      return price / 30.0;
    }
    DateTime endDate = consumedDate ?? DateTime.now();
    int days = endDate.difference(purchaseDate).inDays;
    if (days < 1) days = 1;
    return price / days;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'purchaseDate': purchaseDate.toIso8601String(),
    'estimatedUsageCount': estimatedUsageCount,
    'usagePeriod': usagePeriod,
    'manualClicks': manualClicks,
    'isSubscription': isSubscription,
    'subscriptionPeriod': subscriptionPeriod,
    'emoji': emoji,
    'imagePath': imagePath,
    'category': category,
    'targetCost': targetCost,
    'projectedLifespanDays': projectedLifespanDays,
    'consumedDate': consumedDate?.toIso8601String(),
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      estimatedUsageCount: json['estimatedUsageCount'] ?? 0,
      usagePeriod: json['usagePeriod'] ?? 'week',
      manualClicks: json['manualClicks'] ?? 0,
      isSubscription: json['isSubscription'] ?? false,
      subscriptionPeriod: json['subscriptionPeriod'] ?? 'month',
      emoji: json['emoji'],
      imagePath: json['imagePath'],
      category: json['category'] ?? 'cat_misc',
      targetCost: (json['targetCost'] as num?)?.toDouble(),
      projectedLifespanDays: json['projectedLifespanDays'],
      consumedDate: json['consumedDate'] != null ? DateTime.parse(json['consumedDate']) : null,
    );
  }
}