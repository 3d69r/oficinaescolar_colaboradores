import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SnackType {
  success,
  error,
  warning,
  loading,
}

void showModernSnackBar(
  BuildContext context,
  String message,
  SnackType type, {
  Color? accentColor,
}) {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();

  late final Color accent;
  late final IconData icon;
  late final String label;

  switch (type) {
    case SnackType.success:
      accent = const Color(0xFF35D07F);
      icon = Icons.check_rounded;
      label = 'Listo';

    case SnackType.error:
      accent = const Color(0xFFFF5C6C);
      icon = Icons.close_rounded;
      label = 'Error';

    case SnackType.warning:
      accent = const Color(0xFFFFB84D);
      icon = Icons.priority_high_rounded;
      label = 'Atención';

    case SnackType.loading:
      accent = accentColor ?? const Color(0xFF6C8CFF);
      icon = Icons.sync_rounded;
      label = 'Procesando';
  }

  messenger.showSnackBar(
    SnackBar(
      duration: type == SnackType.loading
          ? const Duration(minutes: 5)
          : const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      content: _AnimatedSnackContent(
        message: message,
        label: label,
        type: type,
        accent: accent,
        icon: icon,
      ),
    ),
  );
}

class _AnimatedSnackContent extends StatefulWidget {
  const _AnimatedSnackContent({
    required this.message,
    required this.label,
    required this.type,
    required this.accent,
    required this.icon,
  });

  final String message;
  final String label;
  final SnackType type;
  final Color accent;
  final IconData icon;

  @override
  State<_AnimatedSnackContent> createState() => _AnimatedSnackContentState();
}

class _AnimatedSnackContentState extends State<_AnimatedSnackContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _iconController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _closing = false;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // ANIMACIÓN DE ENTRADA
    // ------------------------------------------------------------
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.65),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ------------------------------------------------------------
    // ANIMACIÓN DEL ICONO
    // ------------------------------------------------------------
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // ------------------------------------------------------------
    // GLOW
    // ------------------------------------------------------------
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _entryController.forward();

    if (!mounted) return;

    if (widget.type == SnackType.loading) {
      _iconController.repeat();
    } else {
      await _iconController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;

    _closing = true;

    _entryController.reverse().then((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomCenter,
          child: _buildSnack(),
        ),
      ),
    );
  }

  Widget _buildSnack() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowValue =
            0.08 + (_glowController.value * 0.07);

        return Container(
          constraints: const BoxConstraints(
            minHeight: 76,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF181A23),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: widget.accent.withOpacity(glowValue),
                blurRadius: 26,
                spreadRadius: -7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // --------------------------------------------------
                // GLOW DECORATIVO
                // --------------------------------------------------
                Positioned(
                  left: -45,
                  top: -55,
                  child: IgnorePointer(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accent.withOpacity(0.07),
                      ),
                    ),
                  ),
                ),

                // --------------------------------------------------
                // BARRA LATERAL
                // --------------------------------------------------
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.55),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),

                // --------------------------------------------------
                // CONTENIDO
                // --------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    12,
                    14,
                  ),
                  child: Row(
                    children: [
                      _buildAnimatedIcon(),

                      const SizedBox(width: 13),

                      Expanded(
                        child: _buildText(),
                      ),

                      if (widget.type != SnackType.loading) ...[
                        const SizedBox(width: 6),
                        _buildCloseButton(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        final value = Curves.easeOutBack.transform(
          math.min(_iconController.value, 1.0),
        );

        double rotation = 0;

        if (widget.type == SnackType.loading) {
          rotation = _iconController.value * math.pi * 2;
        }

        return Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: widget.type == SnackType.loading
                ? 1.0
                : 0.75 + (value * 0.25),
            child: child,
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.accent.withOpacity(0.14),
          ),
        ),
        child: Center(
          child: widget.type == SnackType.loading
              ? SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.accent,
                    ),
                  ),
                )
              : Icon(
                  widget.icon,
                  color: widget.accent,
                  size: 23,
                ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.accent,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF4F5F7),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _close,
        borderRadius: BorderRadius.circular(13),
        splashColor: widget.accent.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}