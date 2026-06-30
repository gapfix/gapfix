import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidGlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));

    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateToIndex(widget.currentIndex);
    }
  }

  void _animateToIndex(int newIndex) {
    _slideAnimation = Tween<double>(
      begin: _previousIndex.toDouble(),
      end: newIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward(from: 0);
    _scaleController.forward(from: 0);
    _glowController.forward(from: 0);

    _previousIndex = newIndex;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedBuilder(
            animation: Listenable.merge([_slideController, _glowController]),
            builder: (context, child) {
              return Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  // Multi-layer glass effect
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.6),
                          ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.9),
                      width: 0.5,
                    ),
                    left: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                    right: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    // Outer shadow for depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                    // Inner ambient glow
                    BoxShadow(
                      color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.3),
                      blurRadius: 1,
                      spreadRadius: 0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Specular highlight on top edge
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: isDark ? 0.3 : 0.7),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Sliding active indicator
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = constraints.maxWidth / widget.items.length;
                            final indicatorLeft = _slideAnimation.value * itemWidth + (itemWidth - 48) / 2;
                            return Stack(
                              children: [
                                // Active glow pulse
                                Positioned(
                                  left: indicatorLeft - 4,
                                  top: 8,
                                  child: Container(
                                    width: 56,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(
                                              alpha: _glowAnimation.value * (isDark ? 0.4 : 0.25)),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Glass pill indicator
                                Positioned(
                                  left: indicatorLeft,
                                  top: 10,
                                  child: Container(
                                    width: 48,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: isDark
                                            ? [
                                                primaryColor.withValues(alpha: 0.4),
                                                primaryColor.withValues(alpha: 0.2),
                                              ]
                                            : [
                                                primaryColor.withValues(alpha: 0.18),
                                                primaryColor.withValues(alpha: 0.08),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    // Nav items row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(widget.items.length, (index) {
                        final isSelected = index == widget.currentIndex;
                        final item = widget.items[index];
                        return Expanded(
                          child: _LiquidGlassNavItemWidget(
                            icon: item.icon,
                            activeIcon: item.activeIcon,
                            label: item.label,
                            isSelected: isSelected,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            scaleAnimation: isSelected ? _scaleAnimation : null,
                            scaleController: _scaleController,
                            onTap: () => _onItemTapped(index),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassNavItemWidget extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final Animation<double>? scaleAnimation;
  final AnimationController scaleController;
  final VoidCallback onTap;

  const _LiquidGlassNavItemWidget({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.scaleAnimation,
    required this.scaleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade500;
    final selectedColor = primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              width: 48,
              child: Center(
                child: isSelected && scaleAnimation != null
                    ? AnimatedBuilder(
                        animation: scaleAnimation!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: scaleAnimation!.value,
                            child: child,
                          );
                        },
                        child: _buildIcon(selectedColor),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildIcon(
                          isSelected ? selectedColor : unselectedColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    return Icon(
      isSelected ? activeIcon : icon,
      key: ValueKey('${isSelected}_$icon'),
      size: 23,
      color: color,
    );
  }
}
