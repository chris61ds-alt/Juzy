import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/translations.dart';
import 'edit_item_page.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final VoidCallback onUpdate;
  const ItemDetailPage({super.key, required this.item, required this.onUpdate});
  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  @override
  Widget build(BuildContext context) {
    Item item = widget.item;
    return Scaffold(
      appBar: AppBar(actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditItemPage(item: item, availableCategories: [], onSave: (updated) { setState(() { item = updated; }); widget.onUpdate(); }, onDelete: (id) { widget.onUpdate(); Navigator.pop(context); }))))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 80))),
        const SizedBox(height: 20),
        Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("${item.price.toStringAsFixed(2)}€", textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(height: 30),
        _row(T.get('bought_on'), "${item.purchaseDate.day}.${item.purchaseDate.month}.${item.purchaseDate.year}"),
        _row(T.get('days'), "${item.daysOwned}"),
        _row(T.get('cost_per_use'), "${item.costPerUse.toStringAsFixed(2)}€"),
        const SizedBox(height: 30),
        if (!item.isSubscription && item.isActive) ElevatedButton(onPressed: () { setState(() => item.manualClicks++); widget.onUpdate(); }, child: Text("+ ${T.get('per_usage')}")),
        if (item.isActive) TextButton(onPressed: () { setState(() => item.consumedDate = DateTime.now()); widget.onUpdate(); Navigator.pop(context); }, child: Text(T.get('consume_button'), style: const TextStyle(color: Colors.red)))
      ]),
    );
  }
  Widget _row(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
}