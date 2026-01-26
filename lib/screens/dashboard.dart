import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/item.dart';
import 'settings_page.dart';
import 'edit_item_page.dart';
import 'item_detail_page.dart';
import '../utils/translations.dart'; 

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
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstRun());
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('first_run') ?? true;
    if (isFirstRun) {
      _showOnboardingDialog(prefs);
    }
  }

  void _showOnboardingDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // FIX: Explizite Farben für Dark/Light Mode, damit Kontrast immer stimmt
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
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      prefs.setBool('first_run', false);
                      Navigator.pop(context);
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

  void _loadDemoData() { _loadData(); }

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

  void _incrementUsage(Item item) {
    HapticFeedback.mediumImpact();
    setState(() { item.manualClicks++; });
    _saveData();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${item.name}: ${T.get('usage_added')}"), 
      duration: const Duration(milliseconds: 1500), 
      behavior: SnackBarBehavior.floating 
    ));
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  void _updateUsageCount(Item item, int newCount) {
    setState(() { item.manualClicks = newCount; });
    _saveData();
  }

  void _archiveItem(Item item) {
    HapticFeedback.heavyImpact();
    setState(() { item.consumedDate = DateTime.now(); });
    _saveData();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${item.name} ${item.isSubscription ? T.get('sub_ended') : T.get('item_archived')}"), 
      duration: const Duration(milliseconds: 2500),
      behavior: SnackBarBehavior.floating, 
      action: SnackBarAction(
        label: T.get('undo'), 
        textColor: widget.currentTheme == 'retro' ? const Color(0xFFD4522A) : _juzyColor,
        onPressed: () { 
          setState(() { item.consumedDate = null; }); 
          _saveData(); 
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      )
    ));
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) { try { ScaffoldMessenger.of(context).hideCurrentSnackBar(); } catch(e){} }
    });
  }

  void _restoreItem(Item item) {
    HapticFeedback.mediumImpact();
    setState(() { item.consumedDate = null; });
    _saveData();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(T.get('item_restored')), 
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating
    ));
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  List<Item> _getFilteredItems(List<Item> inputList) {
    if (_searchQuery.isEmpty) return inputList;
    return inputList.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()) || i.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPurchases = _items.where((i) => !i.isSubscription && i.isActive).toList();
    final allSubs = _items.where((i) => i.isSubscription && i.isActive).toList();
    
    final purchases = _getFilteredItems(allPurchases);
    final subscriptions = _getFilteredItems(allSubs);

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
        // FIX: Besserer Titel-Kontrast. Retro = Dunkelbraun (gut auf Beige). Standard = Gradient.
        title: _isSearching 
          ? TextField(controller: _searchController, autofocus: true, decoration: InputDecoration(hintText: T.get('search'), border: InputBorder.none), onChanged: (val) => setState(() => _searchQuery = val))
          : (isHappy 
              ? Text(T.get('app_name'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3A2817), letterSpacing: 3.0))
              : ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFDC830), Color(0xFFF37335)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds), child: Text(T.get('app_name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0)))
            ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () { HapticFeedback.selectionClick(); setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchQuery = ""; _searchController.clear(); } }); }),
          if (!_isSearching) IconButton(icon: const Icon(Icons.settings), onPressed: () { HapticFeedback.selectionClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(onThemeChanged: widget.onThemeChanged, currentTheme: widget.currentTheme, onLoadDemoData: _loadDemoData, onDeleteAllData: _deleteAllData, onLanguageChanged: widget.onLanguageChanged))).then((_) => _loadData()); })
        ],
      ),
      body: Container(
        decoration: happyBackground,
        child: SafeArea(
          child: Column(
            children: [
              if (!_isSearching) Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24), child: Column(children: [Text(T.get('daily_cost'), style: TextStyle(color: isHappy ? const Color(0xFF3A2817) : colorScheme.primary, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, fontStyle: isHappy ? FontStyle.italic : FontStyle.normal)), const SizedBox(height: 2), Text("${dailyBurn.toStringAsFixed(2)}€", style: dailyBurnTextStyle)])),
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
              
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(purchases, T.get('empty_items'), false, false), 
                  _buildCategoryList(subscriptions, T.get('empty_subs'), _showDailyRates, true), 
                  _buildStatisticsPage()
                ]
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: fabColor, 
        shape: isHappy ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3A2817), width: 2)) : null, 
        elevation: isHappy ? 6 : 6, 
        onPressed: _showAddDialog, 
        icon: Icon(Icons.add, color: isHappy ? Colors.white : colorScheme.onPrimary), 
        label: Text(T.get('new_item'), style: TextStyle(color: isHappy ? Colors.white : colorScheme.onPrimary, fontWeight: FontWeight.bold))
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 15), Text(text, style: TextStyle(color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 50)]));
  }

  Widget _buildCategoryList(List<Item> items, String emptyText, bool applyDailyRate, bool hasToggle) {
    if (items.isEmpty) return _buildEmptyState(emptyText);

    double totalCostPerUse = 0;
    int count = 0;
    for (var i in _items.where((x) => x.isActive)) { totalCostPerUse += i.costPerUse; count++; }
    double avgCost = count > 0 ? totalCostPerUse / count : 0;

    Map<String, List<Item>> grouped = {};
    for (var item in items) { if (!grouped.containsKey(item.category)) grouped[item.category] = []; grouped[item.category]!.add(item); }
    List<String> keys = grouped.keys.toList()..sort();

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: hasToggle ? 40 : 10),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            String catKey = keys[index];
            String displayName = _categoryAliases[catKey] ?? (catKey.startsWith('cat_') ? T.get(catKey) : catKey);
            List<Item> catItems = grouped[catKey]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(left: 8, bottom: 4, top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(displayName.toUpperCase(), style: TextStyle(color: widget.currentTheme == 'retro' ? const Color(0xFFD4522A) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(Icons.edit, size: 14, color: Colors.grey.withOpacity(0.5)), onPressed: () => _renameCategory(catKey))])),
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  clipBehavior: Clip.hardEdge, 
                  decoration: widget.currentTheme == 'retro' 
                    ? BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: const Color(0xFF6BB8A7), width: 3), 
                        boxShadow: const [BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4), blurRadius: 0)]
                      ) 
                    : BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black12 : Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.08 : 0.2), 
                            blurRadius: 10, 
                            offset: const Offset(0, 4)
                          )
                        ]
                      ),
                  child: Column(children: catItems.map((item) { final realIndex = _items.indexOf(item); return _buildListItem(item, realIndex, item == catItems.last, avgCost, applyDailyRate); }).toList()),
                ),
              ],
            );
          },
        ),

        if (hasToggle)
          Positioned(
            top: 10,
            right: 20,
            child: GestureDetector(
              onTap: () {
                 HapticFeedback.selectionClick();
                 setState(() => _showDailyRates = !_showDailyRates);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _juzyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _juzyColor.withOpacity(0.5))
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 14, color: _juzyColor),
                    const SizedBox(width: 6),
                    Text(
                      _showDailyRates ? T.get('view_daily') : T.get('view_usage'), 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _juzyColor)
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListItem(Item item, int realIndex, bool isLast, double avgCost, bool applyDailyRate) {
    final isHappy = widget.currentTheme == 'retro';
    Color textColor = isHappy ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    Color? statusColor;
    if (avgCost > 0) {
      if (item.costPerUse > avgCost * 2.0) statusColor = Colors.red.withOpacity(isHappy ? 0.1 : 0.2);
      else if (item.costPerUse < avgCost * 0.5) statusColor = Colors.green.withOpacity(isHappy ? 0.1 : 0.2);
      if (item.isSubscription && item.totalUsesCalculated < 2) statusColor = Colors.deepOrange.withOpacity(0.2);
    }
    double? progress;
    bool reachedGoal = false;
    if (item.targetCost != null && item.targetCost! > 0 && !item.isSubscription) {
      double neededUses = item.price / item.targetCost!;
      if (neededUses < 1) neededUses = 1;
      progress = item.totalUsesCalculated / neededUses;
      if (progress >= 1.0) reachedGoal = true;
    }

    String priceDisplay = "";
    String unitDisplay = "";
    
    if (applyDailyRate) {
      priceDisplay = "${item.pricePerDay.toStringAsFixed(2)}€";
      unitDisplay = "/ ${T.get('per_day')}";
    } else {
      if (item.isSubscription) {
        priceDisplay = "${item.price.toStringAsFixed(2)}€";
        unitDisplay = "/ ${item.subscriptionPeriod == 'year' ? T.get('years') : T.get('months')}";
      } else {
        priceDisplay = "${item.costPerUse.toStringAsFixed(2)}€";
        unitDisplay = T.get('per_usage');
      }
    }

    return Container(
      color: statusColor,
      child: Column(children: [
        ListTile(
          onTap: () => _openDetail(item, realIndex),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // FIX: Mehr Padding vertikal
          leading: Hero(
            tag: "item_img_${item.name}_$realIndex",
            child: Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isHappy ? const Color(0xFFF4D98D) : Colors.grey.withOpacity(0.1), border: isHappy ? Border.all(color: const Color(0xFF3A2817), width: 1.5) : null, image: item.imagePath != null ? DecorationImage(image: FileImage(File(item.imagePath!)), fit: BoxFit.cover) : null), child: item.imagePath == null ? Material(color: Colors.transparent, child: Text(item.emoji ?? "📦", style: const TextStyle(fontSize: 26))) : null),
          ),
          title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // FIX: Flexible erlaubt Zeilenumbruch bei langen Wörtern
            Expanded(child: Row(children: [Flexible(child: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))), if (reachedGoal) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.emoji_events, size: 16, color: Colors.amber))])),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                item.isSubscription 
                    ? (item.subscriptionPeriod == 'year' ? T.get('yearly') : T.get('monthly')) 
                    : "${item.totalUsesCalculated.toInt()} ${T.get('times_used')}", 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isHappy ? Colors.grey[700] : Colors.grey)
              ), 
              if (progress != null && !reachedGoal) Padding(padding: const EdgeInsets.only(top: 6, right: 20), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.withOpacity(0.2), color: isHappy ? const Color(0xFF6BB8A7) : Colors.blueAccent, minHeight: 6, borderRadius: BorderRadius.circular(3)))
            ]),
          ),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(priceDisplay, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isHappy && reachedGoal ? const Color(0xFF6BB8A7) : textColor)), 
            Text((item.targetCost != null && item.targetCost! > 0 && !applyDailyRate) ? "${T.get('goal')}: ${item.targetCost!.toStringAsFixed(2)}€" : unitDisplay, style: TextStyle(fontSize: 10, color: isHappy ? Colors.grey[700] : Colors.grey))
          ]),
        ),
        if (!isLast) Divider(height: 1, indent: 80, endIndent: 20, color: isHappy ? const Color(0xFF6BB8A7).withOpacity(0.3) : Colors.white10),
      ]),
    );
  }

  Widget _buildBarChart(Map<String, double> categoryCosts, double totalBurn) {
    var sortedEntries = categoryCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final isHappy = widget.currentTheme == 'retro';
    final colors = isHappy ? [const Color(0xFFD4522A), const Color(0xFFF2B84B), const Color(0xFF6BB8A7), const Color(0xFF8DC9BB), const Color(0xFFC44536)] : [const Color(0xFF64B5F6), const Color(0xFFBA68C8), const Color(0xFFFFB74D), const Color(0xFF81C784), const Color(0xFFE57373)];
    
    final Color contrastColor = isHappy ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;

    return Column(
      children: sortedEntries.asMap().entries.map((entry) {
        int index = entry.key;
        String cat = entry.value.key;
        double value = entry.value.value;
        double percentage = totalBurn > 0 ? value / totalBurn : 0;
        String displayName = _categoryAliases[cat] ?? (cat.startsWith('cat_') ? T.get(cat) : cat);
        Color barColor = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // FIX: Mehr Platz
          child: Stack(
            children: [
              Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: isHappy ? Colors.white : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: isHappy ? Border.all(color: Colors.black12) : null)),
              FractionallySizedBox(widthFactor: percentage, child: Container(height: 30, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(8)))),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentage > 0.5 ? Colors.white : contrastColor)),
                      Text("${(percentage * 100).toStringAsFixed(0)}% (${value.toStringAsFixed(2)}€)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentage > 0.5 ? Colors.white : contrastColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isHappy = widget.currentTheme == 'retro';
    Color textColor = isHappy ? const Color(0xFF5D4037) : colorScheme.onSurface;

    if (activeItems.isEmpty && historyItems.isEmpty) return _buildEmptyState(T.get('empty_stats'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (totalBurn > 0) ...[
            Text(T.get('cost_dist'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            _buildBarChart(categoryCosts, totalBurn),
          ],
          
          const SizedBox(height: 30),
          Text(T.get('daily_usage_sum'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 15),
          Row(children: [Expanded(child: _buildStatCard(T.get('daily_item'), "${burnItems.toStringAsFixed(2)}€", isHappy ? const Color(0xFF6BB8A7) : colorScheme.secondary)), const SizedBox(width: 12), Expanded(child: _buildStatCard(T.get('daily_subs'), "${burnSubs.toStringAsFixed(2)}€", isHappy ? const Color(0xFFF2B84B) : colorScheme.primary))]),
          
          const SizedBox(height: 30),
          Text(T.get('history'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 15),
          if (historyItems.isEmpty) Center(child: Text(T.get('empty_stats'), style: TextStyle(color: textColor))),
          
          ...historyItems.map((item) { 
            final realIndex = _items.indexOf(item); 
            
            bool isSuccess = false;
            String statusText = "";
            bool moneySuccess = false;
            if (item.targetCost != null && item.targetCost! > 0) {
               moneySuccess = item.costPerUse <= item.targetCost!;
            }

            if (item.isSubscription) {
               if (moneySuccess) { isSuccess = true; statusText = T.get('verdict_success'); } else { isSuccess = false; statusText = T.get('verdict_fail'); }
            } else if (item.projectedLifespanDays != null) {
              int actualDays = item.consumedDate!.difference(item.purchaseDate).inDays;
              int plannedDays = item.projectedLifespanDays!;
              if (actualDays >= plannedDays) { isSuccess = true; statusText = "+${actualDays - plannedDays}d ${T.get('lifespan_longer')}"; } 
              else { if (moneySuccess) { isSuccess = true; statusText = "-${plannedDays - actualDays}d ${T.get('lifespan_shorter_good')}"; } else { isSuccess = false; statusText = "-${plannedDays - actualDays}d ${T.get('lifespan_shorter_bad')}"; } }
            } else { isSuccess = true; }

            Color statusColor = isSuccess ? Colors.green : Colors.red;
            Color cardBg = isHappy ? (isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)) : (isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1));
            Color borderColor = isHappy ? statusColor : Colors.transparent;

            return GestureDetector(
              onTap: () => _openDetail(item, realIndex), 
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), 
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                clipBehavior: Clip.hardEdge, 
                decoration: BoxDecoration(
                  color: cardBg, 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: borderColor, width: isHappy ? 2 : 0)
                ), 
                child: Row(
                  children: [
                    Text(item.emoji ?? "🏁", style: const TextStyle(fontSize: 26)), 
                    const SizedBox(width: 15), 
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), 
                          Text("${item.totalUsesCalculated.toInt()} ${T.get('times_used')}", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8)))
                        ]
                      )
                    ), 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end, 
                      children: [
                        Row(children: [
                          Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                          const SizedBox(width: 4),
                          Icon(isSuccess ? Icons.check_circle : Icons.warning_amber_rounded, color: statusColor, size: 16)
                        ]),
                        Text("${item.costPerUse.toStringAsFixed(2)}€", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)), 
                      ]
                    )
                  ]
                )
              )
            ); 
          }),
          const SizedBox(height: 80),
        ]),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final isHappy = widget.currentTheme == 'retro';
    return Container(padding: const EdgeInsets.all(20), clipBehavior: Clip.hardEdge, decoration: isHappy ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3A2817), width: 3), boxShadow: const [BoxShadow(color: Color(0xFF3A2817), offset: Offset(4, 4), blurRadius: 0)]) : BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isHappy ? Colors.white : color)), const SizedBox(height: 5), Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isHappy ? FontWeight.bold : FontWeight.normal, color: isHappy ? const Color(0xFF3A2817) : Colors.grey))]));
  }

  void _openDetail(Item item, int index) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(
      item: item, 
      heroTag: "item_img_${item.name}_$index",
      onEdit: () { Navigator.pop(context); _openEditWizard(item, index); },
      onUsageAdd: () { _incrementUsage(item); setState(() {}); },
      onUsageCorrect: (newCount) { _updateUsageCount(item, newCount); setState(() {}); },
      onArchive: () { Navigator.pop(context); _archiveItem(item); }, 
      onRestore: () { Navigator.pop(context); _restoreItem(item); } 
    )));
  }

  void _openEditWizard(Item item, int index) {
     Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(
       item: item, 
       availableCategories: _categories,
       customEmojis: _customCategoryEmojis, 
       onCategoriesChanged: (newCats, newEmojis) { 
         setState(() {
           _categories = newCats;
           _customCategoryEmojis = newEmojis;
         }); 
         _saveData(); 
       },
       onSave: (updatedItem) { setState(() => _items[index] = updatedItem); _saveData(); }, 
       onDelete: () { setState(() => _items.removeAt(index)); _saveData(); Navigator.pop(context); }
    )));
  }

  void _showAddDialog() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemPage(
      item: Item(name: "", price: 0, purchaseDate: DateTime.now(), estimatedUsageCount: 5, usagePeriod: 'week', category: 'cat_misc'), 
      availableCategories: _categories,
      customEmojis: _customCategoryEmojis,
      onCategoriesChanged: (newCats, newEmojis) {
         setState(() {
           _categories = newCats;
           _customCategoryEmojis = newEmojis;
         }); 
         _saveData(); 
       },
       onSave: (newItem) { setState(() => _items.add(newItem)); _saveData(); }, 
       onDelete: () {}
    )));
  }
}