import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../utils/translations.dart';

class EditItemPage extends StatefulWidget {
  final Item item; 
  final List<String> availableCategories;
  final Map<String, String> customEmojis; 
  final Function(List<String>, Map<String, String>) onCategoriesChanged; 
  final Function(Item) onSave; 
  final Function() onDelete;
  
  const EditItemPage({
    super.key, 
    required this.item, 
    required this.availableCategories, 
    required this.customEmojis,
    required this.onCategoriesChanged, 
    required this.onSave, 
    required this.onDelete
  });
  
  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> with TickerProviderStateMixin {
  
  int _currentStep = 0;
  int _totalSteps = 3;
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  final FocusNode _priceFocusNode = FocusNode();
  bool _isNameError = false;
  bool _isPriceError = false;
  bool _showCelebration = false;
  bool _isDeletingCategory = false; 
  late TextEditingController _nameController; 
  late TextEditingController _priceController;
  late TextEditingController _dateController; 
  late DateTime _purchaseDate; 
  late bool _isSubscription; 
  late String _subscriptionPeriod; 
  late bool _isConsumed;
  late int _usageCount; 
  late String _usagePeriod; 
  late int _manualClicks; 
  late String _category;
  String? _emoji;
  String? _imagePath;
  bool _isManualTracking = false;
  double _lifespanDays = 365;
  double _subUsageGoal = 4; 
  final Color _juzyColor = const Color(0xFF6BB8A7);
  final Map<String, String> _defaultCategoryEmojis = {
    "cat_living": "🛋️", "cat_tech": "📱", "cat_clothes": "👕",
    "cat_transport": "🚲", "cat_food": "🍔", "cat_insurance": "🛡️",
    "cat_entertainment": "🎮", "cat_business": "💼", "cat_health": "💊",
    "cat_misc": "📦"
  };

  String _getEmojiForCategory(String cat) {
    if (cat.startsWith('cat_')) return _defaultCategoryEmojis[cat] ?? "✨";
    return widget.customEmojis[cat] ?? "✨";
  }

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut));
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.price == 0 ? "" : widget.item.price.toString());
    _purchaseDate = widget.item.purchaseDate;
    _dateController = TextEditingController(text: "${_purchaseDate.day}.${_purchaseDate.month}.${_purchaseDate.year}");
    _isSubscription = widget.item.isSubscription;
    _subscriptionPeriod = widget.item.subscriptionPeriod;
    _isConsumed = widget.item.consumedDate != null;
    _usageCount = widget.item.estimatedUsageCount;
    _usagePeriod = widget.item.usagePeriod;
    _manualClicks = widget.item.manualClicks;
    _emoji = widget.item.emoji;
    _imagePath = widget.item.imagePath;
    _category = widget.item.category;
    if(!widget.availableCategories.contains(_category)) {
      if(widget.availableCategories.contains('cat_misc')) _category = 'cat_misc';
      else if (widget.availableCategories.isNotEmpty) _category = widget.availableCategories.first;
    }
    if (widget.item.projectedLifespanDays != null) {
      _lifespanDays = widget.item.projectedLifespanDays!.toDouble();
      if(_lifespanDays < 1) _lifespanDays = 1;
      if(_lifespanDays > 3650) _lifespanDays = 3650;
    } else {
      if (widget.item.name.isEmpty) {
        _applySmartDefaults(_category, initialSetup: true);
      }
    }
    if (_isSubscription && widget.item.targetCost != null && widget.item.price > 0) {
       _subUsageGoal = widget.item.price / widget.item.targetCost!;
       if (_subUsageGoal < 1) _subUsageGoal = 1;
    }
    if (_emoji == null && _imagePath == null) _emoji = "📦";
    _isManualTracking = _usageCount == 0;
    if (_isManualTracking) _usageCount = 1;
  }

  @override
  void dispose() { 
    _celebrationController.dispose(); 
    _nameController.dispose(); 
    _priceController.dispose(); 
    _dateController.dispose(); 
    _priceFocusNode.dispose(); 
    super.dispose(); 
  }

  void _applySmartDefaults(String category, {bool initialSetup = false}) {
    double newLifespanDays = 365;
    String newEmoji = _getEmojiForCategory(category);
    String newPeriod = 'week';
    int newCount = 1;
    if (category == "cat_tech") { newLifespanDays = 1095; newPeriod = 'day'; }
    else if (category == "cat_living") { newLifespanDays = 1825; newPeriod = 'day'; }
    else if (category == "cat_clothes") { newLifespanDays = 730; newPeriod = 'week'; }
    else if (category == "cat_transport") { newLifespanDays = 1825; newPeriod = 'day'; newCount = 2; }
    else if (category == "cat_food") { newLifespanDays = 3; newPeriod = 'day'; }
    else if (category == "cat_insurance") { newLifespanDays = 365; newPeriod = 'month'; }
    else if (category == "cat_entertainment") { newLifespanDays = 730; newPeriod = 'week'; newCount = 3; }
    else if (category == "cat_business") { newLifespanDays = 1095; newPeriod = 'day'; }
    else if (category == "cat_health") { newLifespanDays = 180; newPeriod = 'day'; }

    setState(() {
      _category = category;
      if (_imagePath == null) _emoji = newEmoji;
      if (initialSetup || widget.item.name.isEmpty) {
        _lifespanDays = newLifespanDays;
        _usagePeriod = newPeriod;
        _usageCount = newCount;
      } else if (widget.item.projectedLifespanDays == null) {
        _lifespanDays = newLifespanDays;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) { setState(() { _imagePath = pickedFile.path; _emoji = null; }); }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _juzyColor, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
        _dateController.text = "${picked.day}.${picked.month}.${picked.year}";
      });
    }
  }

  void _showMediaMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text("Bildquelle wählen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _juzyColor)), const SizedBox(height: 20),
      ListTile(leading: const Icon(Icons.emoji_emotions_outlined), title: const Text("Emoji wählen"), onTap: () { Navigator.pop(ctx); _showEmojiPicker((e) { setState(() { _emoji = e; _imagePath = null; }); }); }),
      ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text("Aus Galerie wählen"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text("Foto aufnehmen"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
      const SizedBox(height: 10)
    ])));
  }

  double _calculateTargetCost() {
    double price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    if (price == 0 || (_isManualTracking && !_isSubscription)) return 0;
    if (_isSubscription) {
        if (_subUsageGoal <= 0) return price;
        return price / _subUsageGoal; 
    }
    double weeksInLifespan = _lifespanDays / 7;
    double usesPerWeek = 0;
    switch (_usagePeriod) {
      case 'day': usesPerWeek = _usageCount * 7; break;
      case 'week': usesPerWeek = _usageCount.toDouble(); break;
      case 'month': usesPerWeek = (_usageCount * 12) / 52; break;
      case 'year': usesPerWeek = _usageCount / 52; break;
    }
    return price / (weeksInLifespan * usesPerWeek);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      setState(() { _isNameError = _nameController.text.trim().isEmpty; _isPriceError = _priceController.text.isEmpty; });
      if (_isNameError || _isPriceError) { HapticFeedback.heavyImpact(); return; }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _triggerCelebrationAndSave();
    }
  }

  void _triggerCelebrationAndSave() {
    FocusScope.of(context).unfocus();
    setState(() => _showCelebration = true);
    _celebrationController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 800), () => _saveAndExit());
  }

  void _saveAndExit() {
    double calculatedTarget = _calculateTargetCost();
    if (_isManualTracking && !_isSubscription) calculatedTarget = 0;

    widget.onSave(Item(
      id: widget.item.id,
      name: _nameController.text, 
      price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0, 
      purchaseDate: _purchaseDate, 
      estimatedUsageCount: _isManualTracking ? 0 : _usageCount, 
      usagePeriod: _usagePeriod, 
      manualClicks: _manualClicks, 
      isSubscription: _isSubscription, 
      subscriptionPeriod: _subscriptionPeriod, 
      emoji: _emoji, 
      imagePath: _imagePath,
      category: _category, 
      targetCost: calculatedTarget > 0 ? calculatedTarget : null, 
      projectedLifespanDays: (_isSubscription || _isManualTracking) ? null : _lifespanDays.toInt(),
      consumedDate: _isConsumed ? (widget.item.consumedDate ?? DateTime.now()) : null
    )); 
    if(mounted) Navigator.pop(context);
  }

  void _showEmojiPicker(Function(String) onSelect) {
    final Map<String, List<String>> emojiGroups = { 
      "Mix": ["✨", "🎸", "⚽", "🎨", "🧸", "🐶", "🐱", "📚", "🪴", "🍺", "🍷", "🍕", "🛠️", "💄", "🧶"], 
      "Tech": ["💻", "📱", "🎧", "📷", "⌚", "🔋", "🔌"], 
      "Home": ["🏠", "🛌", "🛋️", "🛁", "🧹", "🧺"], 
      "Style": ["👕", "👟", "👗", "👜", "🕶️", "💍"] 
    };
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(height: MediaQuery.of(context).size.height * 0.6, decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))), child: ListView(padding: const EdgeInsets.all(15), children: emojiGroups.entries.map((group) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(group.key.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemCount: group.value.length, itemBuilder: (context, index) => GestureDetector(onTap: () { Navigator.pop(ctx); onSelect(group.value[index]); }, child: Center(child: Text(group.value[index], style: const TextStyle(fontSize: 28)))))])).toList())));
  }

  void _addNewCategory() { 
    TextEditingController catCtrl = TextEditingController(); 
    String selectedEmoji = "✨"; 
    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(T.get('new_category')), 
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEmojiPicker((emoji) {
                        _reopenAddCategoryDialog(catCtrl.text, emoji);
                    });
                  },
                  child: Container(
                    width: 70, height: 70, alignment: Alignment.center,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle, border: Border.all(color: _juzyColor.withValues(alpha: 0.5))),
                    child: Text(selectedEmoji, style: const TextStyle(fontSize: 35)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Tippe zum Ändern", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(controller: catCtrl, autofocus: true, decoration: const InputDecoration(hintText: "Name", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 15))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))), 
              ElevatedButton(onPressed: () { 
                  if(catCtrl.text.isNotEmpty) { 
                    setState(() { 
                      widget.availableCategories.add(catCtrl.text); 
                      widget.customEmojis[catCtrl.text] = selectedEmoji;
                      _category = catCtrl.text;
                      _emoji = selectedEmoji;
                    }); 
                    widget.onCategoriesChanged(widget.availableCategories, widget.customEmojis);
                    Navigator.pop(ctx); 
                  } 
                }, child: Text(T.get('save')))
            ]
          );
        }
      )
    ); 
  }

  void _reopenAddCategoryDialog(String currentText, String emoji) {
    TextEditingController catCtrl = TextEditingController(text: currentText); 
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(T.get('new_category')), 
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _showEmojiPicker((newEmoji) => _reopenAddCategoryDialog(catCtrl.text, newEmoji));
              },
              child: Container(
                width: 70, height: 70, alignment: Alignment.center,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle, border: Border.all(color: _juzyColor.withValues(alpha: 0.5))),
                child: Text(emoji, style: const TextStyle(fontSize: 35)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: catCtrl, autofocus: true, decoration: const InputDecoration(hintText: "Name", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 15))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))), 
          ElevatedButton(onPressed: () { 
            if(catCtrl.text.isNotEmpty) { 
              setState(() { 
                widget.availableCategories.add(catCtrl.text); 
                widget.customEmojis[catCtrl.text] = emoji;
                _category = catCtrl.text;
                _emoji = emoji;
              }); 
              widget.onCategoriesChanged(widget.availableCategories, widget.customEmojis);
              Navigator.pop(ctx); 
            } 
          }, child: Text(T.get('save')))
        ]
      )
    );
  }

  void _deleteCategory(String cat) { 
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(T.get('delete_category_confirm')), 
      content: Text("$cat ${_getEmojiForCategory(cat)}"), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))), 
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () { 
          setState(() { 
            widget.availableCategories.remove(cat); 
            widget.customEmojis.remove(cat); 
            if(_category == cat) _category = widget.availableCategories.first; 
          }); 
          widget.onCategoriesChanged(widget.availableCategories, widget.customEmojis); 
          Navigator.pop(ctx); 
        }, child: Text(T.get('delete')))
      ]
    )); 
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color inputFillColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    Color inputBorderColor = isDarkMode ? Colors.transparent : Colors.grey.withValues(alpha: 0.2);
    
    _totalSteps = 3;
    bool isLastStep = _currentStep == _totalSteps - 1;

    return Stack(children: [
      Scaffold(body: SafeArea(child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Row(children: [
              _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => setState(() => _currentStep--)) : const SizedBox(width: 48),
              Expanded(child: Center(child: Text(_currentStep == 0 ? T.get('step_identity') : _currentStep == 1 ? T.get('step_usage') : T.get('step_forecast'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)))),
              IconButton(icon: const Icon(Icons.close, size: 22), onPressed: () => Navigator.pop(context)),
            ])),
            LinearProgressIndicator(value: (_currentStep + 1) / _totalSteps, minHeight: 2, valueColor: AlwaysStoppedAnimation<Color>(_juzyColor)),
            Expanded(child: IndexedStack(index: _currentStep, children: [_buildStep1(colors, inputFillColor, inputBorderColor), _buildStep2(colors), _buildStep3(colors)])),
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              if (widget.item.name.isNotEmpty) IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red)),
              Expanded(child: ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _juzyColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(isLastStep ? "${T.get('save')} ✨" : T.get('next'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
            ])),
          ]),
        ),
      ))),
      if (_showCelebration) Positioned.fill(child: IgnorePointer(child: Container(color: Colors.black.withValues(alpha: 0.1), child: Center(child: ScaleTransition(scale: _scaleAnimation, child: _imagePath != null ? Container(width: 150, height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), image: DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover))) : Text(_emoji ?? "📦", style: const TextStyle(fontSize: 150, decoration: TextDecoration.none)))))))
    ]);
  }

  Widget _buildStep1(ColorScheme colors, Color fillColor, Color borderColor) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      GestureDetector(onTap: _showMediaMenu, child: Stack(alignment: Alignment.bottomRight, children: [Container(height: 120, width: 120, alignment: Alignment.center, decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(30), border: Border.all(color: _juzyColor.withValues(alpha: 0.5), width: 2), image: _imagePath != null ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover) : null), child: _imagePath == null ? Text(_emoji ?? "📦", style: const TextStyle(fontSize: 50)) : null), Container(margin: const EdgeInsets.all(5), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]), child: Icon(Icons.edit, size: 14, color: _juzyColor))])), 
      const SizedBox(height: 20), 
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(T.get('label_category'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), 
        IconButton(onPressed: () => setState(() => _isDeletingCategory = !_isDeletingCategory), icon: Icon(_isDeletingCategory ? Icons.check_circle : Icons.edit, color: _isDeletingCategory ? _juzyColor : Colors.grey, size: 20))
      ]), 
      const SizedBox(height: 10), 
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...widget.availableCategories.map((cat) { 
          String displayName = cat.startsWith('cat_') ? T.get(cat) : cat; 
          String emoji = _getEmojiForCategory(cat);
          bool isSelected = _category == cat; 
          bool isStandard = cat.startsWith('cat_'); 
          return GestureDetector(onTap: () { if(_isDeletingCategory) { if(!isStandard) _deleteCategory(cat); } else { _applySmartDefaults(cat); } }, child: Chip(label: Text(displayName), avatar: _isDeletingCategory ? (isStandard ? null : const Icon(Icons.remove_circle, color: Colors.white, size: 18)) : Text(emoji), backgroundColor: _isDeletingCategory ? (isStandard ? Colors.grey.withValues(alpha: 0.1) : Colors.red) : (isSelected ? _juzyColor : colors.surfaceContainerHighest), labelStyle: TextStyle(color: _isDeletingCategory ? (isStandard ? Colors.grey : Colors.white) : (isSelected ? Colors.white : colors.onSurface), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))); 
        }), 
        if(!_isDeletingCategory) ActionChip(label: const Icon(Icons.add, size: 18), onPressed: _addNewCategory, backgroundColor: colors.surface, side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)))
      ]), 
      const SizedBox(height: 40), 
      TextField(controller: _nameController, textCapitalization: TextCapitalization.sentences, textInputAction: TextInputAction.next, onSubmitted: (_) => FocusScope.of(context).requestFocus(_priceFocusNode), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: T.get('label_name'), filled: true, fillColor: _isNameError ? Colors.red.withValues(alpha: 0.1) : fillColor, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _juzyColor, width: 2)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20))), 
      const SizedBox(height: 20), 
      TextField(controller: _priceController, focusNode: _priceFocusNode, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1), textAlign: TextAlign.center, decoration: InputDecoration(labelText: T.get('label_price'), suffixText: T.currency, filled: true, fillColor: _isPriceError ? Colors.red.withValues(alpha: 0.1) : fillColor, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _juzyColor, width: 2)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20))), 
      const SizedBox(height: 20), 
      TextField(controller: _dateController, readOnly: true, onTap: _pickDate, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: T.get('label_date'), prefixIcon: Icon(Icons.calendar_today, color: _juzyColor), filled: true, fillColor: fillColor, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _juzyColor, width: 2)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20)))
    ]));
  }

  Widget _buildStep2(ColorScheme colors) {
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _card(T.get('type_purchase'), Icons.shopping_bag, !_isSubscription, () => setState(() => _isSubscription = false))), const SizedBox(width: 15), Expanded(child: _card(T.get('type_sub'), Icons.event_repeat, _isSubscription, () => setState(() => _isSubscription = true)))]),
      if (_isSubscription) ...[
        const SizedBox(height: 30), Text(T.get('pay_interval'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        Row(children: [Expanded(child: ChoiceChip(label: Center(child: Text(T.get('monthly'))), selected: _subscriptionPeriod == 'month', onSelected: (s) => setState(() => _subscriptionPeriod = 'month'), selectedColor: _juzyColor, labelStyle: TextStyle(color: _subscriptionPeriod == 'month' ? Colors.white : colors.onSurface))), const SizedBox(width: 10), Expanded(child: ChoiceChip(label: Center(child: Text(T.get('yearly'))), selected: _subscriptionPeriod == 'year', onSelected: (s) => setState(() => _subscriptionPeriod = 'year'), selectedColor: _juzyColor, labelStyle: TextStyle(color: _subscriptionPeriod == 'year' ? Colors.white : colors.onSurface)))]),
        const SizedBox(height: 20),
        Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Row(children: [const Icon(Icons.info_outline, color: Colors.blue, size: 20), const SizedBox(width: 10), Expanded(child: Text(T.get('sub_calc_info'), style: const TextStyle(fontSize: 13, color: Colors.blueGrey)))])),
      ],
      const SizedBox(height: 30),
      if (!_isSubscription) ...[
        Text(T.get('tracking_method'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        Row(children: [Expanded(child: ChoiceChip(label: Center(child: Text(T.get('tracking_estimation'))), selected: !_isManualTracking, onSelected: (s) => setState(() => _isManualTracking = false), selectedColor: _juzyColor, labelStyle: TextStyle(color: !_isManualTracking ? Colors.white : colors.onSurface))), const SizedBox(width: 10), Expanded(child: ChoiceChip(label: Center(child: Text(T.get('tracking_manual'))), selected: _isManualTracking, onSelected: (s) => setState(() => _isManualTracking = true), selectedColor: _juzyColor, labelStyle: TextStyle(color: _isManualTracking ? Colors.white : colors.onSurface)))]),
        const SizedBox(height: 30),
        if (_isManualTracking) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(15)), child: Column(children: [
          Text(T.get('manual_info'), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 20),
          Text(T.get('label_manual_usages'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setState(() { if(_manualClicks > 0) _manualClicks--; }), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("$_manualClicks", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold))),
            IconButton(onPressed: () => setState(() => _manualClicks++), icon: Icon(Icons.add_circle_outline, color: _juzyColor)),
          ])
        ]))
        else ...[
          Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _juzyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(Icons.info_outline, color: _juzyColor, size: 20), const SizedBox(width: 10), Expanded(child: Text(T.get('estimation_info'), style: const TextStyle(fontSize: 13)))])),
          Center(child: Text(T.get('usage_approx'), style: TextStyle(fontWeight: FontWeight.bold, color: _juzyColor))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: () => setState(() { if(_usageCount > 1) _usageCount--; }), icon: const Icon(Icons.remove)), Text("$_usageCount", style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold)), IconButton(onPressed: () => setState(() => _usageCount++), icon: const Icon(Icons.add))]),
          DropdownButton<String>(value: _usagePeriod, isExpanded: true, items: ['day', 'week', 'month', 'year'].map((v) => DropdownMenuItem(value: v, child: Center(child: Text("${T.get('times_per')} ${T.get('per_$v')}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))))).toList(), onChanged: (v) => setState(() => _usagePeriod = v!))
        ]
      ]
    ]));
  }

  Widget _buildStep3(ColorScheme colors) {
    if (_isManualTracking && !_isSubscription) return const SizedBox.shrink(); 
    if (_isSubscription) {
      return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        Text(T.get('sub_goal_hint'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text("${_subUsageGoal.toInt()}x ${T.get('per_month')}", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        Slider(value: _subUsageGoal, min: 1, max: 30, activeColor: _juzyColor, onChanged: (v) => setState(() => _subUsageGoal = v)),
        const Spacer(),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _juzyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _juzyColor)), child: Column(children: [Text(T.get('target_value'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text("${_calculateTargetCost().toStringAsFixed(2)} ${T.currency}", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: _juzyColor)), Text(T.get('per_usage'), style: const TextStyle(fontSize: 13))])),
        const SizedBox(height: 40),
      ]));
    }
    DateTime predictedEndDate = DateTime.now().add(Duration(days: _lifespanDays.toInt()));
    String dateString = "${predictedEndDate.day}.${predictedEndDate.month}.${predictedEndDate.year}";
    String displayTime = "";
    if (_lifespanDays < 30) { displayTime = "${_lifespanDays.toInt()} ${T.get('days')}"; } 
    else if (_lifespanDays < 365) { displayTime = "${(_lifespanDays/30).toStringAsFixed(1)} ${T.get('months')}"; } 
    else { displayTime = "${(_lifespanDays/365).toStringAsFixed(1)} ${T.get('years')}"; }

    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      Text(T.get('wish_lifespan'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      Padding(padding: const EdgeInsets.only(top: 5, bottom: 20), child: Text(T.get('lifespan_hint'), style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha: 0.8), fontStyle: FontStyle.italic))),
      Text(displayTime, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
      Slider(value: _lifespanDays, min: 1, max: 3650, activeColor: _juzyColor, onChanged: (v) => setState(() => _lifespanDays = v)),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _juzyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text("${T.get('calc_date')} $dateString", style: TextStyle(color: _juzyColor, fontWeight: FontWeight.bold))),
      const Spacer(),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _juzyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _juzyColor)), child: Column(children: [Text(T.get('target_value'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text("${_calculateTargetCost().toStringAsFixed(2)} ${T.currency}", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: _juzyColor)), Text(T.get('per_usage'), style: const TextStyle(fontSize: 13))])),
      const SizedBox(height: 40),
    ]));
  }

  Widget _card(String t, IconData i, bool s, VoidCallback o) => GestureDetector(onTap: o, child: Container(height: 100, decoration: BoxDecoration(color: s ? _juzyColor.withValues(alpha: 0.2) : Colors.transparent, border: Border.all(color: s ? _juzyColor : Colors.grey.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: s ? _juzyColor : Colors.grey), Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: s ? _juzyColor : Colors.grey))])));
}