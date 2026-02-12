import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const ItemTile({super.key, required this.item, required this.index, required this.isLast, required this.avgCost, required this.showDailyRates, required this.isRetro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isRetro ? Colors.white : Theme.of(context).cardColor;
    final Color textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    final Color borderColor = isRetro ? const Color(0xFF6BB8A7).withOpacity(0.5) : Colors.transparent;
    final List<BoxShadow> shadows = isRetro ? [const BoxShadow(color: Color(0xFFD4522A), offset: Offset(2, 2), blurRadius: 0)] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))];

    Widget? verdictBadge;
    double cost = item.costPerUse;
    if (!item.isSubscription && item.isActive) {
      if (item.daysOwned > 30 && cost < 1.0) verdictBadge = _badge(Icons.star, Colors.amber, "Top");
      else if (item.daysOwned > 60 && cost > 5.0) verdictBadge = _badge(Icons.warning_amber_rounded, Colors.orange, "Teuer");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: isRetro ? 2 : 0), boxShadow: shadows),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: isRetro ? const Color(0xFFF9F3E6) : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 24)))),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Flexible(child: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), overflow: TextOverflow.ellipsis)), if (verdictBadge != null) ...[const SizedBox(width: 6), verdictBadge]]),
                    const SizedBox(height: 4),
                    Text(item.isSubscription ? "${item.subscriptionPeriod == 'month' ? 'Monatlich' : 'Jährlich'}" : "${T.get('bought_on')} ${_dateStr(item.purchaseDate)}", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (showDailyRates) Text("${item.pricePerDay.toStringAsFixed(2)}€", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))
                  else if (item.isSubscription) Text("${item.price.toStringAsFixed(2)}€", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))
                  else Text("${item.costPerUse.toStringAsFixed(2)}€", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _getColorForCost(item.costPerUse))),
                  const SizedBox(height: 2),
                  Text(showDailyRates ? "/ ${T.get('days')}" : (!item.isSubscription ? T.get('per_usage') : "Kosten"), style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.4))),
              ]),
    ]))));
  }
  Widget _badge(IconData icon, Color color, String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Row(children: [Icon(icon, size: 10, color: color), const SizedBox(width: 2), Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color))]));
  String _dateStr(DateTime d) => "${d.day}.${d.month}.${d.year.toString().substring(2)}";
  Color _getColorForCost(double cost) => cost < 1.0 ? Colors.green : (cost > 5.0 ? Colors.red : Colors.orange);
}