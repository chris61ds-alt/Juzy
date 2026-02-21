import 'package:flutter/material.dart';
import 'dart:math';
import '../models/item.dart';
import '../utils/translations.dart';

class HistoryTile extends StatelessWidget {
  final Item item;
  final bool isRetro;
  final VoidCallback onTap;

  const HistoryTile({
    super.key,
    required this.item,
    required this.isRetro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    // Erfolgs-Berechnung
    bool isSuccess = false;
    DateTime buyDate = item.purchaseDate;
    DateTime consumeDate = item.consumedDate ?? DateTime.now();
    int actualDays = max(1, consumeDate.difference(buyDate).inDays);
    int plannedDays = item.projectedLifespanDays ?? 365;

    if (item.isSubscription) {
      isSuccess = (item.costPerUse <= (item.targetCost ?? item.price));
    } else {
      isSuccess = (actualDays >= plannedDays);
    }

    String statusText = isSuccess ? T.get('verdict_success') : T.get('verdict_fail');
    Color statusColor = isSuccess ? Colors.green : Colors.red;
    
    // Hintergrundfarbe basierend auf Theme und Erfolg
    Color cardBg;
    if (isRetro) {
      cardBg = isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    } else {
      cardBg = isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Text(item.emoji ?? "🏁", style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  Text(
                    "${item.totalUsesCalculated.toInt()} ${T.get('times_used')}",
                    style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8)),
                  )
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: statusColor,
                      size: 16,
                    )
                  ],
                ),
                Text(
                  "${item.costPerUse.toStringAsFixed(2)}€",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}