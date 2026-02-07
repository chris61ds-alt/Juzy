import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../models/item.dart';
import 'settings_page.dart';
import 'edit_item_page.dart';
import 'item_detail_page.dart';
import '../utils/translations.dart'; 

// Helfer-Klassen für Animationen
class _RollingNumber extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;
  const _RollingNumber({required this.value, required this.style, this.suffix = ""});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500), 
      curve: Curves.easeOutExpo, 
      builder: (context, val, child) => Text("${val.toStringAsFixed(2)}$suffix", style: style),
    );
  }
}

class _StaggeredSlide extends StatefulWidget {
  final Widget child;
  final int delay; 
  const _StaggeredSlide({required this.child, required this.delay});
  @override
  State<_StaggeredSlide> createState() => _StaggeredSlideState();
}

class _StaggeredSlideState extends State<_StaggeredSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.forward(); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _offsetAnim, child: widget.child)); }
}

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

  final Color _juzyColor = const Color(0xFF6BB8A7);
  final String _privacyUrl = "https://chris61ds-alt.github.io/Juzy-Legal/";

  @override
  void initState() {
    super.initState();
    _categories = List.from(_standardCategories);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation?.value == _tabController.index) {
        setState(() {}); 
      }
    });
    _loadData().then((_) => _checkFirstRun());
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('first_run') ?? true;
    
    if (isFirstRun) {
      T.code = 'en'; 
      widget.onLanguageChanged('en');
      if (mounted) {
        _showOnboardingDialog(prefs);
      } else {
        _createDemoData(); 
      }
    }
  }

  void _createDemoData() {
    DateTime now = DateTime.now();
    List<Item> demoItems = [];

    if (T.code == 'en') {
      demoItems = [
        Item(name: "MacBook Air", price: 1299.00, purchaseDate: now.subtract(const Duration(days: 365)), category: "cat_tech", emoji: "💻", usagePeriod: "day", estimatedUsageCount: 1, isSubscription: false, subscriptionPeriod: "", manualClicks: 0, projectedLifespanDays: 1825),
        Item(name: "Netflix Premium", price: 17.99, purchaseDate: now.subtract(const Duration(days: 180)), category: "cat_entertainment", emoji: "🍿", usagePeriod: "", estimatedUsageCount: 0, isSubscription: true, subscriptionPeriod: "month", manualClicks: 85, targetCost: 0.50),
        Item(name: "Gym Membership", price: 45.00, purchaseDate: now.subtract(const Duration(days: 300)), category: "cat_health", emoji: "💪", usagePeriod: "", estimatedUsageCount: 0, isSubscription: true, subscriptionPeriod: "month", manualClicks: 90, targetCost: 3.00),
        Item(name: "Basic T-Shirt", price: 15.00, purchaseDate: now.subtract(const Duration(days: 600)), consumedDate: now.subtract(const Duration(days: 10)), category: "cat_clothes", emoji: "👕", usagePeriod: "", estimatedUsageCount: 0, isSubscription: false, subscriptionPeriod: "", manualClicks: 50, targetCost: 0.50, projectedLifespanDays: 365),
      ];
    } else {
      demoItems = [
        Item(name: "MacBook Air", price: 1299.00, purchaseDate: now.subtract(const Duration(days: 365)), category: "cat_tech", emoji: "💻", usagePeriod: "day", estimatedUsageCount: 1, isSubscription: false, subscriptionPeriod: "", manualClicks: 0, projectedLifespanDays: 1825),
        Item(name: "Netflix Premium", price: 17.99, purchaseDate: now.subtract(const Duration(days: 180)), category: "cat_entertainment", emoji: "🍿", usagePeriod: "", estimatedUsageCount: 0, isSubscription: true, subscriptionPeriod: "month", manualClicks: 85, targetCost: 0.50),
        Item(name: "Fitnessstudio", price: 45.00, purchaseDate: now.subtract(const Duration(days: 300)), category: "cat_health", emoji: "💪", usagePeriod: "", estimatedUsageCount: 0, isSubscription: true, subscriptionPeriod: "month", manualClicks: 90, targetCost: 3.00),
        Item(name: "Basic T-Shirt", price: 15.00, purchaseDate: now.subtract(const Duration(days: 600)), consumedDate: now.subtract(const Duration(days: 10)), category: "cat_clothes", emoji: "👕", usagePeriod: "", estimatedUsageCount: 0, isSubscription: false, subscriptionPeriod: "", manualClicks: 50, targetCost: 0.50, projectedLifespanDays: 365),
      ];
    }

    setState(() {
      _items = demoItems;
    });
    _saveData();
  }

  void _showOnboardingDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final chipBg = isDark ? Colors.black54 : Colors.grey[200];

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text("🥭", style: TextStyle(fontSize: 50)),
                const SizedBox(height: 15),
                Text(T.get('choose_lang'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("Deutsch"),
                      selected: T.code == 'de',
                      onSelected: (b) {
                        widget.onLanguageChanged('de');
                        setStateDialog(() {}); 
                      },
                      selectedColor: _juzyColor,
                      labelStyle: TextStyle(color: T.code == 'de' ? Colors.white : textColor, fontWeight: FontWeight.bold),
                      backgroundColor: chipBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("English"),
                      selected: T.code == 'en',
                      onSelected: (b) {
                        widget.onLanguageChanged('en');
                        setStateDialog(() {});
                      },
                      selectedColor: _juzyColor,
                      labelStyle: TextStyle(color: T.code == 'en' ? Colors.white : textColor, fontWeight: FontWeight.bold),
                      backgroundColor: chipBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                Text(T.get('onboarding_welcome'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _juzyColor)),
                const SizedBox(height: 10),
                Text(T.get('onboarding_desc'), textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.8), height: 1.4)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                     final Uri url = Uri.parse(_privacyUrl);
                     if (!await launchUrl(url)) {
                       debugPrint('Could not launch $_privacyUrl');
                     }
                  },
                  child: Text(
                    T.get('onboarding_legal'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5), decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      prefs.setBool('first_run', false);
                      Navigator.pop(context);
                      _createDemoData(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _juzyColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0
                    ),
                    child: Text(T.get('lets_go'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          );
        });
      }
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('items');
    if (data != null && data != "[]") {
      setState(() => _items = (json.decode(data) as List).map((i) => Item.fromJson(i)).toList());
    }
    final String? aliasData = prefs.getString('cat_aliases');
    if (aliasData != null) {
      setState(() => _categoryAliases = Map<String, String>.from(json.decode(aliasData)));
    }
    
    final List<String>? customCats = prefs.getStringList('custom_categories');
    final String? customEmojisJson = prefs.getString('custom_category_emojis');
    
    if (customEmojisJson != null) {
      _customCategoryEmojis = Map<String, String>.from(json.decode(customEmojisJson));
    }

    setState(() {
      _categories = List.from(_standardCategories);
      if (customCats != null) {
        for(var c in customCats) {
          if(!_categories.contains(c)) _categories.add(c);
        }
      }
    });
  }

  void _deleteAllData() {
    setState(() { _items = []; _categoryAliases = {}; });
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('items', json.encode(_items.map((i) => i.toJson()).toList()));
    prefs.setString('cat_aliases', json.encode(_categoryAliases));
    
    List<String> customCats = _categories.where((c) => !_standardCategories.contains(c)).toList();
    prefs.setStringList('custom_categories', customCats);
    prefs.setString('custom_category_emojis', json.encode(_customCategoryEmojis));
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
        ElevatedButton(onPressed: () {
          setState(() => _categoryAliases[originalKey] = ctrl.text);
          _saveData();
          Navigator.pop(ctx);
        }, child: Text(T.get('save')))
      ],
    ));
  }

  // --- HIER WURDE DIE SNACKBAR FUNKTION ENTFERNT ---

  void _incrementUsage(Item item) {
    HapticFeedback.mediumImpact();
    setState(() { item.manualClicks++; });
    _saveData();
    // Keine Snackbar mehr
  }

  void _updateUsageCount(Item item, int newCount) {
    setState(() { item.manualClicks = newCount; });
    _saveData();
  }

  void _archiveItem(Item item) {
    HapticFeedback.heavyImpact();
    setState(() { item.consumedDate = DateTime.now(); });
    _saveData();
    // Keine Snackbar mehr (Achtung: Undo ist damit auch weg, aber das wolltest du so)
  }

  void _restoreItem(Item item) {
    HapticFeedback.mediumImpact();
    setState(() { item.consumedDate = null; });
    _saveData();
    // Keine Snackbar mehr
  }

  List<Item> _getFilteredItems(List<Item> inputList) {
    if (_searchQuery.isEmpty) return inputList;
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

    final dailyBurn = _items.where((i) => i.isActive).fold(0.0, (sum, item) => sum + item.pricePerDay);
    final colorScheme = Theme.of(context).colorScheme;
    final isHappy = widget.currentTheme == 'retro';
    final fabColor = isHappy ? _juzyColor : colorScheme.primary;
    final dailyBurnTextStyle = isHappy 
        ? const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFD4522A), height: 1.0, shadows: [Shadow(offset: Offset(2, 2), color: Color(0xFFF2B84B)), Shadow(offset: Offset(3, 3), color: Color(0xFF6BB8A7))])
        : TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white);
    final happyBackground = isHappy ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF9F3E6), Color(0xFFF5F5DC)], begin: Alignment.topCenter, end: Alignment.bottomCenter)) : null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50, 
        elevation: 2,
        shadowColor: isHappy ? Colors.black12 : Colors.black26,
        surfaceTintColor: Colors.transparent,
        title: _isSearching 
          ? TextField(controller: _searchController, autofocus: true, decoration: InputDecoration(hintText: T.get('search'), border: InputBorder.none), onChanged: (val) => setState(() => _searchQuery = val))
          : ShaderMask( 
              shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFDC830), Color(0xFFF37335)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds), 
              child: Text(T.get('app_name'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: isHappy ? 3.0 : 2.0))
            ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () { HapticFeedback.selectionClick(); setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchQuery = ""; _searchController.clear(); } }); }),
          
          if (!_isSearching) IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () { 
              HapticFeedback.selectionClick(); 
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(
                onThemeChanged: widget.onThemeChanged, 
                currentTheme: widget.currentTheme, 
                onDeleteAllData: _deleteAllData, 
                onLanguageChanged: widget.onLanguageChanged,
                onLoadDemoData: () {   
                  _createDemoData(); 
                  setState(() {});
                }
              ))).then((_) => _loadData()); 
            }
          )
        ],
      ),
      body: Container(
        decoration: happyBackground,
        child: SafeArea(
          child: Column(
            children: [
              if (!_isSearching) Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: Column(children: [Text(T.get('daily_cost'), style: TextStyle(color: isHappy ? const Color(0xFF3A2817) : colorScheme.primary, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: isHappy ? FontStyle.italic : FontStyle.normal)), const SizedBox(height: 2), FittedBox(fit: BoxFit.scaleDown, child: _RollingNumber(value: dailyBurn, style: dailyBurnTextStyle, suffix: "€"))])),
              TabBar(
                controller: _tabController,
                onTap: (i) => HapticFeedback.selectionClick(), 
                indicatorColor: isHappy ? const Color(0xFFD4522A) : colorScheme.primary, 
                indicatorWeight: isHappy ? 4.0 : 2.0, 
                labelColor: isHappy ? const Color(0xFFD4522A) : colorScheme.primary, 
                unselectedLabelColor: isHappy ? const Color(0xFF9B8E3F) : Colors.grey, 
                dividerColor: Colors.transparent, 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold), 
                tabs: [Tab(text: T.get('items')), Tab(text: T.get('subs')), Tab(text: T.get('stats'))]
              ),
              Expanded(child: TabBarView(controller: _tabController, children: [
                _buildCategoryList(purchasesActive, purchasesArchived, T.get('empty_items'), false, false), 
                _buildCategoryList(subsActive, subsArchived, T.get('empty_subs'), _showDailyRates, true), 
                _buildStatisticsPage()
              ])),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: fabColor, shape: isHappy ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3A2817), width: 2)) : null, elevation: isHappy ? 6 : 6, onPressed: _showAddDialog, icon: Icon(Icons.add, color: isHappy ? Colors.white : colorScheme.onPrimary), label: Text(T.get('new_item'), style: TextStyle(color: isHappy ? Colors.white : colorScheme.onPrimary, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 15), Text(text, style: TextStyle(color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 50)]));
  }

  Widget _buildCategoryList(List<Item> items, List<Item> archivedItems, String emptyText, bool applyDailyRate, bool hasToggle) {
    if (items.isEmpty && archivedItems.isEmpty) return _buildEmptyState(emptyText);
    
    double totalCostPerUse = 0;
    int count = 0;
    for (var i in _items.where((x) => x.isActive)) { totalCostPerUse += i.costPerUse; count++; }
    double avgCost = count > 0 ? totalCostPerUse / count : 0;
    
    Map<String, List<Item>> grouped = {};
    for (var item in items) { if (!grouped.containsKey(item.category)) grouped[item.category] = []; grouped[item.category]!.add(item); }
    List<String> keys = grouped.keys.toList()..sort();

    archivedItems.sort((a, b) => (b.consumedDate ?? DateTime(0)).compareTo(a.consumedDate ?? DateTime(0)));
    Map<int, List<Item>> groupedArchived = {};
    for (var item in archivedItems) {
      int year = (item.consumedDate ?? DateTime.now()).year;
      if (!groupedArchived.containsKey(year)) groupedArchived[year] = [];
      groupedArchived[year]!.add(item);
    }
    List<int> archivedYears = groupedArchived.keys.toList()..sort((a, b) => b.compareTo(a));

    final Color headerColor = widget.currentTheme == 'retro' ? const Color(0xFFD4522A) : Colors.grey;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: hasToggle ? 40 : 10),
          children: [
            ...keys.asMap().entries.map((entry) {
              int index = entry.key;
              String catKey = entry.value;
              String displayName = _categoryAliases[catKey] ?? (catKey.startsWith('cat_') ? T.get(catKey) : catKey);
              List<Item> catItems = grouped[catKey]!;
              return _StaggeredSlide(
                delay: index * 50, 
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(left: 8, bottom: 6, top: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(displayName.toUpperCase(), style: TextStyle(color: headerColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(Icons.edit, size: 14, color: Colors.grey.withOpacity(0.5)), onPressed: () => _renameCategory(catKey))])),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15), clipBehavior: Clip.hardEdge, 
                    decoration: widget.currentTheme == 'retro' 
                      ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6BB8A7), width: 3), boxShadow: const [BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4), blurRadius: 0)]) 
                      : BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.08 : 0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(children: catItems.map((item) { final realIndex = _items.indexOf(item); return _buildListItem(item, realIndex, item == catItems.last, avgCost, applyDailyRate); }).toList()),
                  ),
                ]),
              );
            }),

            if (archivedItems.isNotEmpty) ...[
              const SizedBox(height: 30),
              Divider(thickness: 2, color: widget.currentTheme == 'retro' ? const Color(0xFFD4522A).withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: Text(T.get('history'), style: TextStyle(color: widget.currentTheme == 'retro' ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16))),
              ),
              ...archivedYears.map((year) {
                 return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10),
                      child: Text("$year", style: TextStyle(color: widget.currentTheme == 'retro' ? const Color(0xFFD4522A) : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    Column(
                      children: groupedArchived[year]!.map((item) {
                        final realIndex = _items.indexOf(item);
                        return _buildHistoryCardItem(item, realIndex, widget.currentTheme == 'retro', Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black);
                      }).toList(),
                    )
                  ]
                 );
              })
            ],
            const SizedBox(height: 60), 
          ],
        ),

        if (hasToggle) Positioned(top: 10, right: 20, child: GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() => _showDailyRates = !_showDailyRates); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _juzyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _juzyColor.withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_horiz, size: 14, color: _juzyColor), const SizedBox(width: 6), Text(_showDailyRates ? T.get('view_daily') : T.get('view_usage'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _juzyColor))])))),
      ],
    );
  }

  Widget _buildListItem(Item item, int realIndex, bool isLast, double avgCost, bool applyDailyRate) {
    final isHappy = widget.currentTheme == 'retro';
    Color textColor = isHappy ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    Color subTextColor = isHappy ? Colors.grey[700]! : Colors.grey;
    Color? statusColor;
    if (avgCost > 0) {
      if (item.costPerUse > avgCost * 2.0) statusColor = Colors.red.withOpacity(isHappy ? 0.1 : 0.15);
      else if (item.costPerUse < avgCost * 0.5) statusColor = Colors.green.withOpacity(isHappy ? 0.1 : 0.15);
    }
    double? progress;
    bool reachedGoal = false;
    if (item.targetCost != null && item.targetCost! > 0 && !item.isSubscription) {
      double neededUses = item.price / item.targetCost!;
      if (neededUses < 1) neededUses = 1;
      progress = item.totalUsesCalculated / neededUses;
      if (progress >= 1.0) reachedGoal = true;
    }
    String priceDisplay = applyDailyRate ? "${item.pricePerDay.toStringAsFixed(2)}€" : (item.isSubscription ? "${item.price.toStringAsFixed(2)}€" : "${item.costPerUse.toStringAsFixed(2)}€");
    String unitDisplay = applyDailyRate ? "/ ${T.get('per_day')}" : (item.isSubscription ? "/ ${item.subscriptionPeriod == 'year' ? T.get('years') : T.get('months')}" : T.get('per_usage'));

    return Container(
      color: statusColor,
      child: Column(children: [
        ListTile(
          onTap: () => _openDetail(item, realIndex),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          leading: Hero(tag: "item_img_${item.name}_$realIndex", child: Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isHappy ? const Color(0xFFF4D98D) : Colors.grey.withOpacity(0.1), border: isHappy ? Border.all(color: const Color(0xFF3A2817), width: 1.5) : null, image: item.imagePath != null ? DecorationImage(image: FileImage(File(item.imagePath!)), fit: BoxFit.cover) : null), child: item.imagePath == null ? Material(color: Colors.transparent, child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 26))) : null)),
          title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Row(children: [Flexible(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))), if (reachedGoal) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.emoji_events, size: 16, color: Colors.amber))]))]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.isSubscription ? (item.subscriptionPeriod == 'year' ? T.get('yearly') : T.get('monthly')) : "${item.totalUsesCalculated.toInt()} ${T.get('times_used')}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: subTextColor)), 
              if (progress != null && !reachedGoal) Padding(padding: const EdgeInsets.only(top: 6, right: 20), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.withOpacity(0.2), color: isHappy ? const Color(0xFF6BB8A7) : Colors.blueAccent, minHeight: 6, borderRadius: BorderRadius.circular(3)))
            ])
          ),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(priceDisplay, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isHappy && reachedGoal ? const Color(0xFF6BB8A7) : textColor)), Text((item.targetCost != null && item.targetCost! > 0 && !applyDailyRate) ? "${T.get('goal')}: ${item.targetCost!.toStringAsFixed(2)}€" : unitDisplay, style: TextStyle(fontSize: 10, color: subTextColor))]),
        ),
        if (!isLast) Divider(height: 1, indent: 80, endIndent: 20, color: isHappy ? const Color(0xFF6BB8A7).withOpacity(0.3) : Colors.white10),
      ]),
    );
  }

  Widget _buildStatisticsPage() {
    final activeItems = _items.where((i) => i.isActive).toList();
    final historyItems = _items.where((i) => !i.isActive).toList();
    historyItems.sort((a, b) => (b.consumedDate ?? DateTime(0)).compareTo(a.consumedDate ?? DateTime(0)));
    Map<String, double> categoryCosts = {};
    double totalBurn = 0;
    for (var i in activeItems) { double cost = i.pricePerDay; totalBurn += cost; if (!categoryCosts.containsKey(i.category)) categoryCosts[i.category] = 0; categoryCosts[i.category] = categoryCosts[i.category]! + cost; }
    double burnSubs = activeItems.where((i) => i.isSubscription).fold(0, (sum, i) => sum + i.pricePerDay);
    double burnItems = activeItems.where((i) => !i.isSubscription).fold(0, (sum, i) => sum + i.pricePerDay);
    final isHappy = widget.currentTheme == 'retro';
    Color textColor = isHappy ? const Color(0xFF5D4037) : Theme.of(context).colorScheme.onSurface;

    if (activeItems.isEmpty && historyItems.isEmpty) return _buildEmptyState(T.get('empty_stats'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (totalBurn > 0) ...[Text(T.get('cost_dist'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)), const SizedBox(height: 15), _buildBarChart(categoryCosts, totalBurn)],
          const SizedBox(height: 30),
          Text(T.get('daily_usage_sum'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _buildStatCard(T.get('daily_item'), burnItems, isHappy ? const Color(0xFF6BB8A7) : Theme.of(context).colorScheme.secondary)), 
            const SizedBox(width: 12), 
            Expanded(child: _buildStatCard(T.get('daily_subs'), burnSubs, isHappy ? const Color(0xFFF2B84B) : Theme.of(context).colorScheme.primary))
          ]),
          const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildHistoryCardItem(Item item, int realIndex, bool isHappy, Color textColor) {
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
    Color cardBg = isHappy ? (isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)) : (isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1));

    return GestureDetector(
      onTap: () => _openDetail(item, realIndex), 
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(15)), 
        child: Row(children: [
            Text(item.emoji ?? "🏁", style: const TextStyle(fontSize: 26)), 
            const SizedBox(width: 15), 
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), Text("${item.totalUsesCalculated.toInt()} ${T.get('times_used')}", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8)))])), 
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(children: [Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)), const SizedBox(width: 4), Icon(isSuccess ? Icons.check_circle : Icons.warning_amber_rounded, color: statusColor, size: 16)]), Text("${item.costPerUse.toStringAsFixed(2)}€", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor))])
        ])
      )
    ); 
  }

  Widget _buildBarChart(Map<String, double> categoryCosts, double totalBurn) {
    var sortedEntries = categoryCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final isHappy = widget.currentTheme == 'retro';
    final colors = [const Color(0xFFD4522A), const Color(0xFFF2B84B), const Color(0xFF6BB8A7), const Color(0xFF8DC9BB), const Color(0xFFC44536)];
    final Color contrastColor = isHappy ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    final Color textColorInsideBar = isHappy ? const Color(0xFF3A2817) : Colors.white;

    return Column(children: sortedEntries.asMap().entries.map((entry) {
        double percentage = totalBurn > 0 ? entry.value.value / totalBurn : 0;
        String displayName = _categoryAliases[entry.value.key] ?? (entry.value.key.startsWith('cat_') ? T.get(entry.value.key) : entry.value.key);
        return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Stack(children: [
            Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: isHappy ? Colors.white : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8))),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuart,
              builder: (context, val, _) => FractionallySizedBox(widthFactor: val, child: Container(height: 30, decoration: BoxDecoration(color: colors[entry.key % colors.length], borderRadius: BorderRadius.circular(8)))),
            ),
            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentage > 0.5 ? textColorInsideBar : contrastColor)), 
              Text("${(percentage * 100).toStringAsFixed(0)}% (${entry.value.value.toStringAsFixed(2)}€)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentage > 0.5 ? textColorInsideBar : contrastColor))
            ]))),
        ]));
    }).toList());
  }

  Widget _buildStatCard(String title, double value, Color color) {
    final isHappy = widget.currentTheme == 'retro';
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: isHappy ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A2817), width: 3), boxShadow: const [BoxShadow(color: Color(0xFF3A2817), offset: Offset(4, 4), blurRadius: 0)]) : BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), 
      child: Column(children: [
        _RollingNumber(value: value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isHappy ? Colors.white : color), suffix: "€"), 
        const SizedBox(height: 5), 
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isHappy ? FontWeight.bold : FontWeight.normal, color: isHappy ? const Color(0xFF3A2817) : Colors.grey))
      ])
    );
  }

  void _openDetail(Item item, int index) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(item: item, heroTag: "item_img_${item.name}_$index", onEdit: () { Navigator.pop(context); _openEditWizard(item, index); }, onUsageAdd: () { _incrementUsage(item); setState(() {}); }, onUsageCorrect: (newCount) { _updateUsageCount(item, newCount); setState(() {}); }, onArchive: () { Navigator.pop(context); _archiveItem(item); }, onRestore: () { Navigator.pop(context); _restoreItem(item); } )));
  }

  void _openEditWizard(Item item, int index) {
     Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(item: item, availableCategories: _categories, customEmojis: _customCategoryEmojis, onCategoriesChanged: (newCats, newEmojis) { setState(() { _categories = newCats; _customCategoryEmojis = newEmojis; }); _saveData(); }, onSave: (updatedItem) { setState(() => _items[index] = updatedItem); _saveData(); }, onDelete: () { setState(() => _items.removeAt(index)); _saveData(); Navigator.pop(context); })));
  }

  void _showAddDialog() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(item: Item(name: "", price: 0, purchaseDate: DateTime.now(), estimatedUsageCount: 5, usagePeriod: 'week', category: 'cat_misc'), availableCategories: _categories, customEmojis: _customCategoryEmojis, onCategoriesChanged: (newCats, newEmojis) { setState(() { _categories = newCats; _customCategoryEmojis = newEmojis; }); _saveData(); }, onSave: (newItem) { setState(() => _items.add(newItem)); _saveData(); }, onDelete: () {})));
  }
}