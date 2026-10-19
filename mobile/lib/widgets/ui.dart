import 'package:flutter/material.dart';
import '../theme.dart';

/// İnce kenarlı, düşük köşeli yüzey. Gölge/degrade yok; ayrımı kenar ve boşluk yapar.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: c.hairline),
    );
    final content = Padding(padding: padding, child: child);
    return Material(
      color: background ?? c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Küçük, aralıklı, büyük harf bölüm etiketi — başlıkları şişirmeden hiyerarşi kurar.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: c.inkMuted,
      ),
    );
  }
}

/// Öğün kategorisini belli eden küçük renkli nokta.
class MealDot extends StatelessWidget {
  final Color color;
  final double size;
  const MealDot(this.color, {super.key, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
