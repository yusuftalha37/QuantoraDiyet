import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism (buzlu cam) tasarım yapı taşları.
/// - [FrostedBackground]: renkli degrade + bulanık ışık lekeleri (arka plan).
/// - [GlassCard]: saydam + arkasını bulanıklaştıran, ince ışıklı kenarlı kart.
/// Okunabilirlik için cam yeterince opak tutulur (hedef kitle yaşlı/az teknoloji).

class FrostedBackground extends StatelessWidget {
  final Widget child;
  const FrostedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Ana degrade
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [Color(0xFF241A14), Color(0xFF17120F)]
                    : const [Color(0xFFFFF3E9), Color(0xFFFCE3CE), Color(0xFFF8D7C4)],
              ),
            ),
          ),
        ),
        // Sıcak turuncu ışık lekesi (sol üst)
        _blob(
          top: -90,
          left: -70,
          size: 260,
          color: const Color(0xFFF2924A).withOpacity(dark ? 0.35 : 0.55),
        ),
        // Tamamlayıcı yeşil/teal leke (sağ alt)
        _blob(
          bottom: -80,
          right: -60,
          size: 240,
          color: const Color(0xFF2BA98C).withOpacity(dark ? 0.28 : 0.38),
        ),
        // Pembe-şeftali leke (orta sağ)
        _blob(
          top: 220,
          right: -90,
          size: 200,
          color: const Color(0xFFF26B5E).withOpacity(dark ? 0.22 : 0.30),
        ),
        child,
      ],
    );
  }

  Widget _blob({double? top, double? left, double? right, double? bottom, required double size, required Color color}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Buzlu cam kart: arkasını bulanıklaştırır, saydam beyaz dolgu + ışıklı kenar.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint;
  final double? opacity;
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = 18,
    this.tint,
    this.opacity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseTint = tint ?? (dark ? const Color(0xFF2A2420) : Colors.white);
    final fillOpacity = opacity ?? (dark ? 0.42 : 0.58);
    final borderColor = (dark ? Colors.white : Colors.white).withOpacity(dark ? 0.16 : 0.60);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseTint.withOpacity(fillOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: child,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.35 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}
