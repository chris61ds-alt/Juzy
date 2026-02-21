import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'; 
import '../models/item.dart';
import '../utils/translations.dart';
import '../widgets/animations.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final String heroTag;
  final VoidCallback onEdit;
  final VoidCallback onUsageAdd;
  final Function(int) onUsageCorrect;
  final VoidCallback onRestore;
  final VoidCallback onArchive;

  const ItemDetailPage({ super.key, required this.item, required this.heroTag, required this.onEdit, required this.onUsageAdd, required this.onUsageCorrect, required this.onRestore, required this.onArchive });
  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> with TickerProviderStateMixin {
  late AnimationController _controller, _bumpController;
  late Animation<double> _scaleAnimation, _bumpUpAnimation, _bumpDownAnimation;
  String _chartView = 'month'; 
  bool _isLocaleReady = false; 

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(T.code, null).then((_) {
      if (mounted) setState(() => _isLocaleReady = true);
    });

    _controller = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _bumpController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _bumpUpAnimation = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50), TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50)]).animate(CurvedAnimation(parent: _bumpController, curve: Curves.easeInOut));
    _bumpDownAnimation = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 50), TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 50)]).animate(CurvedAnimation(parent: _bumpController, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); _bumpController.dispose(); super.dispose(); }
  
  void _handleUsageAdd() { _bumpController.forward(from: 0.0); setState(() { widget.item.usageHistory.add(DateTime.now().millisecondsSinceEpoch); }); Future.microtask(() => widget.onUsageAdd()); }
  void _handleCorrection(int delta) { if (widget.item.manualClicks + delta >= 0) { if (delta < 0 && widget.item.usageHistory.isNotEmpty) { widget.item.usageHistory.removeLast(); } widget.onUsageCorrect(widget.item.manualClicks + delta); setState(() {}); } }

  String _getLastUsedText() {
    final lastUsed = widget.item.lastUsedDate;
    if (lastUsed == null) return T.get('never_used');
    final diff = DateTime.now().difference(lastUsed);
    if (diff.inSeconds < 60) return T.get('just_now'); 
    if (diff.inDays == 0) return T.get('today'); 
    if (diff.inDays == 1) return T.get('yesterday'); 
    if (diff.inDays < 7) return "${T.get('days_ago')} ${diff.inDays} ${T.get('days')}";
    return DateFormat('dd.MM.yyyy').format(lastUsed);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isRetro = Theme.of(context).scaffoldBackgroundColor == const Color(0xFFF9F3E6);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainBgColor = isRetro ? const Color(0xFFF9F3E6) : (isDark ? const Color(0xFF121212) : Colors.white);
    
    Color headerBgColor = isRetro ? const Color(0xFFE8DFC8) : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));
    if (widget.item.consumedDate != null) headerBgColor = Colors.grey[300]!;

    const Color maturiColor = Color(0xFF6BB8A7);
    final bool isArchived = widget.item.consumedDate != null;

    double? progress;
    if (widget.item.targetCost != null && widget.item.targetCost! > 0 && !widget.item.isSubscription) { 
      double neededUses = widget.item.price / widget.item.targetCost!; 
      if (neededUses < 1) neededUses = 1; 
      progress = widget.item.totalUsesCalculated / neededUses; 
      if (progress > 1) progress = 1; 
    }
    
    double usageVal = widget.item.isSubscription ? widget.item.manualClicks.toDouble() : widget.item.totalUsesCalculated;
    final priceColor = isRetro ? const Color(0xFF3A2817) : (isDark ? Colors.white : Colors.black87);
    final appBarIconColor = !isDark && !isRetro ? Colors.black87 : colorScheme.onSurface;

    return Scaffold(
      backgroundColor: mainBgColor,
      body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 200.0, pinned: true, backgroundColor: mainBgColor, elevation: 0,
            leading: IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: mainBgColor.withValues(alpha: 0.5), shape: BoxShape.circle), child: Icon(Icons.arrow_back, color: appBarIconColor)), onPressed: () => Navigator.pop(context)),
            actions: [IconButton(onPressed: widget.onEdit, icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: mainBgColor.withValues(alpha: 0.5), shape: BoxShape.circle), child: Icon(Icons.edit, color: appBarIconColor))), const SizedBox(width: 8)],
            flexibleSpace: FlexibleSpaceBar(background: ScaleTransition(scale: _scaleAnimation, child: Container(width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: headerBgColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)), image: widget.item.imagePath != null ? (kIsWeb ? null : DecorationImage(image: FileImage(File(widget.item.imagePath!)), fit: BoxFit.cover)) : null), child: widget.item.imagePath == null ? Text(widget.item.emoji ?? "📦", style: const TextStyle(fontSize: 80)) : (kIsWeb ? const SizedBox.shrink() : Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)]))))))),
          ),
          SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
                      const SizedBox(height: 20),
                      StaggeredSlide(delay: 300, child: Text(widget.item.name.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 22, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Colors.grey))),
                      const SizedBox(height: 5),
                      StaggeredSlide(delay: 400, child: FittedBox(fit: BoxFit.scaleDown, child: RollingNumber(value: widget.item.price, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: priceColor), suffix: " ${T.currency}"))),
                      const SizedBox(height: 10),
                      StaggeredSlide(delay: 500, child: Column(children: [Text("${T.get('bought_on')} ${widget.item.purchaseDate.day}.${widget.item.purchaseDate.month}.${widget.item.purchaseDate.year}", style: TextStyle(color: Colors.grey.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold)), if (isArchived) Padding(padding: const EdgeInsets.only(top: 4), child: Text("${T.get('item_archived')}: ${widget.item.consumedDate!.day}.${widget.item.consumedDate!.month}.${widget.item.consumedDate!.year}", style: TextStyle(color: isRetro ? const Color(0xFFD4522A) : colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold)))])),
                      const SizedBox(height: 30),
                      if (isArchived) _buildArchivedAnalysis(context, isRetro)
                      else ...[
                          if (progress != null) StaggeredSlide(delay: 600, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${T.get('goal')}: ${widget.item.targetCost!.toStringAsFixed(2)} ${T.currency}/${T.get('per_usage')}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)), Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: progress >= 1 ? Colors.amber : maturiColor))]), const SizedBox(height: 8), TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: const Duration(milliseconds: 1500), curve: Curves.easeOutExpo, builder: (context, val, _) => ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: val, minHeight: 12, backgroundColor: Colors.grey.withValues(alpha: 0.1), color: (val >= 1 ? Colors.amber : maturiColor)))), const SizedBox(height: 25)]))),
                          StaggeredSlide(delay: 700, child: Row(children: [
                            Expanded(child: _buildBigStat(context: context, label: T.get('cost_per_use'), value: widget.item.costPerUse, color: colorScheme.primary, isRetro: isRetro, suffix: " ${T.currency}", animation: _bumpDownAnimation)), 
                            const SizedBox(width: 15), 
                            Expanded(child: _buildBigStat(context: context, label: T.get('usages'), value: usageVal, color: colorScheme.secondary, isRetro: isRetro, suffix: "", animation: _bumpUpAnimation, decimals: 0))
                          ])),
                          if (!widget.item.isSubscription && widget.item.lastUsedDate != null) Padding(padding: const EdgeInsets.only(top: 15), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 14, color: Colors.grey.withValues(alpha: 0.6)), const SizedBox(width: 5), Text("${T.get('last_used')} ${_getLastUsedText()}", style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.8), fontStyle: FontStyle.italic))])),
                          const SizedBox(height: 35),
                          StaggeredSlide(delay: 800, child: Column(children: [Align(alignment: Alignment.centerLeft, child: Text(T.get('view_usage'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 1))), const SizedBox(height: 15), SizedBox(width: double.infinity, child: Row(children: [Expanded(child: SizedBox(height: 65, child: OutlinedButton(onPressed: widget.onArchive, style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700], side: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.item.isSubscription ? T.get('cancel_sub_button') : T.get('consume_button'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)))))), const SizedBox(width: 12), SizedBox(height: 65, width: 65, child: ElevatedButton(onPressed: () => _handleCorrection(-1), style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.zero, alignment: Alignment.center), child: const Icon(Icons.remove, size: 30))), const SizedBox(width: 12), ScaleTransition(scale: _bumpUpAnimation, child: SizedBox(height: 65, width: 65, child: ElevatedButton(onPressed: _handleUsageAdd, style: ElevatedButton.styleFrom(elevation: 5, backgroundColor: maturiColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.zero, alignment: Alignment.center), child: const Icon(Icons.add, size: 35))))]))])),
                          StaggeredSlide(delay: 900, child: _buildUsageChart(context, isRetro, maturiColor, isDark)),
                      ],
                      if (isArchived) Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: SizedBox(width: double.infinity, child: SizedBox(height: 60, child: OutlinedButton.icon(onPressed: widget.onRestore, icon: const Icon(Icons.restore), label: Text(T.get('restore'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), style: OutlinedButton.styleFrom(foregroundColor: maturiColor, side: const BorderSide(color: maturiColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))))),
                      const SizedBox(height: 60),
                ])))))
        ]));
  }

  Widget _buildArchivedAnalysis(BuildContext context, bool isRetro) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSuccess = true;
    String verdictTitle = T.get('verdict_excellent');
    String verdictSub = T.get('verdict_item_success');

    DateTime start = widget.item.purchaseDate;
    DateTime end = widget.item.consumedDate ?? DateTime.now();
    Color verdictColor = Colors.green;
    
    if (widget.item.isSubscription) {
      if (widget.item.targetCost != null && widget.item.costPerUse > widget.item.targetCost!) {
        isSuccess = false;
      }
      verdictTitle = isSuccess ? T.get('verdict_excellent') : T.get('verdict_fail');
      verdictSub = isSuccess ? T.get('verdict_sub_success') : T.get('verdict_sub_fail');
    } else {
      int expectedDays = widget.item.projectedLifespanDays ?? 365;
      DateTime expectedEnd = start.add(Duration(days: expectedDays));
      if (end.isBefore(expectedEnd)) {
        isSuccess = false;
      }
      verdictTitle = isSuccess ? T.get('verdict_excellent') : T.get('verdict_fail');
      verdictSub = isSuccess ? T.get('verdict_item_success') : T.get('verdict_item_fail');
    }

    if (!isSuccess) verdictColor = isRetro ? const Color(0xFFD4522A) : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: isRetro ? Colors.white : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: verdictColor.withValues(alpha: 0.5), width: 2)
      ), 
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSuccess ? Icons.emoji_events : Icons.warning_amber_rounded, color: verdictColor),
              const SizedBox(width: 8),
              Text(verdictTitle, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: verdictColor)),
            ]
          ), 
          const SizedBox(height: 8), 
          Text(verdictSub, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isRetro ? const Color(0xFF3A2817) : colorScheme.onSurface)),
          const SizedBox(height: 25),
          
          if (!widget.item.isSubscription) _buildTimeline(start, end, widget.item.projectedLifespanDays ?? 365, verdictColor, isRetro)
        ]
      )
    ); 
  }

  Widget _buildTimeline(DateTime start, DateTime end, int projectedDays, Color verdictColor, bool isRetro) {
    DateTime expectedEnd = start.add(Duration(days: projectedDays));
    bool diedEarly = end.isBefore(expectedEnd);
    String format(DateTime d) => "${d.day}.${d.month}.${d.year}";
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timelineNode(T.get('bought'), format(start), Colors.grey),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3), thickness: 2)),
        if (diedEarly) ...[
          _timelineNode(T.get('archived'), format(end), verdictColor),
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3), thickness: 2)),
          _timelineNode(T.get('expected'), format(expectedEnd), Colors.grey.withValues(alpha: 0.5)),
        ] else ...[
          _timelineNode(T.get('expected'), format(expectedEnd), Colors.grey),
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3), thickness: 2)),
          _timelineNode(T.get('archived'), format(end), verdictColor),
        ]
      ],
    );
  }

  Widget _timelineNode(String label, String date, Color color) {
    return Column(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        Text(date, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }

  Widget _buildUsageChart(BuildContext context, bool isRetro, Color maturiColor, bool isDark) {
    if (!_isLocaleReady) return const SizedBox(height: 200);
    List<int> historyData = List.from(widget.item.usageHistory);
    if (historyData.isEmpty && !widget.item.isSubscription && widget.item.estimatedUsageCount > 0) {
      DateTime currentDate = widget.item.purchaseDate;
      DateTime now = DateTime.now();
      int intervalDays = widget.item.usagePeriod == 'week' ? 7 : (widget.item.usagePeriod == 'month' ? 30 : (widget.item.usagePeriod == 'year' ? 365 : 1));
      double stepDays = intervalDays / (widget.item.estimatedUsageCount > 0 ? widget.item.estimatedUsageCount : 1);
      while (currentDate.isBefore(now)) { 
        historyData.add(currentDate.millisecondsSinceEpoch); 
        currentDate = currentDate.add(Duration(hours: (stepDays * 24).toInt().clamp(1, 8760))); 
      }
    }
    if (historyData.isEmpty) return const SizedBox.shrink();

    Map<String, int> counts = {}; String dateFormatPattern = _chartView == 'month' ? 'yyyy-MM' : 'yyyy-MM-dd';
    for (int ts in historyData) { DateTime date = DateTime.fromMillisecondsSinceEpoch(ts); String key = DateFormat(dateFormatPattern).format(date); counts[key] = (counts[key] ?? 0) + 1; }
    var sortedKeys = counts.keys.toList()..sort();
    if (_chartView == 'day' && sortedKeys.length > 14) sortedKeys = sortedKeys.sublist(sortedKeys.length - 14);
    if (_chartView == 'month' && sortedKeys.length > 12) sortedKeys = sortedKeys.sublist(sortedKeys.length - 12);

    List<BarChartGroupData> barGroups = []; List<String> xLabels = []; double maxY = 0;
    for (int i = 0; i < sortedKeys.length; i++) {
      String key = sortedKeys[i]; double count = counts[key]!.toDouble(); if (count > maxY) maxY = count;
      xLabels.add(_chartView == 'month' ? DateFormat('MMM', T.code).format(DateFormat(dateFormatPattern).parse(key)) : DateFormat('dd.MM').format(DateFormat(dateFormatPattern).parse(key)));
      barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: count, color: isRetro ? const Color(0xFFD4522A) : maturiColor, width: 16, borderRadius: BorderRadius.circular(4))]));
    }
    return Container(margin: const EdgeInsets.only(top: 35), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isRetro ? Colors.white : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(T.get('chart_history'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isRetro ? const Color(0xFF3A2817) : (isDark ? Colors.white70 : Colors.black54))), Container(decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Row(mainAxisSize: MainAxisSize.min, children: [_buildChartToggleBtn("M", 'month', maturiColor, isRetro), _buildChartToggleBtn("T", 'day', maturiColor, isRetro)]))]),
           const SizedBox(height: 20),
           SizedBox(height: 180, child: BarChart(BarChartData(maxY: maxY + 1, titlesData: FlTitlesData(show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(xLabels[v.toInt().clamp(0, xLabels.length-1)], style: const TextStyle(fontSize: 10)))))), barGroups: barGroups)))
        ]));
  }

  Widget _buildChartToggleBtn(String label, String value, Color activeColor, bool isRetro) { bool isSelected = _chartView == value; return GestureDetector(onTap: () => setState(() => _chartView = value), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isSelected ? (isRetro ? const Color(0xFFD4522A) : activeColor) : Colors.transparent, borderRadius: BorderRadius.circular(15)), child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)))); }

  Widget _buildBigStat({required BuildContext context, required String label, required double value, required Color color, required bool isRetro, required String suffix, Animation<double>? animation, int decimals = 2}) {
    Widget child = Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isRetro ? Colors.white : Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value >= 1000 ? value.toStringAsFixed(0) : value.toStringAsFixed(decimals), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)), if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(fontSize: 14, color: Colors.grey))])
        ]));
    return animation != null ? ScaleTransition(scale: animation, child: child) : child;
  }
}