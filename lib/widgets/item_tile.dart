import 'package:flutter/material.dart';
import 'dart:io';
import '../models/item.dart';
import '../utils/translations.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final int index; 
  final bool isLast;
  final double avgCost; 
  final bool showDailyRates; 
  final bool isRetro; 
  final VoidCallback onTap;

  const ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
    required this.avgCost,
    required this.showDailyRates,
    required this.isRetro,
    required this.onTap,
  });

  int _calculateStars() {
    if (item.daysOwned < 3 && item.manualClicks < 5) return 5;
    if (item.targetCost != null && item.targetCost! > 0) {
      double ratio = item.costPerUse / item.targetCost!;
      if (ratio <= 1.0) return 5;
      if (ratio <= 1.25) return 4;
      if (ratio <= 1.5) return 3;
      if (ratio <= 1.75) return 2;
      return 1;
    }
    if (!item.isSubscription && item.projectedLifespanDays != null) {
      double ratio = item.daysOwned / item.projectedLifespanDays!;
      if (ratio >= 1.0) return 5; 
      if (ratio >= 0.8) return 4;
      if (ratio >= 0.5) return 3;
      if (ratio >= 0.2) return 2;
      return 1;
    }
    if (item.totalUsesCalculated > 0) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    final subTextColor = isRetro ? Colors.grey[700]! : Colors.grey;
    final Color starColor = Colors.amber;

    // Fortschritt & Zielberechnung für die Anzeige
    double? progress;
    bool reachedGoal = false;
    String usageFraction = "";

    // 1. Anzeige für Abos
    if (item.isSubscription) {
        // Bei Abos zeigen wir das Intervall
        usageFraction = item.subscriptionPeriod == 'year' ? T.get('yearly') : T.get('monthly');
    } 
    // 2. Anzeige für Items mit Ziel (z.B. "12 / 100")
    else if (item.targetCost != null && item.targetCost! > 0) {
      double neededUses = item.price / item.targetCost!;
      double currentUses = item.totalUsesCalculated;
      if (neededUses < 1) neededUses = 1;
      
      progress = currentUses / neededUses;
      if (progress >= 1.0) reachedGoal = true;
      
      // Formatierung: Keine Nachkommastellen bei Nutzungen
      usageFraction = "${currentUses.toInt()} / ${neededUses.toInt()}"; 
    } 
    // 3. Fallback Items ohne Ziel (z.B. "12 genutzt")
    else {
      usageFraction = "${item.totalUsesCalculated.toInt()} ${T.get('times_used')}";
    }

    // Preisanzeige
    String priceDisplay;
    
    if (showDailyRates) {
      priceDisplay = "${item.pricePerDay.toStringAsFixed(2)}€ /${T.get('days')}";
    } else {
      if (item.isSubscription) {
        priceDisplay = "${item.price.toStringAsFixed(2)}€";
      } else {
        priceDisplay = "${item.costPerUse.toStringAsFixed(2)}€";
      }
    }

    int stars = _calculateStars();

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Hero(
            tag: "item_img_${item.name}_$index",
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isRetro ? const Color(0xFFF4D98D) : Colors.grey.withOpacity(0.1),
                border: isRetro ? Border.all(color: const Color(0xFF3A2817), width: 1.5) : null,
                image: item.imagePath != null
                    ? DecorationImage(image: FileImage(File(item.imagePath!)), fit: BoxFit.cover)
                    : null,
              ),
              child: item.imagePath == null
                  ? Material(
                      color: Colors.transparent,
                      child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 28)))
                  : null,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
              ),
              if (reachedGoal)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                )
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // STERNE JETZT LINKS UNTER DEM NAMEN
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: index < stars ? starColor : Colors.grey.withOpacity(0.3),
                  );
                }),
              ),
              
              if (progress != null && !reachedGoal)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      color: isRetro ? const Color(0xFF6BB8A7) : Colors.blueAccent,
                      minHeight: 4,
                    ),
                  ),
                )
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // PREIS OBEN
              Text(
                priceDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isRetro && reachedGoal ? const Color(0xFF6BB8A7) : textColor,
                ),
              ),
              const SizedBox(height: 4),
              // NUTZUNG UNTEN (X / Y)
              Text(
                usageFraction,
                style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 82,
            endIndent: 20,
            color: isRetro ? const Color(0xFF6BB8A7).withOpacity(0.2) : Colors.white10,
          ),
      ],
    );
  }
}