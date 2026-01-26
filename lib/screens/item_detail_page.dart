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
    final bool showMinusButton = !widget.item.isSubscription; 

    double? progress;
    if (widget.item.targetCost != null && widget.item.targetCost! > 0 && !widget.item.isSubscription) {
      double neededUses = widget.item.price / widget.item.targetCost!;
      if (neededUses < 1) neededUses = 1;
      progress = widget.item.totalUsesCalculated / neededUses;
      if (progress > 1) progress = 1;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            // BILD BEREICH
            Container(
              height: 320, width: double.infinity, alignment: Alignment.center,
              decoration: BoxDecoration(color: isArchived ? Colors.grey.withOpacity(0.1) : colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50))),
              child: SafeArea(child: Hero(tag: widget.heroTag, child: Container(height: 150, width: 150, alignment: Alignment.center, decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(45), image: widget.item.imagePath != null ? DecorationImage(image: FileImage(File(widget.item.imagePath!)), fit: BoxFit.cover) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))]), child: widget.item.imagePath == null ? Material(color: Colors.transparent, child: Text(widget.item.emoji ?? "📦", style: const TextStyle(fontSize: 65))) : null))),
            ),
            const SizedBox(height: 35),
            
            // TITEL & PREIS
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(widget.item.name.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, letterSpacing: 2.5, fontWeight: FontWeight.bold, color: Colors.grey))), if (progress != null && progress >= 1) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.emoji_events, color: Colors.amber))]),
            const SizedBox(height: 8),
            // FIX: Preis deutlich größer
            Text("${widget.item.price.toStringAsFixed(2)} €", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: isArchived ? Colors.grey : colorScheme.onSurface)),
            
            const SizedBox(height: 30),

            // --- ARCHIV ANSICHT ---
            if (isArchived) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text(widget.item.isSubscription ? T.get('sub_ended') : T.get('archived'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text("${widget.item.consumedDate!.day}.${widget.item.consumedDate!.month}.${widget.item.consumedDate!.year}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildHistoryCard(context, widget.item),
              const SizedBox(height: 25),
            ],

            // --- AKTIVE ANSICHT ---
            if (!isArchived) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [_buildBigStat(context, T.get('cost_per_use'), "${widget.item.costPerUse.toStringAsFixed(2)} €", colorScheme.primary), const SizedBox(width: 15), _buildBigStat(context, T.get('usages'), "${widget.item.totalUsesCalculated.toInt()}", colorScheme.secondary)])),
                const SizedBox(height: 35),
                if (progress != null) ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${T.get('goal')}: ${widget.item.targetCost!.toStringAsFixed(2)} €/${T.get('per_usage')}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: progress >= 1 ? Colors.amber : maturiColor))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 18, backgroundColor: Colors.grey.withOpacity(0.1), color: (progress >= 1 ? Colors.amber : maturiColor))), if (progress >= 1) Padding(padding: const EdgeInsets.only(top: 10), child: Text(T.get('goal_reached'), style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w900, letterSpacing: 1.5)))]))
                ],
                const SizedBox(height: 45),
            ],

            // --- BUTTONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25), 
              child: SizedBox(
                width: double.infinity, 
                child: isArchived 
                ? SizedBox(
                    height: 65,
                    child: OutlinedButton.icon(onPressed: widget.onRestore, icon: const Icon(Icons.restore), label: Text(T.get('restore'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), style: OutlinedButton.styleFrom(foregroundColor: maturiColor, side: const BorderSide(color: maturiColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))
                  ) 
                : Row(
                  children: [
                    Expanded(
                      flex: 2, 
                      child: SizedBox(
                        height: 65,
                        child: OutlinedButton(
                          onPressed: widget.onArchive, 
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), 
                          child: Text(widget.item.isSubscription ? T.get('cancel_sub_button') : T.get('consume_button'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)
                        ),
                      )
                    ), 
                    
                    const SizedBox(width: 12),

                    if (showMinusButton) ...[
                      SizedBox(
                        height: 65,
                        width: 65,
                        child: ElevatedButton(
                          onPressed: () => _handleCorrection(-1), 
                          style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.zero),
                          child: const Icon(Icons.remove, size: 30)
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    Expanded(
                      flex: 3, 
                      child: SizedBox(
                        height: 65,
                        child: ElevatedButton.icon(
                          onPressed: _handleUsageAdd, 
                          icon: const Icon(Icons.add_circle_outline, size: 28), 
                          label: Text(T.get('use_now'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
                          style: ElevatedButton.styleFrom(elevation: 5, backgroundColor: maturiColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
                        ),
                      )
                    )
                  ]
                )
              )
            ),
            
            if (!isArchived) ...[
              const SizedBox(height: 25),
              Text("${widget.item.isSubscription ? T.get('started_on') : T.get('bought_on')} ${widget.item.purchaseDate.day}.${widget.item.purchaseDate.month}.${widget.item.purchaseDate.year}", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(BuildContext context, String label, String value, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))])));
  }

  Widget _buildHistoryCard(BuildContext context, Item item) {
    final double actualCost = item.costPerUse;
    double targetCost = item.targetCost ?? 0;
    if (targetCost <= 0) targetCost = item.price; 

    final bool moneySuccess = actualCost <= targetCost;
    final double diffCost = (targetCost - actualCost).abs();

    if (item.isSubscription) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: moneySuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(children: [
          Text(moneySuccess ? T.get('verdict_success') : T.get('verdict_fail'), style: TextStyle(color: moneySuccess ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text("${diffCost.toStringAsFixed(2)}€ ${moneySuccess ? T.get('saved_per_use') : T.get('lost_per_use')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      );
    }

    final int actualDays = item.consumedDate!.difference(item.purchaseDate).inDays;
    final int plannedDays = item.projectedLifespanDays ?? 365; 
    
    final int maxScale = max(actualDays, plannedDays);
    final double fractionPlanned = maxScale > 0 ? plannedDays / maxScale : 0;
    final double fractionActual = maxScale > 0 ? actualDays / maxScale : 0;
    
    bool isLonger = actualDays >= plannedDays;
    Color barColor = (isLonger || moneySuccess) ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8);
    Color textColor = (isLonger || moneySuccess) ? Colors.green : Colors.red;

    String bottomText = "";
    if (isLonger) {
      bottomText = "+${actualDays - plannedDays}d ${T.get('lifespan_longer')}";
    } else {
      if (moneySuccess) bottomText = "-${plannedDays - actualDays}d ${T.get('lifespan_shorter_good')}";
      else bottomText = "-${plannedDays - actualDays}d ${T.get('lifespan_shorter_bad')}";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: moneySuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Text(moneySuccess ? T.get('verdict_success') : T.get('verdict_fail'), style: TextStyle(color: moneySuccess ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text("${diffCost.toStringAsFixed(2)}€ ${moneySuccess ? T.get('saved_per_use') : T.get('lost_per_use')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 35),
          
          Align(alignment: Alignment.centerLeft, child: Text(T.get('lifespan_analysis'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
          const SizedBox(height: 15),
          
          SizedBox(
            height: 45,
            child: LayoutBuilder(builder: (context, constraints) {
              final double fullWidth = constraints.maxWidth;
              return Stack(
                children: [
                  Container(width: fullWidth, height: 45, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12))),
                  Positioned(left: (fullWidth * fractionPlanned).clamp(0, fullWidth) - 2, child: Container(width: 4, height: 45, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)))),
                  Container(width: (fullWidth * fractionActual).clamp(0, fullWidth), height: 45, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 10), child: Text("${actualDays}d", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  if (fractionActual < fractionPlanned - 0.2 || fractionActual > fractionPlanned + 0.2)
                    Positioned(left: (fullWidth * fractionPlanned).clamp(0, fullWidth - 50) + 5, top: 14, child: Text("${T.get('goal')}: ${plannedDays}d", style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.bold)))
                ],
              );
            }),
          ),
          
          const SizedBox(height: 15),
          Text(bottomText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15))
        ],
      ),
    );
  }
}