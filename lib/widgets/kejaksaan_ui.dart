import 'package:flutter/material.dart';

class KMotion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 360);
  static const slow = Duration(milliseconds: 560);
  static const curve = Curves.easeOutCubic;

  static PageRoute<T> route<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: normal,
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class KStaggeredItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Offset beginOffset;
  final Duration delay;
  final Duration duration;

  const KStaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.beginOffset = const Offset(0, 0.08),
    this.delay = const Duration(milliseconds: 55),
    this.duration = KMotion.slow,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + (delay * index.clamp(0, 8)),
      curve: KMotion.curve,
      builder: (context, value, child) {
        final start = (index.clamp(0, 8) * 0.08).clamp(0.0, 0.64);
        final progress = ((value - start) / (1 - start)).clamp(0.0, 1.0);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              beginOffset.dx * (1 - progress) * 100,
              beginOffset.dy * (1 - progress) * 100,
            ),
            child: Transform.scale(
              scale: 0.96 + (0.04 * progress),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class KColors {
  static const ink = Color(0xff021C16);
  static const dark = Color(0xff021C16);

  static const primary = Color(0xff0B3D2E);
  static const green = Color(0xff0F6B3D);

  static const card = Color(0xff0B3329);
  static const card2 = Color(0xff103D32);

  static const gold = Color(0xffD6A536);
  static const goldLight = Color(0xffFFE08A);

  static const danger = Color(0xffEF4444);

  static const bg = Color(0xff031F19);

  static const softText = Color(0xffC8D8D2);
  static const softGreen = Color(0xffDFF3E6);
  static const greenSoft = Color(0xffDFF3E6);
}

class KGradient {
  static const main = LinearGradient(
    colors: [
      KColors.dark,
      KColors.primary,
      KColors.green,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const card = LinearGradient(
    colors: [
      KColors.card,
      KColors.card2,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gold = LinearGradient(
    colors: [
      KColors.goldLight,
      KColors.gold,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class KText {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const subtitle = TextStyle(
    fontSize: 13,
    color: KColors.softText,
    height: 1.4,
  );

  static const section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: KColors.softText,
    height: 1.4,
  );
}

class KCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool borderGold;
  final VoidCallback? onTap;
  final Color? color;

  const KCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.borderGold = false,
    this.onTap,
    this.color,
  });

  @override
  State<KCard> createState() => _KCardState();
}

class _KCardState extends State<KCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: pressed ? 0.975 : 1,
      duration: KMotion.fast,
      curve: KMotion.curve,
      child: AnimatedContainer(
        duration: KMotion.normal,
        curve: KMotion.curve,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.color,
          gradient: widget.color == null ? KGradient.card : null,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: widget.borderGold
                ? KColors.gold.withOpacity(0.45)
                : Colors.white.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(pressed ? 0.16 : 0.22),
              blurRadius: pressed ? 14 : 20,
              offset: Offset(0, pressed ? 6 : 10),
            ),
          ],
        ),
        child: Padding(
          padding: widget.padding ??
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.radius),
        onHighlightChanged: (value) {
          if (pressed == value) return;
          setState(() => pressed = value);
        },
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}

class KHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const KHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 58, 22, 26),
      decoration: const BoxDecoration(
        gradient: KGradient.main,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KText.title.copyWith(
                    fontSize: 26,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: KText.subtitle,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class KButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool fullWidth;
  final bool loading;

  const KButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
  });

  @override
  State<KButton> createState() => _KButtonState();
}

class _KButtonState extends State<KButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: KMotion.fast,
      curve: KMotion.curve,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        height: 54,
        child: Listener(
          onPointerDown: (_) {
            if (widget.onTap != null && !widget.loading) {
              setState(() => pressed = true);
            }
          },
          onPointerCancel: (_) => setState(() => pressed = false),
          onPointerUp: (_) => setState(() => pressed = false),
          child: ElevatedButton.icon(
            icon: widget.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KColors.dark,
                    ),
                  )
                : widget.icon != null
                    ? Icon(widget.icon, color: KColors.dark)
                    : const SizedBox.shrink(),
            label: AnimatedSwitcher(
              duration: KMotion.fast,
              child: Text(
                widget.text,
                key: ValueKey(widget.text),
                style: const TextStyle(
                  color: KColors.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor:
                  widget.onTap == null ? Colors.grey : KColors.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: widget.loading ? null : widget.onTap,
          ),
        ),
      ),
    );
  }
}
