import 'package:flutter/material.dart';

class StaggeredSlide extends StatelessWidget {
  final int delay;
  final Widget child;
  const StaggeredSlide({super.key, required this.delay, required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart,
      builder: (context, val, _) => Transform.translate(offset: Offset(0, 50 * (1 - val)), child: Opacity(opacity: val, child: child)),
    );
  }
}

class RollingNumber extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String suffix;
  final bool isInt; 
  const RollingNumber({super.key, required this.value, this.style, this.suffix = "", this.isInt = false});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value), duration: const Duration(milliseconds: 1500), curve: Curves.easeOutExpo,
      builder: (context, val, child) {
        String text = isInt ? val.toInt().toString() : val.toStringAsFixed(2);
        return Text("$text$suffix", style: style);
      },
    );
  }
}