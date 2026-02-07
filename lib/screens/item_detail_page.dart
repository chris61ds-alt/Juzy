import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math'; 
import '../models/item.dart';
import '../utils/translations.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final String heroTag; // Wir behalten die Variable, nutzen sie aber nicht mehr für den Hero-Effekt
  final VoidCallback onEdit;
  final VoidCallback onUsageAdd;
  final Function(int) onUsageCorrect;
  final VoidCallback onRestore; 
  final VoidCallback onArchive; 

  const ItemDetailPage({
    super.key, 
    required this.item, 
    required this.heroTag,
    required this.onEdit,
    required this.onUsageAdd,
    required this.onUsageCorrect,
    required this.onRestore, 
    required this.onArchive, 
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900), // Schön "saftig" langsam
      vsync: this,
    );
    
    // HIER IST DER POP-EFFEKT:
    // Wir starten bei 0.0 (unsichtbar) und gehen auf 1.0.
    // elasticOut sorgt für das "Wackelpudding"-Aufploppen.
    // Da wir TweenSequence nicht nutzen, stürzt elasticOut auch nicht ab!
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );

    // Sofort starten, keine Verzögerung mehr nötig
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleUsageAdd() {
    widget.onUsageAdd(); 
    setState(() {}); 
  }

  void _handleCorrection(int delta) {
    if (widget.item.manualClicks + delta >= 0) {
      widget.onUsageCorrect(widget.item.manualClicks + delta);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final bool isRetro = Theme.of(context).scaffoldBackgroundColor == const Color(0xFFF9F3E6);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color mainBgColor = isRetro 
        ? const Color(0xFFF9F3E6) 
        : (isDark ? const Color(0xFF121212) : Colors.white);

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
    double priceVal = widget.item.price;
    double costPerUseVal = widget.item.costPerUse;

    DateTime buyDate = widget.item.purchaseDate;
    DateTime? targetDate;
    if (!widget.item.isSubscription && widget.item.projectedLifespanDays != null) {
      targetDate = buyDate.add(Duration(days: widget.item.projectedLifespanDays!));
    }

    final priceColor = isRetro 
        ? const Color(0xFF3A2817) 
        : (isDark ? Colors.white : Colors.black87);

    final appBarIconColor = !isDark && !isRetro ? Colors.black87 : colorScheme.onSurface;

    return Scaffold(
      backgroundColor: mainBgColor,
      appBar: AppBar(
        backgroundColor: mainBgColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarIconColor), 
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: widget.onEdit,
            icon: Icon(Icons.edit, color: appBarIconColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER BILD (POP-UP) ---
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                height: 250, width: double.infinity, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isArchived ? Colors.grey[300] : colorScheme.surfaceVariant.withOpacity(0.3), 
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50))
                ),
                // WICHTIG: KEIN HERO WIDGET MEHR HIER!
                child: Container(
                  height: 140, width: 140, alignment: Alignment.center, 
                  decoration: BoxDecoration(
                    color: colorScheme.surface, 
                    borderRadius: BorderRadius.circular(45), 
                    image: widget.item.imagePath != null ? DecorationImage(
                      image: FileImage(File(widget.item.imagePath!)), 
                      fit: BoxFit.cover, 
                      colorFilter: null 
                    ) : null, 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))]
                  ), 
                  child: widget.item.imagePath == null ? Material(color: Colors.transparent, child: Text(widget.item.emoji ?? "📦", style: const TextStyle(fontSize: 60))) : null
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- TITEL & PREIS ---
            _StaggeredSlide(
              delay: 300,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), 
                child: Text(widget.item.name.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.grey))
              ),
            ),
            const SizedBox(height: 5),
            
            _StaggeredSlide(
              delay: 400,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40), 
                child: FittedBox(
                  fit: BoxFit.scaleDown, 
                  child: _RollingNumber(
                    value: priceVal, 
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: priceColor),
                    suffix: " €",
                  )
                )
              ),
            ),
            
            const SizedBox(height: 10),
            
            // --- DATEN ---
            _StaggeredSlide(
              delay: 500,
              child: Column(
                children: [
                  Text("${T.get('bought_on')} ${buyDate.day}.${buyDate.month}.${buyDate.year}", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (isArchived)
                    Text("${T.get('item_archived')}: ${widget.item.consumedDate!.day}.${widget.item.consumedDate!.month}.${widget.item.consumedDate!.year}", style: TextStyle(color: isRetro ? const Color(0xFFD4522A) : colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  if (targetDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("${T.get('calc_date')} ${targetDate.day}.${targetDate.month}.${targetDate.year}", style: TextStyle(color: maturiColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (isArchived) 
              _buildArchivedAnalysis(context, isRetro)
            else ...[
                if (progress != null) 
                  _StaggeredSlide(
                    delay: 600,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30), 
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text("${T.get('goal')}: ${widget.item.targetCost!.toStringAsFixed(2)} €/${T.get('per_usage')}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)), 
                            Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: progress >= 1 ? Colors.amber : maturiColor))
                          ]), 
                          const SizedBox(height: 8), 
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutExpo,
                            builder: (context, val, _) => ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: val, minHeight: 12, backgroundColor: Colors.grey.withOpacity(0.1), color: (val >= 1 ? Colors.amber : maturiColor))),
                          ),
                          const SizedBox(height: 25), 
                        ]
                      )
                    ),
                  ),

                _StaggeredSlide(
                  delay: 700,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), 
                    child: Row(
                      children: [
                        _buildBigStat(context, T.get('cost_per_use'), costPerUseVal, colorScheme.primary, isRetro, " €"), 
                        const SizedBox(width: 15), 
                        _buildBigStat(context, T.get('usages'), usageVal, colorScheme.secondary, isRetro, ""), 
                      ]
                    )
                  ),
                ),
                
                const SizedBox(height: 35),

                _StaggeredSlide(
                  delay: 800,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(T.get('usage_section_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25), 
                        child: SizedBox(
                          width: double.infinity, 
                          child: Row(
                            children: [
                              Expanded(child: SizedBox(height: 65, child: OutlinedButton(onPressed: widget.onArchive, style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700], side: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.item.isSubscription ? T.get('cancel_sub_button') : T.get('consume_button'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)))))), 
                              const SizedBox(width: 12),
                              SizedBox(height: 65, width: 65, child: ElevatedButton(onPressed: () => _handleCorrection(-1), style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.zero, alignment: Alignment.center), child: const Icon(Icons.remove, size: 30))),
                              const SizedBox(width: 12),
                              SizedBox(height: 65, width: 65, child: ElevatedButton(onPressed: _handleUsageAdd, style: ElevatedButton.styleFrom(elevation: 5, backgroundColor: maturiColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.zero, alignment: Alignment.center), child: const Icon(Icons.add, size: 35)))
                            ]
                          )
                        )
                      ),
                    ],
                  ),
                ),
            ],

            if (isArchived)
               Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: SizedBox(width: double.infinity, child: SizedBox(height: 60, child: OutlinedButton.icon(onPressed: widget.onRestore, icon: const Icon(Icons.restore), label: Text(T.get('restore'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), style: OutlinedButton.styleFrom(foregroundColor: maturiColor, side: const BorderSide(color: maturiColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))))), 

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(BuildContext context, String label, dynamic value, Color color, bool isRetro, String suffix) {
    final bgColor = isRetro ? Colors.white : Theme.of(context).colorScheme.surface;
    
    double numericVal = 0;
    if (value is String) {
      numericVal = double.tryParse(value) ?? 0;
    } else if (value is double) {
      numericVal = value;
    } else if (value is int) {
      numericVal = value.toDouble();
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), 
        decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(25), 
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: isRetro ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))] : null
        ), 
        child: Column(
          children: [
            _RollingNumber(
              value: numericVal, 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              suffix: suffix,
              isInt: suffix.isEmpty, 
            ),
            const SizedBox(height: 6), 
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))
          ]
        )
      )
    );
  }

  Widget _buildArchivedAnalysis(BuildContext context, bool isRetro) {
    // ... Identischer Inhalt für Archiv (gekürtzt dargestellt, da oben gleich)
    // Wir nutzen hier aber auch _StaggeredSlide für den Effekt
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Item item = widget.item;
    DateTime buyDate = item.purchaseDate;
    DateTime consumeDate = item.consumedDate!;
    int actualDays = max(1, consumeDate.difference(buyDate).inDays);
    int plannedDays = item.projectedLifespanDays ?? 365;
    
    bool isSuccess = item.isSubscription ? (item.costPerUse <= (item.targetCost ?? item.price)) : (actualDays >= plannedDays);
    if (!item.isSubscription && item.targetCost != null && item.targetCost! > 0) {
       isSuccess = item.costPerUse <= item.targetCost!;
    }

    Color stateColor = isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
    Color boxColor = isRetro ? Colors.white : (isDark ? stateColor.withOpacity(0.2) : (isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)));
    final dateTextColor = isRetro ? const Color(0xFF3A2817) : (isDark ? Colors.white70 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${buyDate.day}.${buyDate.month}.${buyDate.year}", style: TextStyle(fontSize: 12, color: dateTextColor, fontWeight: FontWeight.bold)), 
            Text("${consumeDate.day}.${consumeDate.month}.${consumeDate.year}", style: TextStyle(fontSize: 12, color: dateTextColor, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 5),
          SizedBox(height: 40, child: Stack(alignment: Alignment.centerLeft, children: [
            Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(5))),
            LayoutBuilder(builder: (ctx, constraints) {
              int maxDays = max(actualDays, plannedDays);
              return Stack(alignment: Alignment.centerLeft, children: [
                Container(margin: EdgeInsets.only(left: constraints.maxWidth * (plannedDays / maxDays)), width: 2, height: 20, color: Colors.black45),
                Container(width: constraints.maxWidth * (actualDays / maxDays), height: 10, decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(5))),
              ]);
            })
          ])),
          const SizedBox(height: 20),
          _StaggeredSlide(
            delay: 100,
            child: Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(
                color: boxColor, 
                borderRadius: BorderRadius.circular(25),
                border: isRetro ? Border.all(color: stateColor.withOpacity(0.3), width: 1.5) : null,
                boxShadow: isRetro ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))] : null
              ),
              child: Column(children: [
                Icon(isSuccess ? Icons.emoji_events : Icons.money_off, size: 40, color: stateColor),
                const SizedBox(height: 10),
                Text(isSuccess ? T.get('verdict_excellent') : T.get('verdict_expensive'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stateColor, letterSpacing: 1.0)),
                const Divider(height: 30, color: Colors.black12),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Expanded(child: Column(children: [FittedBox(fit: BoxFit.scaleDown, child: Text("${actualDays}d", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))), Text(T.get('days'), style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                    Container(width: 1, height: 35, color: Colors.black12),
                    Expanded(child: Column(children: [FittedBox(fit: BoxFit.scaleDown, child: Text("${item.totalUsesCalculated.toInt()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))), Text(T.get('usages'), style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                    Container(width: 1, height: 35, color: Colors.black12),
                    Expanded(child: Column(children: [FittedBox(fit: BoxFit.scaleDown, child: Text("${item.costPerUse.toStringAsFixed(2)}€", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: stateColor))), Text(T.get('cost_per_use'), style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                  ],
                )
              ]),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _RollingNumber extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;
  final bool isInt;

  const _RollingNumber({required this.value, required this.style, this.suffix = "", this.isInt = false});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500), 
      curve: Curves.easeOutExpo, 
      builder: (context, val, child) {
        String text;
        if (isInt) {
          text = val.toInt().toString();
        } else {
          text = val.toStringAsFixed(2);
        }
        return Text("$text$suffix", style: style);
      },
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
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _offsetAnim, child: widget.child));
  }
}