import 'dart:math';

class Item {
  String id;
  String name;
  double price;
  DateTime purchaseDate;
  DateTime? consumedDate;
  String category;
  String? emoji;
  String usagePeriod; // 'day', 'week', 'month', 'year' oder leer
  int estimatedUsageCount;
  
  // Subscription fields
  bool isSubscription;
  String subscriptionPeriod; // 'month', 'year'
  
  // Manual tracking
  int manualClicks;
  
  // Goals
  double? targetCost; // Ziel-Kosten pro Nutzung (auch für Abos!)
  int? projectedLifespanDays; // Nur für Einmalkäufe relevant
  String? imagePath;

  Item({
    String? id,
    required this.name,
    required this.price,
    required this.purchaseDate,
    this.consumedDate,
    required this.category,
    this.emoji,
    this.usagePeriod = '',
    this.estimatedUsageCount = 0,
    this.isSubscription = false,
    this.subscriptionPeriod = 'month',
    this.manualClicks = 0,
    this.targetCost,
    this.projectedLifespanDays,
    this.imagePath,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // --- DIE NEUE LOGIK ---
  double get totalAccruedCost {
    if (!isSubscription) {
      return price;
    }

    // Zeitdifferenz berechnen (Bis heute oder bis Archiv-Datum)
    DateTime end = consumedDate ?? DateTime.now();
    Duration duration = end.difference(purchaseDate);
    
    // Einfache Näherung für Monate (30.44 Tage)
    double monthsPassed = max(1, duration.inDays / 30.44); 
    
    if (subscriptionPeriod == 'year') {
      // Wenn jährlich: Jahre berechnen (Monate / 12)
      double yearsPassed = max(1, monthsPassed / 12);
      // Kosten = Jahrespreis * Jahre (mindestens 1 Jahr wird berechnet am Anfang)
      // Wir runden auf, da man meist im Voraus zahlt (angefangenes Jahr = volles Jahr zahlen)
      return price * yearsPassed.ceil(); 
    } else {
      // Monatlich: Angefangener Monat zählt meist voll
      return price * monthsPassed.ceil();
    }
  }

  double get costPerUse {
    double totalCost = totalAccruedCost;
    
    // Nutzungen ermitteln
    double uses;
    if (isSubscription) {
      uses = manualClicks.toDouble();
    } else {
      uses = totalUsesCalculated;
    }

    if (uses <= 0) return totalCost; // Wenn 0 Nutzung, sind die Kosten pro Nutzung = Gesamtkosten
    return totalCost / uses;
  }

  // Für die Statistik im Dashboard (Tägliche Kosten)
  double get pricePerDay {
    if (isSubscription) {
      if (subscriptionPeriod == 'year') return price / 365.0;
      return price / 30.44;
    }
    // Kauf: Preis / Lebensdauer (angenommen oder Ziel)
    int lifespan = projectedLifespanDays ?? 365;
    return price / lifespan;
  }

  // Berechnete Nutzungen für Schätzungen (Einmalkäufe)
  double get totalUsesCalculated {
    if (manualClicks > 0 && usagePeriod.isEmpty) return manualClicks.toDouble();
    if (manualClicks > 0 && isSubscription) return manualClicks.toDouble();

    // Wenn Schätzung aktiv ist:
    DateTime end = consumedDate ?? DateTime.now();
    int daysOwned = end.difference(purchaseDate).inDays;
    if (daysOwned < 0) daysOwned = 0;

    if (usagePeriod == 'day') return daysOwned * estimatedUsageCount.toDouble();
    if (usagePeriod == 'week') return (daysOwned / 7) * estimatedUsageCount;
    if (usagePeriod == 'month') return (daysOwned / 30.44) * estimatedUsageCount;
    if (usagePeriod == 'year') return (daysOwned / 365) * estimatedUsageCount;
    
    return manualClicks.toDouble();
  }

  bool get isActive => consumedDate == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'purchaseDate': purchaseDate.toIso8601String(),
    'consumedDate': consumedDate?.toIso8601String(),
    'category': category,
    'emoji': emoji,
    'usagePeriod': usagePeriod,
    'estimatedUsageCount': estimatedUsageCount,
    'isSubscription': isSubscription,
    'subscriptionPeriod': subscriptionPeriod,
    'manualClicks': manualClicks,
    'targetCost': targetCost,
    'projectedLifespanDays': projectedLifespanDays,
    'imagePath': imagePath,
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      consumedDate: json['consumedDate'] != null ? DateTime.parse(json['consumedDate']) : null,
      category: json['category'],
      emoji: json['emoji'],
      usagePeriod: json['usagePeriod'] ?? '',
      estimatedUsageCount: json['estimatedUsageCount'] ?? 0,
      isSubscription: json['isSubscription'] ?? false,
      subscriptionPeriod: json['subscriptionPeriod'] ?? 'month',
      manualClicks: json['manualClicks'] ?? 0,
      targetCost: (json['targetCost'] as num?)?.toDouble(),
      projectedLifespanDays: json['projectedLifespanDays'],
      imagePath: json['imagePath'],
    );
  }
}