import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math'; 
import '../models/item.dart';
import '../utils/translations.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final String heroTag;
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

class _ItemDetailPageState extends State<ItemDetailPage> {
  
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
    const Color maturiColor = Color(0xFF6BB8A7);
    final bool isArchived = widget.item.consumedDate != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double? progress;
    if (widget.item.targetCost != null && widget.item.targetCost! > 0 && !widget.item.isSubscription) {
      double neededUses = widget.item.price / widget.item.targetCost!;
      if (neededUses < 1) neededUses = 1;
      progress = widget.item.totalUsesCalculated / neededUses;
      if (progress > 1) progress = 1;
    }

    String usageDisplayValue = widget.item.isSubscription ? "${widget.item.manualClicks}" : "${widget.item.totalUsesCalculated.toInt()}";

    DateTime buyDate = widget.item.purchaseDate;
    DateTime? targetDate;
    if (!widget.item.isSubscription && widget.item.projectedLifespanDays != null) {
      targetDate = buyDate.add(Duration(days: widget.item.projectedLifespanDays!));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isArchived && !isDark ? Colors.black87 : colorScheme.onSurface), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onEdit,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        child: const Icon(Icons.edit),
      ),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 280, width: double.infinity, alignment: Alignment.center,
              decoration: BoxDecoration(color: isArchived ? Colors.grey[300] : colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50))),
              child: SafeArea(child: Hero(tag: widget.heroTag, child: Container(height: 140, width: 140, alignment: Alignment.center, decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(45), image: widget.item.imagePath != null ? DecorationImage(image: FileImage(File(widget.item.imagePath!)), fit: BoxFit.cover, colorFilter: isArchived ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))]), child: widget.item.imagePath == null ? Material(color: Colors.transparent, child: Text(widget.item.emoji ?? "📦", style: const TextStyle(fontSize: 60))) : null))),
            ),
            const SizedBox(height: 20),
            
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(widget.item.name.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 18, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.grey))),
            const SizedBox(height: 5),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: FittedBox(fit: BoxFit.scaleDown, child: Text("${widget.item.price.toStringAsFixed(2)} €", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: isArchived ? Colors.grey : colorScheme.onSurface)))),
            
            const SizedBox(height: 10),
            Column(
              children: [
                Text("${T.get('bought_on')} ${buyDate.day}.${buyDate.month}.${buyDate.year}", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                if (targetDate != null && !isArchived)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Geplantes Ende: ${targetDate.day}.${targetDate.month}.${targetDate.year}", style: TextStyle(color: maturiColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            const SizedBox(height: 30),

            if (isArchived) 
              _buildArchivedAnalysis(context)
            else ...[
                if (progress != null) 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30), 
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("${T.get('goal')}: ${widget.item.targetCost!.toStringAsFixed(2)} €/${T.get('per_usage')}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)), 
                          Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: progress >= 1 ? Colors.amber : maturiColor))
                        ]), 
                        const SizedBox(height: 8), 
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey.withOpacity(0.1), color: (progress >= 1 ? Colors.amber : maturiColor))),
                        const SizedBox(height: 25), 
                      ]
                    )
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20), 
                  child: Row(
                    children: [
                      _buildBigStat(context, T.get('cost_per_use'), "${widget.item.costPerUse.toStringAsFixed(2)} €", colorScheme.primary), 
                      const SizedBox(width: 15), 
                      _buildBigStat(context, T.get('usages'), usageDisplayValue, colorScheme.secondary)
                    ]
                  )
                ),
                
                const SizedBox(height: 35),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(T.get('usage_section_title'), 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 1)
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25), 
                  child: SizedBox(
                    width: double.infinity, 
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: OutlinedButton(
                              onPressed: widget.onArchive, 
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700], 
                                side: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                              ), 
                              child: FittedBox(
                                fit: BoxFit.scaleDown, 
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    widget.item.isSubscription ? T.get('cancel_sub_button') : T.get('consume_button'), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                                    textAlign: TextAlign.center
                                  ),
                                )
                              )
                            ),
                          )
                        ), 
                        
                        const SizedBox(width: 12),
                        
                        // FIX: Padding Zero und Alignment Center für perfekte Mitte
                        SizedBox(
                          height: 65, 
                          width: 65, 
                          child: ElevatedButton(
                            onPressed: () => _handleCorrection(-1), 
                            style: ElevatedButton.styleFrom(
                              elevation: 0, 
                              backgroundColor: Colors.red.withOpacity(0.1), 
                              foregroundColor: Colors.red, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: EdgeInsets.zero, // WICHTIG
                              alignment: Alignment.center // WICHTIG
                            ), 
                            child: const Icon(Icons.remove, size: 30)
                          )
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // FIX: Padding Zero und Alignment Center für perfekte Mitte
                        SizedBox(
                          height: 65,
                          width: 65,
                          child: ElevatedButton(
                            onPressed: _handleUsageAdd, 
                            style: ElevatedButton.styleFrom(
                              elevation: 5, 
                              backgroundColor: maturiColor, 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: EdgeInsets.zero, // WICHTIG
                              alignment: Alignment.center // WICHTIG
                            ),
                            child: const Icon(Icons.add, size: 35) 
                          )
                        )
                      ]
                    )
                  )
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

  Widget _buildBigStat(BuildContext context, String label, String value, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))])));
  }

  Widget _buildArchivedAnalysis(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Item item = widget.item;
    DateTime buyDate = item.purchaseDate;
    DateTime consumeDate = item.consumedDate!;
    int actualDays = max(1, consumeDate.difference(buyDate).inDays);
    int plannedDays = item.projectedLifespanDays ?? 365;
    bool isSuccess = item.isSubscription ? (item.costPerUse <= (item.targetCost ?? item.price)) : (actualDays >= plannedDays);
    Color stateColor = isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE57373);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${buyDate.day}.${buyDate.month}.${buyDate.year}", style: const TextStyle(fontSize: 12, color: Colors.grey)), Text("${consumeDate.day}.${consumeDate.month}.${consumeDate.year}", style: const TextStyle(fontSize: 12, color: Colors.grey))]),
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
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: isDark ? stateColor.withOpacity(0.2) : (isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)), borderRadius: BorderRadius.circular(25)),
            child: Column(children: [
              Icon(isSuccess ? Icons.emoji_events : Icons.money_off, size: 40, color: stateColor),
              const SizedBox(height: 15),
              Text(isSuccess ? "Exzellent!" : "Zu teuer", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: stateColor, letterSpacing: 1.5)),
              const Divider(height: 40, color: Colors.black12),
              Row(children: [
                Expanded(child: Column(children: [Text(item.isSubscription ? "${item.manualClicks}" : "${actualDays}d", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)), Text(item.isSubscription ? "Nutzungen" : "Dauer", style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                Container(width: 1, height: 40, color: Colors.black12),
                Expanded(child: Column(children: [Text("${item.costPerUse.toStringAsFixed(2)}€", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stateColor)), const Text("Kosten/Nutzung", style: TextStyle(fontSize: 12, color: Colors.grey))])),
              ])
            ]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}