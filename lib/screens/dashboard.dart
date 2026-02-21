import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Wichtig für das Auslesen der Systemsprache
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/item.dart';
import '../widgets/animations.dart';
import '../widgets/item_tile.dart';
import '../widgets/history_tile.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'settings_page.dart';
import 'edit_item_page.dart';
import 'item_detail_page.dart';
import '../utils/translations.dart';

class DashboardPage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;

  const DashboardPage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.onLanguageChanged,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  List<Item> _items = [];
  Map<String, String> _categoryAliases = {};
  
  final List<String> _standardCategories = [
    'cat_living', 'cat_tech', 'cat_clothes', 'cat_transport',
    'cat_food', 'cat_insurance', 'cat_entertainment',
    'cat_business', 'cat_health', 'cat_misc'
  ];
  
  List<String> _categories = [];
  Map<String, String> _customCategoryEmojis = {};

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  bool _showDailyRates = false;
  int _currentTabIndex = 0;
  
  String _selectedRaceCategory = 'cat_tech';

  final Color _juzyColor = const Color(0xFF6BB8A7);
  final String _privacyUrl = "https://chris61ds-alt.github.io/Juzy-Legal/";
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _categories = List.from(_standardCategories);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    
    _loadData().then((_) => _checkFirstRun());
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('first_run') ?? true;
    
    if (isFirstRun) {
      // Systemsprache auslesen und JUZY entsprechend einstellen
      String sysLang = ui.PlatformDispatcher.instance.locale.languageCode;
      String defaultLang = sysLang.startsWith('de') ? 'de' : 'en';
      
      T.setLanguage(defaultLang); 
      widget.onLanguageChanged(defaultLang);
      
      if (mounted) {
        _showOnboardingDialog(prefs);
      }
    } else {
      if (_items.isNotEmpty) {
        NotificationService().checkAndNudge(_items);
      }
    }
  }

  List<int> _generateFakeHistory(int count, int daysBack) {
    List<int> history = [];
    DateTime now = DateTime.now();
    Random random = Random();
    for (int i = 0; i < count; i++) {
      int daysAgo = random.nextInt(daysBack + 1);
      DateTime date = now.subtract(Duration(days: daysAgo, hours: random.nextInt(20)));
      history.add(date.millisecondsSinceEpoch);
    }
    history.sort(); 
    return history;
  }

  void _createDemoData() {
    DateTime now = DateTime.now();
    List<Item> demoItems = [];
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    // 8 Active Items
    demoItems.add(Item(name: "MacBook Air M2", price: 1299.00, purchaseDate: daysAgo(365), category: "cat_tech", emoji: "💻", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 1825, usageHistory: _generateFakeHistory(300, 365)));
    demoItems.add(Item(name: "Sofa Retro", price: 899.00, purchaseDate: daysAgo(120), category: "cat_living", emoji: "🛋️", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 3650, usageHistory: _generateFakeHistory(120, 120)));
    demoItems.add(Item(name: "E-Bike City", price: 2100.00, purchaseDate: daysAgo(60), category: "cat_transport", emoji: "🚲", usagePeriod: "week", estimatedUsageCount: 4, projectedLifespanDays: 1825, usageHistory: _generateFakeHistory(35, 60)));
    demoItems.add(Item(name: "Winterjacke", price: 150.00, purchaseDate: daysAgo(200), category: "cat_clothes", emoji: "🧥", usagePeriod: "week", estimatedUsageCount: 2, projectedLifespanDays: 1095, usageHistory: _generateFakeHistory(60, 200)));
    demoItems.add(Item(name: "Sony Kopfhörer", price: 250.00, purchaseDate: daysAgo(400), category: "cat_tech", emoji: "🎧", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 1095, usageHistory: _generateFakeHistory(350, 400)));
    demoItems.add(Item(name: "Schreibtisch", price: 300.00, purchaseDate: daysAgo(800), category: "cat_living", emoji: "🪑", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 3650, usageHistory: _generateFakeHistory(800, 800)));
    demoItems.add(Item(name: "Laufschuhe", price: 120.00, purchaseDate: daysAgo(45), category: "cat_clothes", emoji: "👟", usagePeriod: "week", estimatedUsageCount: 3, projectedLifespanDays: 365, usageHistory: _generateFakeHistory(20, 45)));
    demoItems.add(Item(name: "Siebträger", price: 650.00, purchaseDate: daysAgo(100), category: "cat_living", emoji: "☕", usagePeriod: "day", estimatedUsageCount: 2, projectedLifespanDays: 1825, usageHistory: _generateFakeHistory(190, 100)));

    // 4 Archived Items
    demoItems.add(Item(name: "Altes iPhone 11", price: 799.00, purchaseDate: daysAgo(1500), category: "cat_tech", emoji: "📱", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 1095, consumedDate: daysAgo(10), usageHistory: _generateFakeHistory(1400, 1500))); 
    demoItems.add(Item(name: "Sneakers (Kaputt)", price: 90.00, purchaseDate: daysAgo(400), category: "cat_clothes", emoji: "👟", usagePeriod: "week", estimatedUsageCount: 4, projectedLifespanDays: 730, consumedDate: daysAgo(50), usageHistory: _generateFakeHistory(180, 350))); 
    demoItems.add(Item(name: "Standmixer", price: 40.00, purchaseDate: daysAgo(800), category: "cat_food", emoji: "🥤", usagePeriod: "week", estimatedUsageCount: 1, projectedLifespanDays: 1095, consumedDate: daysAgo(200), usageHistory: _generateFakeHistory(80, 600))); 
    demoItems.add(Item(name: "Monitor 24 Zoll", price: 150.00, purchaseDate: daysAgo(2000), category: "cat_tech", emoji: "🖥️", usagePeriod: "day", estimatedUsageCount: 1, projectedLifespanDays: 1825, consumedDate: daysAgo(100), usageHistory: _generateFakeHistory(1800, 1900))); 

    // 6 Active Subs
    demoItems.add(Item(name: "Netflix Premium", price: 17.99, purchaseDate: daysAgo(180), category: "cat_entertainment", emoji: "🍿", isSubscription: true, subscriptionPeriod: "month", manualClicks: 120, targetCost: 0.50, usageHistory: _generateFakeHistory(120, 180)));
    demoItems.add(Item(name: "Spotify Duo", price: 12.99, purchaseDate: daysAgo(400), category: "cat_entertainment", emoji: "🎵", isSubscription: true, subscriptionPeriod: "month", manualClicks: 350, targetCost: 0.10, usageHistory: _generateFakeHistory(350, 400)));
    demoItems.add(Item(name: "Gym Membership", price: 45.00, purchaseDate: daysAgo(300), category: "cat_health", emoji: "💪", isSubscription: true, subscriptionPeriod: "month", manualClicks: 90, targetCost: 3.00, usageHistory: _generateFakeHistory(90, 300)));
    demoItems.add(Item(name: "Amazon Prime", price: 8.99, purchaseDate: daysAgo(600), category: "cat_misc", emoji: "📦", isSubscription: true, subscriptionPeriod: "month", manualClicks: 200, targetCost: 0.50, usageHistory: _generateFakeHistory(200, 600)));
    demoItems.add(Item(name: "iCloud 2TB", price: 9.99, purchaseDate: daysAgo(800), category: "cat_tech", emoji: "☁️", isSubscription: true, subscriptionPeriod: "month", manualClicks: 800, targetCost: 0.05, usageHistory: _generateFakeHistory(800, 800)));
    demoItems.add(Item(name: "Haftpflicht", price: 5.50, purchaseDate: daysAgo(1000), category: "cat_insurance", emoji: "🛡️", isSubscription: true, subscriptionPeriod: "month", manualClicks: 10, targetCost: 10.00, usageHistory: _generateFakeHistory(10, 1000)));

    // 3 Archived Subs
    demoItems.add(Item(name: "VPN Service", price: 4.99, purchaseDate: daysAgo(500), category: "cat_tech", emoji: "🔒", isSubscription: true, subscriptionPeriod: "month", manualClicks: 40, targetCost: 0.20, consumedDate: daysAgo(100), usageHistory: _generateFakeHistory(40, 400)));
    demoItems.add(Item(name: "Xbox Game Pass", price: 14.99, purchaseDate: daysAgo(300), category: "cat_entertainment", emoji: "🎮", isSubscription: true, subscriptionPeriod: "month", manualClicks: 15, targetCost: 1.00, consumedDate: daysAgo(60), usageHistory: _generateFakeHistory(15, 240))); 
    demoItems.add(Item(name: "Zeit Magazin", price: 29.90, purchaseDate: daysAgo(200), category: "cat_entertainment", emoji: "📰", isSubscription: true, subscriptionPeriod: "month", manualClicks: 8, targetCost: 2.00, consumedDate: daysAgo(20), usageHistory: _generateFakeHistory(8, 180)));

    for (var item in demoItems) {
      _storage.saveItem(item);
    }
    _loadData();
  }

  void _showOnboardingDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🥭", style: TextStyle(fontSize: 60)),
                const SizedBox(height: 20),
                Text(T.get('onboarding_welcome'), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _juzyColor, height: 1.2)),
                const SizedBox(height: 15),
                Text(T.get('onboarding_desc'), textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.8), height: 1.4, fontSize: 15)),
                const SizedBox(height: 35),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      await prefs.setBool('first_run', false);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _juzyColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0
                    ),
                    child: Text(T.get('onboarding_start').isEmpty ? "Start" : T.get('onboarding_start'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async { 
                    final Uri url = Uri.parse(_privacyUrl); 
                    if (!await launchUrl(url)) { debugPrint('Could not launch $_privacyUrl'); } 
                  }, 
                  child: Text(T.get('onboarding_legal'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5), decoration: TextDecoration.underline))
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  void dispose() { 
    _tabController.dispose(); 
    _searchController.dispose();
    super.dispose(); 
  }

  Future<void> _loadData() async {
    final items = _storage.getAllItems();
    final aliases = _storage.getCategoryAliases();
    final customCats = _storage.getCustomCategories();
    final emojis = _storage.getCustomEmojis();
    setState(() { 
      _items = items; 
      _categoryAliases = aliases; 
      _customCategoryEmojis = emojis; 
      _categories = List.from(_standardCategories); 
      for(var c in customCats) { 
        if(!_categories.contains(c)) {
          _categories.add(c);
        }
      } 
    });
  }

  void _deleteAllData() { 
    _storage.deleteAllItems(); 
    setState(() { 
      _items = []; 
      _categoryAliases = {}; 
    }); 
  }

  void _renameCategory(String originalKey) {
    HapticFeedback.selectionClick();
    String currentName = _categoryAliases[originalKey] ?? (originalKey.startsWith('cat_') ? T.get(originalKey) : originalKey);
    TextEditingController ctrl = TextEditingController(text: currentName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(T.get('group_rename')),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: T.get('new_name'), border: const OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))), 
        ElevatedButton(onPressed: () { setState(() => _categoryAliases[originalKey] = ctrl.text); _storage.saveCategoryAliases(_categoryAliases); Navigator.pop(ctx); }, child: Text(T.get('save')))
      ],
    ));
  }

  void _incrementUsage(Item item) { 
    HapticFeedback.mediumImpact(); 
    item.manualClicks++; 
    item.usageHistory.add(DateTime.now().millisecondsSinceEpoch); 
    item.save();
    setState(() {}); 
  }

  void _updateUsageCount(Item item, int newCount) { 
    item.manualClicks = newCount; 
    item.save();
    setState(() {}); 
  }

  void _archiveItem(Item item) { 
    HapticFeedback.heavyImpact(); 
    item.consumedDate = DateTime.now(); 
    item.save();
    setState(() {}); 
  }

  void _restoreItem(Item item) { 
    HapticFeedback.mediumImpact(); 
    item.consumedDate = null; 
    item.save();
    setState(() {}); 
  }

  List<Item> _getFilteredItems(List<Item> inputList) {
    if (_searchQuery.isEmpty) {
      return inputList;
    }
    return inputList.where((i) {
      final nameMatch = i.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final catMatch = i.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final alias = _categoryAliases[i.category]?.toLowerCase() ?? "";
      final aliasMatch = alias.contains(_searchQuery.toLowerCase());
      return nameMatch || catMatch || aliasMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAll = _getFilteredItems(_items);
    final purchasesActive = filteredAll.where((i) => !i.isSubscription && i.isActive).toList();
    final purchasesArchived = filteredAll.where((i) => !i.isSubscription && !i.isActive).toList();
    final subsActive = filteredAll.where((i) => i.isSubscription && i.isActive).toList();
    final subsArchived = filteredAll.where((i) => i.isSubscription && !i.isActive).toList();

    double displayedCost = 0;
    String headerTitle = "";
    final double totalDailyBurn = _items.where((i) => i.isActive).fold(0.0, (sum, item) => sum + item.pricePerDay);
    if (_currentTabIndex == 0) { 
      displayedCost = purchasesActive.fold(0.0, (sum, item) => sum + item.pricePerDay); 
      headerTitle = T.get('daily_cost_items'); 
    } else if (_currentTabIndex == 1) { 
      displayedCost = subsActive.fold(0.0, (sum, item) => sum + item.pricePerDay); 
      headerTitle = T.get('daily_cost_subs'); 
    } else { 
      displayedCost = totalDailyBurn; 
      headerTitle = T.get('daily_cost'); 
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isRetro = widget.currentTheme == 'retro';
    final fabColor = isRetro ? _juzyColor : colorScheme.primary;
    final dailyBurnTextStyle = isRetro ? const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFD4522A), height: 1.0, shadows: [Shadow(offset: Offset(2, 2), color: Color(0xFFF2B84B)), Shadow(offset: Offset(3, 3), color: Color(0xFF6BB8A7))]) : TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white);
    final happyBackground = isRetro ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF9F3E6), Color(0xFFF5F5DC)], begin: Alignment.topCenter, end: Alignment.bottomCenter)) : null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50, 
        elevation: 0, 
        shadowColor: Colors.transparent, 
        surfaceTintColor: Colors.transparent,
        title: _isSearching ? TextField(controller: _searchController, autofocus: true, decoration: InputDecoration(hintText: T.get('search'), border: InputBorder.none), onChanged: (val) => setState(() => _searchQuery = val))
          : ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFDC830), Color(0xFFF37335)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds), child: Text(T.get('app_name'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: isRetro ? 3.0 : 2.0))),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () { HapticFeedback.selectionClick(); setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchQuery = ""; _searchController.clear(); } }); }),
          if (!_isSearching) IconButton(icon: const Icon(Icons.settings), onPressed: () { HapticFeedback.selectionClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(onThemeChanged: widget.onThemeChanged, currentTheme: widget.currentTheme, onDeleteAllData: _deleteAllData, onLanguageChanged: widget.onLanguageChanged, onLoadDemoData: () { _createDemoData(); setState(() {}); }))).then((_) => _loadData()); })
        ],
      ),
      body: Container(decoration: happyBackground, child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: Column(children: [
                  if (!_isSearching) Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: Column(children: [Text(headerTitle, style: TextStyle(color: isRetro ? const Color(0xFF3A2817) : colorScheme.primary, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: isRetro ? FontStyle.italic : FontStyle.normal)), const SizedBox(height: 2), FittedBox(fit: BoxFit.scaleDown, child: RollingNumber(value: displayedCost, style: dailyBurnTextStyle, suffix: T.currency))])),
                  TabBar(controller: _tabController, onTap: (i) => HapticFeedback.selectionClick(), indicatorColor: isRetro ? const Color(0xFFD4522A) : colorScheme.primary, indicatorWeight: isRetro ? 4.0 : 2.0, labelColor: isRetro ? const Color(0xFFD4522A) : colorScheme.primary, unselectedLabelColor: isRetro ? const Color(0xFF9B8E3F) : Colors.grey, dividerColor: Colors.transparent, labelStyle: const TextStyle(fontWeight: FontWeight.bold), tabs: [Tab(text: T.get('items')), Tab(text: T.get('subs')), Tab(text: T.get('stats'))]),
                  Expanded(child: TabBarView(controller: _tabController, children: [_buildCategoryList(purchasesActive, purchasesArchived, T.get('empty_items'), false, false), _buildCategoryList(subsActive, subsArchived, T.get('empty_subs'), _showDailyRates, true), _buildStatisticsPage()])),
                ]))))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: fabColor, shape: isRetro ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3A2817), width: 2)) : null, elevation: isRetro ? 6 : 6, onPressed: _showAddDialog, icon: Icon(Icons.add, color: isRetro ? Colors.white : colorScheme.onPrimary), label: Text(T.get('new_item'), style: TextStyle(color: isRetro ? Colors.white : colorScheme.onPrimary, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildEmptyState(String text) { 
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.3)), const SizedBox(height: 15), Text(text, style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 50)])); 
  }

  Widget _buildCategoryList(List<Item> items, List<Item> archivedItems, String emptyText, bool applyDailyRate, bool hasToggle) {
    if (items.isEmpty && archivedItems.isEmpty) {
      return _buildEmptyState(emptyText);
    }
    double totalCostPerUse = 0; 
    int count = 0; 
    for (var i in _items.where((x) => x.isActive)) { 
      totalCostPerUse += i.costPerUse; 
      count++; 
    } 
    double avgCost = count > 0 ? totalCostPerUse / count : 0;
    
    Map<String, List<Item>> grouped = {}; 
    for (var item in items) { 
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = []; 
      }
      grouped[item.category]!.add(item); 
    }
    
    List<String> keys = grouped.keys.toList()..sort();
    archivedItems.sort((a, b) => (b.consumedDate ?? DateTime(0)).compareTo(a.consumedDate ?? DateTime(0)));
    
    Map<int, List<Item>> groupedArchived = {}; 
    for (var item in archivedItems) { 
      int year = (item.consumedDate ?? DateTime.now()).year; 
      if (!groupedArchived.containsKey(year)) {
        groupedArchived[year] = []; 
      }
      groupedArchived[year]!.add(item); 
    }
    
    List<int> archivedYears = groupedArchived.keys.toList()..sort((a, b) => b.compareTo(a));
    final bool isRetro = widget.currentTheme == 'retro'; 
    final Color headerColor = isRetro ? const Color(0xFFD4522A) : Colors.grey;

    return Stack(children: [
        ListView(padding: EdgeInsets.symmetric(horizontal: 20, vertical: hasToggle ? 40 : 10), children: [
            ...keys.asMap().entries.map((entry) {
              return StaggeredSlide(delay: entry.key * 50, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(left: 8, bottom: 6, top: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text((_categoryAliases[entry.value] ?? (entry.value.startsWith('cat_') ? T.get(entry.value) : entry.value)).toUpperCase(), style: TextStyle(color: headerColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(Icons.edit, size: 14, color: Colors.grey.withValues(alpha: 0.5)), onPressed: () => _renameCategory(entry.value))])),
                  Container(margin: const EdgeInsets.only(bottom: 15), clipBehavior: Clip.hardEdge, decoration: isRetro ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6BB8A7), width: 3), boxShadow: const [BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4), blurRadius: 0)]) : BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: grouped[entry.value]!.map((item) { final realIndex = _items.indexOf(item); return ItemTile(item: item, index: realIndex, isLast: item == grouped[entry.value]!.last, avgCost: avgCost, showDailyRates: applyDailyRate, isRetro: isRetro, onTap: () => _openDetail(item, realIndex)); }).toList())),
                ]));
            }),
            if (archivedItems.isNotEmpty) ...[
              const SizedBox(height: 30), 
              Divider(thickness: 2, color: isRetro ? const Color(0xFFD4522A).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1)), 
              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: Text(T.get('history'), style: TextStyle(color: isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)))), 
              ...archivedYears.map((year) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10), child: Text("$year", style: TextStyle(color: isRetro ? const Color(0xFFD4522A) : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20))), 
                Column(children: groupedArchived[year]!.map((item) => HistoryTile(item: item, isRetro: isRetro, onTap: () => _openDetail(item, _items.indexOf(item)))).toList())
              ]))
            ], 
            const SizedBox(height: 60)
        ]),
        if (hasToggle) Positioned(top: 10, right: 20, child: GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() => _showDailyRates = !_showDailyRates); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _juzyColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _juzyColor.withValues(alpha: 0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_horiz, size: 14, color: _juzyColor), const SizedBox(width: 6), Text(_showDailyRates ? T.get('view_daily') : T.get('view_usage'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _juzyColor))])))),
    ]);
  }

  Widget _buildStatisticsPage() {
    final activeItems = _items.where((i) => i.isActive).toList();
    final activeSubs = activeItems.where((i) => i.isSubscription).toList();
    final activeOneTime = activeItems.where((i) => !i.isSubscription).toList();

    double yearlySubsCost = activeSubs.fold(0.0, (sum, sub) => sum + (sub.subscriptionPeriod == 'year' ? sub.price : sub.price * 12));
    double inventoryValue = activeOneTime.fold(0.0, (sum, item) => sum + item.price);

    List<Item> allItemsForRanking = List.from(_items)..sort((a, b) => a.costPerUse.compareTo(b.costPerUse));

    final bestItems = allItemsForRanking.take(3).toList();
    final validWorstItems = allItemsForRanking.where((i) => !i.isActive || i.daysOwned > 14).toList();
    final worstItems = validWorstItems.reversed.take(3).toList();

    Map<String, double> categoryCosts = {};
    double totalBurn = 0;
    for (var i in activeItems) { 
      double cost = i.pricePerDay; 
      totalBurn += cost; 
      categoryCosts[i.category] = (categoryCosts[i.category] ?? 0.0) + cost; 
    }

    final isHappy = widget.currentTheme == 'retro';
    if (_items.isEmpty) return _buildEmptyState(T.get('empty_stats'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _buildStatCard(T.get('stats_inventory'), inventoryValue, isHappy ? const Color(0xFF6BB8A7) : Theme.of(context).colorScheme.secondary, true)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(T.get('stats_yearly_subs'), yearlySubsCost, isHappy ? const Color(0xFFF2B84B) : Theme.of(context).colorScheme.primary, true))
          ]),
          const SizedBox(height: 30),

          if (bestItems.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(T.get('stats_best').toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      ...bestItems.map((i) => _buildMiniRankItem(i, true, isHappy)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(T.get('stats_worst').toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      ...worstItems.map((i) => _buildMiniRankItem(i, false, isHappy)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],

          _buildLongevityRace(isHappy),
          const SizedBox(height: 40),

          if (totalBurn > 0) ...[
            Text(T.get('cost_dist'), style: TextStyle(color: isHappy ? const Color(0xFF5D4037) : Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)), 
            const SizedBox(height: 15), 
            _buildBarChart(categoryCosts, totalBurn)
          ],
          
          const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildLongevityRace(bool isRetro) {
    Set<String> activeCategories = _items.map((i) => i.category).toSet();
    if (activeCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!activeCategories.contains(_selectedRaceCategory)) {
      _selectedRaceCategory = activeCategories.first;
    }

    List<Item> raceItems = _items.where((i) => i.category == _selectedRaceCategory).toList();
    
    raceItems.sort((a, b) {
      int aMax = max(a.daysOwned, a.projectedLifespanDays ?? 365);
      int bMax = max(b.daysOwned, b.projectedLifespanDays ?? 365);
      return bMax.compareTo(aMax);
    });

    int maxScaleDays = 1;
    for (var item in raceItems) {
      int itemMax = max(item.daysOwned, item.projectedLifespanDays ?? 365);
      if (itemMax > maxScaleDays) {
        maxScaleDays = itemMax;
      }
    }

    final Color textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(T.get('lifespan_race'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: activeCategories.map((catKey) {
              bool isSelected = _selectedRaceCategory == catKey;
              String label = _categoryAliases[catKey] ?? (catKey.startsWith('cat_') ? T.get(catKey) : catKey);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRaceCategory = catKey);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        ...raceItems.map((item) {
          int planned = item.projectedLifespanDays ?? 365;
          int actual = item.daysOwned;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text(item.emoji ?? "📦"),
                      const SizedBox(width: 8),
                      Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    ]),
                    Text("${actual}d / ${planned}d", style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                
                SizedBox(
                  height: 12,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth;
                      double actualWidth = (actual / maxScaleDays).clamp(0.0, 1.0) * maxWidth;
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(width: maxWidth, decoration: BoxDecoration(color: isRetro ? Colors.black12 : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6))),
                          Container(
                            width: actualWidth,
                            decoration: BoxDecoration(
                              color: actual >= planned ? (isRetro ? const Color(0xFF6BB8A7) : Colors.green) : (isRetro ? const Color(0xFFD4522A) : Theme.of(context).colorScheme.primary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniRankItem(Item item, bool isBest, bool isRetro) {
    return GestureDetector(
      onTap: () => _openDetail(item, _items.indexOf(item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isRetro ? Colors.white : (isBest ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isBest ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3))
        ),
        child: Row(
          children: [
            Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text("${item.costPerUse.toStringAsFixed(2)}${T.currency}", style: TextStyle(color: isBest ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 10)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> categoryCosts, double totalBurn) {
    var sortedEntries = categoryCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final isRetro = widget.currentTheme == 'retro';
    final colors = [const Color(0xFFD4522A), const Color(0xFFF2B84B), const Color(0xFF6BB8A7)];

    return Column(children: sortedEntries.asMap().entries.map((entry) {
        double percentage = entry.value.value / totalBurn;
        String displayName = _categoryAliases[entry.value.key] ?? (entry.value.key.startsWith('cat_') ? T.get(entry.value.key) : entry.value.key);
        return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Stack(children: [
            Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: isRetro ? Colors.white : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8))),
            FractionallySizedBox(widthFactor: percentage, child: Container(height: 30, decoration: BoxDecoration(color: colors[entry.key % colors.length], borderRadius: BorderRadius.circular(8)))),
            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentage > 0.5 ? Colors.white : (isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface))),
              Text("${(percentage * 100).toStringAsFixed(0)}%")
            ]))),
        ]));
    }).toList());
  }

  Widget _buildStatCard(String title, double value, Color color, [bool useInt = false]) {
    final isRetro = widget.currentTheme == 'retro';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isRetro ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A2817), width: 3), boxShadow: const [BoxShadow(color: Color(0xFF3A2817), offset: Offset(4, 4))]) : BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(children: [
        RollingNumber(value: value, isInt: useInt, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isRetro ? Colors.white : color), suffix: T.currency),
        const SizedBox(height: 5),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isRetro ? FontWeight.bold : FontWeight.normal, color: isRetro ? const Color(0xFF3A2817) : Colors.grey))
      ])
    );
  }

  void _openDetail(Item item, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(
      item: item, 
      heroTag: "item_$index", 
      onEdit: () { Navigator.pop(context); _openEditWizard(item, index); }, 
      onUsageAdd: () => _incrementUsage(item), 
      onUsageCorrect: (n) => _updateUsageCount(item, n), 
      onArchive: () { _archiveItem(item); Navigator.pop(context); }, 
      onRestore: () => _restoreItem(item) 
    )));
  }

  void _openEditWizard(Item item, int index) {
     Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(item: item, availableCategories: _categories, customEmojis: _customCategoryEmojis, onCategoriesChanged: (nc, ne) { setState(() { _categories = nc; _customCategoryEmojis = ne; }); _storage.saveCustomCategories(_categories.where((c) => !_standardCategories.contains(c)).toList()); _storage.saveCustomEmojis(ne); }, onSave: (u) { setState(() => _items[index] = u); _storage.saveItem(u); }, onDelete: () { setState(() => _items.removeAt(index)); _storage.deleteItem(item.id); Navigator.pop(context); } )));
  }

  void _showAddDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(item: Item(name: "", price: 0, purchaseDate: DateTime.now(), category: 'cat_misc'), availableCategories: _categories, customEmojis: _customCategoryEmojis, onCategoriesChanged: (nc, ne) { setState(() { _categories = nc; _customCategoryEmojis = ne; }); _storage.saveCustomCategories(_categories.where((c) => !_standardCategories.contains(c)).toList()); _storage.saveCustomEmojis(ne); }, onSave: (ni) { setState(() => _items.add(ni)); _storage.saveItem(ni); }, onDelete: () {} )));
  }
}