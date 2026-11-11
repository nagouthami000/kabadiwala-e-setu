import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// Vibrant Design System Palette
class VibrantColors {
  static const Color inkDark = Color(0xFF081C14);
  static const Color deepEmerald = Color(0xFF0D2B1E);
  static const Color neonLime = Color(0xFFC6F24D);
  static const Color mintCyan = Color(0xFF00F5D4);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color radiantEmerald = Color(0xFF00E676);
  static const Color solarAmber = Color(0xFFFFD166);
  static const Color fireCoral = Color(0xFFFF5376);
  static const Color techPurple = Color(0xFFB388FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonLime, mintCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralFireGradient = LinearGradient(
    colors: [fireCoral, solarAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGlowGradient = LinearGradient(
    colors: [radiantEmerald, electricCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// A floating animated e-waste particle model
class _EWasteFloatingItem {
  final IconData icon;
  final Color color;
  final double size;
  final double initialX; // 0.0 to 1.0 fraction of screen
  final double initialY; // 0.0 to 1.0 fraction of screen
  final double speedX;
  final double speedY;
  final double rotationSpeed;

  const _EWasteFloatingItem({
    required this.icon,
    required this.color,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.speedX,
    required this.speedY,
    required this.rotationSpeed,
  });
}

/// Ambient background featuring animated floating e-waste items
/// (Microchips, Batteries, Circuit nodes, Motherboards, Recycling glyphs)
/// and radiant organic light orbs.
class EWasteAnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const EWasteAnimatedBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<EWasteAnimatedBackground> createState() => _EWasteAnimatedBackgroundState();
}

class _EWasteAnimatedBackgroundState extends State<EWasteAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Curated list of floating tech & e-waste elements
  static const List<_EWasteFloatingItem> _items = [
    _EWasteFloatingItem(
      icon: Icons.memory_rounded, // Microchip
      color: VibrantColors.neonLime,
      size: 38,
      initialX: 0.15,
      initialY: 0.22,
      speedX: 0.8,
      speedY: 1.2,
      rotationSpeed: 1.0,
    ),
    _EWasteFloatingItem(
      icon: Icons.battery_charging_full_rounded, // Battery cell
      color: VibrantColors.mintCyan,
      size: 32,
      initialX: 0.82,
      initialY: 0.18,
      speedX: -1.0,
      speedY: 0.9,
      rotationSpeed: -0.8,
    ),
    _EWasteFloatingItem(
      icon: Icons.recycling_rounded, // Recycling loop
      color: VibrantColors.radiantEmerald,
      size: 44,
      initialX: 0.70,
      initialY: 0.58,
      speedX: 0.6,
      speedY: -1.1,
      rotationSpeed: 1.4,
    ),
    _EWasteFloatingItem(
      icon: Icons.developer_board_rounded, // Motherboard PCB
      color: VibrantColors.electricCyan,
      size: 40,
      initialX: 0.20,
      initialY: 0.75,
      speedX: -0.7,
      speedY: -0.8,
      rotationSpeed: -0.6,
    ),
    _EWasteFloatingItem(
      icon: Icons.cable_rounded, // Wire harness
      color: VibrantColors.solarAmber,
      size: 34,
      initialX: 0.88,
      initialY: 0.85,
      speedX: 0.9,
      speedY: 0.7,
      rotationSpeed: 1.2,
    ),
    _EWasteFloatingItem(
      icon: Icons.hub_rounded, // Circuit junction
      color: VibrantColors.fireCoral,
      size: 30,
      initialX: 0.08,
      initialY: 0.48,
      speedX: 1.1,
      speedY: -0.7,
      rotationSpeed: -1.0,
    ),
    _EWasteFloatingItem(
      icon: Icons.bolt_rounded, // Energy spark
      color: VibrantColors.solarAmber,
      size: 28,
      initialX: 0.50,
      initialY: 0.35,
      speedX: -0.9,
      speedY: 1.0,
      rotationSpeed: 1.5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark tech background
        Container(color: VibrantColors.inkDark),

        // Glowing organic ambient orbs (inspired by the reference UI 3D sphere)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            final orb1X = 0.65 + 0.12 * math.cos(t);
            final orb1Y = 0.25 + 0.08 * math.sin(t);
            final orb2X = 0.25 + 0.10 * math.sin(t * 0.8);
            final orb2Y = 0.70 + 0.10 * math.cos(t * 0.8);
            final orb3X = 0.50 + 0.15 * math.cos(t * 1.2);
            final orb3Y = 0.50 + 0.12 * math.sin(t * 1.2);

            return CustomPaint(
              painter: _AmbientOrbsPainter(
                orb1: Offset(orb1X, orb1Y),
                orb2: Offset(orb2X, orb2Y),
                orb3: Offset(orb3X, orb3Y),
              ),
              size: Size.infinite,
            );
          },
        ),

        // Animated floating e-waste objects
        if (widget.showParticles)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return Stack(
                      children: _items.map((item) {
                        final waveX = math.sin((progress * 2 * math.pi) * item.speedX);
                        final waveY = math.cos((progress * 2 * math.pi) * item.speedY);
                        final x = (item.initialX * width) + (waveX * 28);
                        final y = (item.initialY * height) + (waveY * 34);
                        final rot = (progress * 2 * math.pi * item.rotationSpeed);
                        final alphaVal = ((0.22 + 0.12 * math.sin(progress * 2 * math.pi * item.speedX.abs())) * 255).clamp(0, 255).toInt();

                        return Positioned(
                          left: x,
                          top: y,
                          child: Transform.rotate(
                            angle: rot,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withAlpha((alphaVal * 0.6).toInt()),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: item.size,
                                color: item.color.withAlpha(alphaVal),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),

        // Foreground content (the screens, forms, and glass cards)
        widget.child,
      ],
    );
  }
}

/// Custom painter for the vibrant 3D glowing liquid orbs
class _AmbientOrbsPainter extends CustomPainter {
  final Offset orb1;
  final Offset orb2;
  final Offset orb3;

  _AmbientOrbsPainter({
    required this.orb1,
    required this.orb2,
    required this.orb3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Top right vibrant emerald/mint orb
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          VibrantColors.radiantEmerald.withAlpha(90),
          VibrantColors.mintCyan.withAlpha(45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * orb1.dx, size.height * orb1.dy),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(Offset(size.width * orb1.dx, size.height * orb1.dy), size.width * 0.55, paint1);

    // Bottom left vibrant cyan/blue orb
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          VibrantColors.electricCyan.withAlpha(70),
          const Color(0xFF0D5240).withAlpha(40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * orb2.dx, size.height * orb2.dy),
          radius: size.width * 0.50,
        ),
      );
    canvas.drawCircle(Offset(size.width * orb2.dx, size.height * orb2.dy), size.width * 0.50, paint2);

    // Center subtle warm energy highlight
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          VibrantColors.neonLime.withAlpha(40),
          VibrantColors.fireCoral.withAlpha(20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * orb3.dx, size.height * orb3.dy),
          radius: size.width * 0.40,
        ),
      );
    canvas.drawCircle(Offset(size.width * orb3.dx, size.height * orb3.dy), size.width * 0.40, paint3);
  }

  @override
  bool shouldRepaint(covariant _AmbientOrbsPainter oldDelegate) => true;
}

/// Frosted Glass Card / Container with blur, specular gradient border,
/// and smooth rounded corners (identical to the reference design).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final int tintAlpha;
  final Border? customBorder;
  final bool hasBorder;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.blur = 18,
    this.padding,
    this.margin,
    this.tintColor,
    this.tintAlpha = 22,
    this.customBorder,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tintColor ?? Colors.white;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveTint.withAlpha(tintAlpha),
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? (customBorder ??
                Border.all(
                  color: Colors.white.withAlpha(45),
                  width: 1.2,
                ))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: VibrantColors.neonLime.withAlpha(40),
          highlightColor: VibrantColors.mintCyan.withAlpha(20),
          child: content,
        ),
      );
    }

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (margin != null) {
      glass = Padding(padding: margin!, child: glass);
    }

    return glass;
  }
}

/// High-energy tactile gradient button with glow and rounded pill shape
class VibrantGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final Color textColor;

  const VibrantGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.gradient = VibrantColors.primaryGradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.borderRadius = 18,
    this.elevation = 6,
    this.textColor = VibrantColors.inkDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? Colors.white24 : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: (gradient is LinearGradient && (gradient as LinearGradient).colors.isNotEmpty)
                      ? (gradient as LinearGradient).colors.first.withAlpha(90)
                      : VibrantColors.neonLime.withAlpha(90),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: textColor, size: 20),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                DefaultTextStyle(
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted Glass Button with translucent fill and specular border
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withAlpha(80),
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onPressed,
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: color, size: 18),
                        child: icon!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    DefaultTextStyle(
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      child: label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destination item descriptor for [GlassFloatingNavBar]
class GlassNavDestination {
  final IconData icon;
  final String label;

  const GlassNavDestination({
    required this.icon,
    required this.label,
  });
}

/// Floating Frosted Glass Navigation Pill Dock
/// (Matches the bottom navigation in the user's reference UI)
class GlassFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavDestination> destinations;

  const GlassFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF092017).withAlpha(170),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withAlpha(55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(destinations.length, (index) {
                  final isSelected = index == selectedIndex;
                  final item = destinations[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onDestinationSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 12 : 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VibrantColors.neonLime.withAlpha(45)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? Border.all(
                                color: VibrantColors.neonLime.withAlpha(100),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected
                                ? VibrantColors.neonLime
                                : Colors.white.withAlpha(150),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 5),
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: VibrantColors.neonLime,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
