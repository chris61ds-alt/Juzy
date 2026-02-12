import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/translations.dart';

class HistoryTile extends StatelessWidget {
  final Item item;
  final bool isRetro;
  final VoidCallback onTap;

  const HistoryTile({super.key, required this.item, required this.isRetro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 20))),
      title: Text(item.name, style: TextStyle(decoration: TextDecoration.lineThrough, color: textColor.withOpacity(0.6))),
      subtitle: Text("${T.get('item_archived')} ${_dateStr(item.consumedDate!)}"),
      trailing: Text("${item.costPerUse.toStringAsFixed(2)}€/${T.get('per_usage')}", style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
  String _dateStr(DateTime d) => "${d.day}.${d.month}.${d.year}";
}