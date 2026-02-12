import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; 
import 'package:fl_chart/fl_chart.dart';
import '../models/item.dart';
import '../widgets/animations.dart';
import '../widgets/item_tile.dart';
import '../widgets/history_tile.dart';
import '../services/storage_service.dart';
import '../utils/translations.dart';
import 'settings_page.dart';
import 'edit_item_page.dart';
import 'item_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;
  const DashboardPage({super.key, required this.onThemeChanged, required this.currentTheme, required this.onLanguageChanged});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  List<Item> _items = [];
  Map<String, String> _categoryAliases = {};
  List<String> _categories = ['cat_living', 'cat_tech', 'cat_clothes', 'cat_transport', 'cat_food', 'cat_insurance', 'cat_entertainment', 'cat_business', 'cat_health', 'cat_misc'];
  bool _isSearching = false;
  String _searchQuery = "";
  late TabController _tabController;
  bool _showDailyRates = false;
  int _currentTabIndex = 0;
  String _selectedRaceCategory = 'cat_tech';
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() => _currentTabIndex = _tabController.index); });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _items = _storage.getAllItems();
      _categoryAliases = _storage.getCategoryAliases();
      List<String> custom = _storage.getCustomCategories();
      for (var c in custom) { if (!_categories.contains(c)) _categories.add(c); }
    });
  }

  void _createDemoData() {
    List<Item> demos = [
      Item(name: "MacBook Air", price: 1299, purchaseDate: DateTime.now().subtract(const Duration(days: 400)), category: "cat_tech", emoji: "💻", projectedLifespanDays: 1825),
      Item(name: "Netflix", price: 17.99, purchaseDate: DateTime.now().subtract(const Duration(days: 30)), category: "cat_entertainment", emoji: "🍿", isSubscription: true, subscriptionPeriod: "month"),
      Item(name: "Winter Boots", price: 180, purchaseDate: DateTime.now().subtract(const Duration(days: 100)), category: "cat_clothes", emoji: "🥾", projectedLifespanDays: 730),
      Item(name: "Gym", price: 45, purchaseDate: DateTime.now().subtract(const Duration(days: 60)), category: "cat_health", emoji: "💪", isSubscription: true, subscriptionPeriod: "month"),
    ];
    for(var i in demos) _storage.saveItem(i);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()) || i.category.contains(_searchQuery)).toList();
    final active = filtered.where((i) => i.isActive && !i.isSubscription).toList();
    final subs = filtered.where((i) => i.isActive && i.isSubscription).toList();
    final archived = filtered.where((i) => !i.isActive).toList();
    final isRetro = widget.currentTheme == 'retro';
    
    // Header Berechnung
    double headerValue = 0;
    String headerLabel = T.get('daily_cost');
    double totalDaily = _items.where((i) => i.isActive).fold(0.0, (sum, item) => sum + item.pricePerDay);
    
    if (_currentTabIndex == 0) { 
      headerValue = active.fold(0.0, (sum, item) => sum + item.pricePerDay); headerLabel = T.get('daily_cost_items'); 
    } else if (_currentTabIndex == 1) { 
      headerValue = subs.fold(0.0, (sum, item) => sum + item.pricePerDay); headerLabel = T.get('daily_cost_subs'); 
    } else { 
      headerValue = totalDaily; 
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(autofocus: true, decoration: InputDecoration(hintText: T.get('search'), border: InputBorder.none), onChanged: (v) => setState(() => _searchQuery = v))
          : Text(T.get('app_name'), style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: isRetro ? 3 : 1)),
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () => setState(() { _isSearching = !_isSearching; _searchQuery = ""; })),
          if (!_isSearching) IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsPage(onThemeChanged: widget.onThemeChanged, currentTheme: widget.currentTheme, onLanguageChanged: widget.onLanguageChanged))).then((_) => _loadData()))
        ],
      ),
      body: Column(
        children: [
          if (!_isSearching) Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(children: [
              Text(headerLabel, style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              RollingNumber(value: headerValue, suffix: "€", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color))
            ]),
          ),
          TabBar(controller: _tabController, tabs: [Tab(text: T.get('items')), Tab(text: T.get('subs')), Tab(text: T.get('stats'))]),
          Expanded(child: TabBarView(controller: _tabController, children: [
              _buildList(active, archived, false),
              _buildList(subs, [], true),
              _buildStats(isRetro)
          ])),
        ],
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.add), onPressed: () => _openEdit(null)),
    );
  }

  Widget _buildList(List<Item> items, List<Item> archived, bool isSub) {
    if (items.isEmpty && archived.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(isSub ? T.get('empty_subs') : T.get('empty_items'), style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        if (!isSub) TextButton(onPressed: _createDemoData, child: Text(T.get('load_demo')))
      ]));
    }
    return ListView(children: [
      ...items.map((i) => ItemTile(item: i, index: 0, isLast: false, avgCost: 0, showDailyRates: _showDailyRates, isRetro: widget.currentTheme == 'retro', onTap: () => _openDetail(i))),
      if (archived.isNotEmpty) ...[const Divider(), Center(child: Text(T.get('history'), style: const TextStyle(fontWeight: FontWeight.bold))), ...archived.map((i) => HistoryTile(item: i, isRetro: widget.currentTheme == 'retro', onTap: () => _openDetail(i)))]
    ]);
  }

  Widget _buildStats(bool isRetro) {
    if (_items.isEmpty) return Center(child: Text(T.get('empty_stats')));
    double totalVal = _items.where((i) => !i.isSubscription && i.isActive).fold(0, (sum, i) => sum + i.price);
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _statCard(T.get('stats_inventory'), totalVal, Colors.blue, false)), const SizedBox(width: 10), Expanded(child: _statCard(T.get('stats_yearly_subs'), _items.where((i)=>i.isSubscription && i.isActive).fold(0, (sum, i) => sum + (i.subscriptionPeriod=='month'?i.price*12:i.price)), Colors.orange, false))]),
      const SizedBox(height: 30),
      _buildLongevityRace(isRetro),
      const SizedBox(height: 30),
      SizedBox(height: 200, child: PieChart(PieChartData(sections: _getSections())))
    ]));
  }

  Widget _buildLongevityRace(bool isRetro) {
    Set<String> activeCats = _items.map((i) => i.category).toSet();
    if (activeCats.isEmpty) return const SizedBox.shrink();
    if (!activeCats.contains(_selectedRaceCategory)) _selectedRaceCategory = activeCats.first;
    List<Item> raceItems = _items.where((i) => i.category == _selectedRaceCategory).toList();
    raceItems.sort((a, b) => max(b.daysOwned, b.projectedLifespanDays ?? 365).compareTo(max(a.daysOwned, a.projectedLifespanDays ?? 365)));
    int maxScale = 1;
    for (var i in raceItems) { int m = max(i.daysOwned, i.projectedLifespanDays ?? 365); if (m > maxScale) maxScale = m; }
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(T.get('lifespan_race'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: activeCats.map((c) => Padding(padding: const EdgeInsets.only(right: 5), child: ChoiceChip(label: Text(_categoryAliases[c] ?? (c.startsWith('cat') ? T.get(c) : c)), selected: _selectedRaceCategory == c, onSelected: (s) { if(s) setState(() => _selectedRaceCategory = c); }))).toList())),
      const SizedBox(height: 15),
      ...raceItems.map((item) {
        int planned = item.projectedLifespanDays ?? 365;
        int actual = item.daysOwned;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item.name), Text("$actual / $planned d")]),
          const SizedBox(height: 5),
          Stack(children: [
            Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
            FractionallySizedBox(widthFactor: (planned / maxScale).clamp(0.0, 1.0), child: Container(height: 10, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(5)))),
            FractionallySizedBox(widthFactor: (actual / maxScale).clamp(0.0, 1.0), child: Container(height: 10, decoration: BoxDecoration(color: actual >= planned ? Colors.green : Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(5)))),
          ])
        ]));
      })
    ]);
  }

  List<PieChartSectionData> _getSections() {
    Map<String, double> data = {};
    for (var i in _items) { data[i.category] = (data[i.category] ?? 0) + i.price; }
    return data.entries.map((e) => PieChartSectionData(value: e.value, title: "", color: Colors.primaries[data.keys.toList().indexOf(e.key) % Colors.primaries.length], radius: 50)).toList();
  }

  Widget _statCard(String t, double v, Color c, bool isInt) {
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Column(children: [RollingNumber(value: v, isInt: isInt, suffix: "€", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)), Text(t, textAlign: TextAlign.center)]));
  }

  void _openDetail(Item i) => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(item: i, onUpdate: () => setState(() => _storage.saveItem(i)))));
  void _openEdit(Item? i) => Navigator.push(context, MaterialPageRoute(builder: (_) => EditItemPage(item: i, availableCategories: _categories, onSave: (newItem) { setState(() { if(i==null) _items.add(newItem); else { int idx = _items.indexWhere((x)=>x.id==newItem.id); if(idx!=-1) _items[idx]=newItem; }}); _storage.saveItem(newItem); }, onDelete: (id) { setState(() => _items.removeWhere((x)=>x.id==id)); _storage.deleteItem(id); })));
}