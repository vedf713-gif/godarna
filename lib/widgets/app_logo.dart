import 'package:flutter/material.dart';

class AppLogo extends StatefulWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.backgroundColor,
    this.borderRadius = 20,
    this.withShadow = false,
    this.heroTag,
    this.imagePath = 'assets/images/app_icon.png',
    this.animate = true,
  });

  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final bool withShadow;
  final String? heroTag;
  final String imagePath;
  final bool animate;

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    } else {
      _visible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? cs.surface;
    Widget logo = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.withShadow
            ? [
                BoxShadow(
                  color: cs.shadow.withAlpha((0.15 * 255).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        widget.imagePath,
        fit: BoxFit.contain,
      ),
    );

    if (widget.animate) {
      logo = AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          scale: _visible ? 1.0 : 0.92,
          child: logo,
        ),
      );
    }

    if (widget.heroTag != null) {
      logo = Hero(tag: widget.heroTag!, child: logo);
    }

    return logo;
  }
}
