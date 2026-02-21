import 'package:flutter/material.dart';
import 'dart:ui'; 

class RollingNumber extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;
  final bool isInt;
  final Duration duration; // NEU: Anpassbare Dauer

  const RollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = "",
    this.isInt = false,
    this.duration = const Duration(milliseconds: 800), // Standard: Schneller (war 1200/1500)
  });

  @override
  Widget build(BuildContext context) {
    final monoStyle = style.merge(const TextStyle(
      fontFeatures: [FontFeature.tabularFigures()],
    ));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration, 
      curve: Curves.easeOutExpo,
      builder: (context, val, child) {
        String text;

        if (isInt) {
          text = val.toInt().toString();
        } else {
          double diff = (value - val).abs();
          
          if (diff >= 1.0) {
            // Bei großen Sprüngen: Kommastellen fixieren für mehr Ruhe
            String targetDecimals = (value - value.truncate()).toStringAsFixed(2).substring(1); 
            text = "${val.toInt()}$targetDecimals";
          } else {
            text = val.toStringAsFixed(2);
          }
        }
        
        return Text("$text$suffix", style: monoStyle);
      },
    );
  }
}

class StaggeredSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const StaggeredSlide({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<StaggeredSlide> createState() => _StaggeredSlideState();
}

class _StaggeredSlideState extends State<StaggeredSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _offsetAnim, child: widget.child),
    );
  }
}