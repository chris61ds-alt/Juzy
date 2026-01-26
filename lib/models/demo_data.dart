import 'item.dart';

class DemoData {
  static List<Item> getDemoItems() {
    return [
      Item(
        name: "Netflix Premium",
        price: 17.99,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
        isSubscription: true,
        subscriptionPeriod: 'month',
        emoji: "🍿",
        category: "Entertainment",
        estimatedUsageCount: 0,
      ),
      Item(
        name: "Spotify Duo",
        price: 14.99,
        purchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        isSubscription: true,
        subscriptionPeriod: 'month',
        emoji: "🎧",
        category: "Entertainment",
        estimatedUsageCount: 0,
      ),
      Item(
        name: "Fitness Studio",
        price: 45.00,
        purchaseDate: DateTime.now().subtract(const Duration(days: 120)),
        isSubscription: true,
        subscriptionPeriod: 'month',
        emoji: "💪",
        category: "Gesundheit",
        estimatedUsageCount: 0,
      ),
      Item(
        name: "Winterjacke",
        price: 199.99,
        purchaseDate: DateTime.now().subtract(const Duration(days: 100)),
        estimatedUsageCount: 4,
        usagePeriod: 'week',
        emoji: "🧥",
        category: "Kleidung",
        targetCost: 1.00, // Ziel: 1€ pro Tragen
      ),
      Item(
        name: "iPhone 15",
        price: 999.00,
        purchaseDate: DateTime.now().subtract(const Duration(days: 200)),
        estimatedUsageCount: 50, // Sehr oft
        usagePeriod: 'day',
        emoji: "📱",
        category: "Tech",
        projectedLifespanDays: 365 * 3, // 3 Jahre geplant
      ),
      Item(
        name: "Kaffee To Go",
        price: 4.50,
        purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
        manualClicks: 1, // Manuelles Tracking
        estimatedUsageCount: 0,
        emoji: "☕",
        category: "Essen",
      ),
      Item(
        name: "Haftpflicht",
        price: 55.00,
        purchaseDate: DateTime.now().subtract(const Duration(days: 300)),
        isSubscription: true,
        subscriptionPeriod: 'year',
        emoji: "🛡️",
        category: "Versicherung",
      ),
    ];
  }
}