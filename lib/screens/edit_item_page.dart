import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item.dart';
import '../utils/translations.dart';

class EditItemPage extends StatefulWidget {
  final Item? item;
  final List<String> availableCategories;
  final Function(Item) onSave;
  final Function(String) onDelete;
  const EditItemPage({super.key, this.item, required this.availableCategories, required this.onSave, required this.onDelete});
  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  String _selectedCategory = 'cat_misc';
  String _selectedEmoji = '📦';
  DateTime _selectedDate = DateTime.now();
  bool _isSubscription = false;
  String _subPeriod = 'month'; 
  String _usagePeriod = 'week';
  int _estimatedUsage = 1;
  int _lifespanDays = 365;

  final Map<String, String> _categoryEmojis = { 'cat_living': '🛋️', 'cat_tech': '💻', 'cat_clothes': '👕', 'cat_transport': '🚲', 'cat_food': '🍔', 'cat_insurance': '🛡️', 'cat_entertainment': '🍿', 'cat_business': '💼', 'cat_health': '💊', 'cat_misc': '📦' };

  @override
  void initState() {
    super.initState();
    Item? i = widget.item;
    _nameController = TextEditingController(text: i?.name ?? "");
    _priceController = TextEditingController(text: i != null ? i.price.toString() : "");
    if (i != null) {
      _selectedCategory = i.category;
      _selectedEmoji = i.emoji ?? _categoryEmojis[i.category] ?? '📦';
      _selectedDate = i.purchaseDate;
      _isSubscription = i.isSubscription;
      _subPeriod = i.subscriptionPeriod ?? 'month';
      _usagePeriod = i.usagePeriod;
      _estimatedUsage = i.estimatedUsageCount;
      _lifespanDays = i.projectedLifespanDays ?? 365;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? T.get('new_item') : T.get('group_rename').replaceAll("Gruppe", "Item")),
        actions: [if (widget.item != null) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _confirmDelete)]
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(T.get('items').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: widget.availableCategories.length,
            itemBuilder: (ctx, index) {
              String cat = widget.availableCategories[index];
              bool isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedCategory = cat; _selectedEmoji = _categoryEmojis[cat] ?? '📦'; }); },
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isSelected ? highlightColor : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: isSelected ? Border.all(color: highlightColor, width: 2) : null),
                    child: Text(_categoryEmojis[cat] ?? '📦', style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(height: 4),
                  Text((cat.startsWith('cat_') ? T.get(cat) : cat), style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)
                ]),
              );
            },
          ),
          const SizedBox(height: 30),
          TextFormField(controller: _nameController, decoration: InputDecoration(labelText: T.get('new_name'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.tag)), validator: (v) => v!.isEmpty ? "Name?" : null),
          const SizedBox(height: 15),
          TextFormField(controller: _priceController, decoration: InputDecoration(labelText: "Preis (€)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.euro)), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? "Preis?" : null),
          const SizedBox(height: 15),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(T.get('bought_on')), subtitle: Text("${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}"), trailing: const Icon(Icons.calendar_today), onTap: () async { DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2010), lastDate: DateTime.now()); if (picked != null) setState(() => _selectedDate = picked); }),
          const Divider(height: 40),
          SwitchListTile(title: Text(T.get('subs')), subtitle: Text(_isSubscription ? "Wiederkehrende Zahlung" : "Einmaliger Kauf"), value: _isSubscription, activeColor: highlightColor, onChanged: (v) => setState(() => _isSubscription = v)),
          if (_isSubscription) ...[
            const SizedBox(height: 10),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'month', label: Text('Monatlich')), ButtonSegment(value: 'year', label: Text('Jährlich'))], selected: {_subPeriod}, onSelectionChanged: (Set<String> newSelection) { setState(() => _subPeriod = newSelection.first); }),
          ] else ...[
            const SizedBox(height: 10),
            Text("Geschätzte Haltbarkeit: ${(_lifespanDays/365).toStringAsFixed(1)} Jahre", style: const TextStyle(fontSize: 12)),
            Slider(value: _lifespanDays.toDouble(), min: 30, max: 3650, divisions: 100, activeColor: highlightColor, onChanged: (val) => setState(() => _lifespanDays = val.toInt())),
            const SizedBox(height: 10),
            Row(children: [const Text("Ich nutze es ca."), const SizedBox(width: 10), SizedBox(width: 50, child: TextFormField(initialValue: _estimatedUsage.toString(), keyboardType: TextInputType.number, onChanged: (v) => _estimatedUsage = int.tryParse(v) ?? 1, textAlign: TextAlign.center)), const SizedBox(width: 10), const Text("mal pro"), const SizedBox(width: 10), DropdownButton<String>(value: _usagePeriod, items: const [DropdownMenuItem(value: 'day', child: Text('Tag')), DropdownMenuItem(value: 'week', child: Text('Woche')), DropdownMenuItem(value: 'month', child: Text('Monat')), DropdownMenuItem(value: 'year', child: Text('Jahr'))], onChanged: (v) => setState(() => _usagePeriod = v!))]),
          ],
          const SizedBox(height: 40),
          SizedBox(height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: highlightColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _saveItem, child: Text(T.get('save').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        ]),
      ),
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    double price = double.parse(_priceController.text.replaceAll(',', '.'));
    Item newItem = Item(id: widget.item?.id, name: _nameController.text, price: price, purchaseDate: _selectedDate, category: _selectedCategory, emoji: _selectedEmoji, isSubscription: _isSubscription, subscriptionPeriod: _subPeriod, projectedLifespanDays: _lifespanDays, estimatedUsageCount: _estimatedUsage, usagePeriod: _usagePeriod, manualClicks: widget.item?.manualClicks ?? 0, usageHistory: widget.item?.usageHistory ?? [], consumedDate: widget.item?.consumedDate);
    widget.onSave(newItem);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Löschen?"), content: const Text("Wirklich unwiderruflich löschen?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))), TextButton(onPressed: () { Navigator.pop(ctx); widget.onDelete(widget.item!.id); Navigator.pop(context); }, child: const Text("Löschen", style: TextStyle(color: Colors.red)))]));
  }
}