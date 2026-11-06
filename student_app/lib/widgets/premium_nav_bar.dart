import 'package:flutter/material.dart';
import '../core/constants.dart';

class PremiumNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const PremiumNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavBarItem> items;

  const PremiumNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Height of the bar itself: 22px icon + 8px padding each side inside the
  /// pill, plus 10px each side inside the container.
  static const double barHeight = 58;

  /// Gap between the bar and the bottom edge of the safe area.
  static const double bottomGap = 16;

  /// Vertical space the floating bar occupies at the bottom of the screen,
  /// including the device's own gesture or navigation-bar inset.
  ///
  /// The shell sets extendBody, so tab content is drawn behind this bar. A
  /// scrollable tab has to add this much bottom padding or its last row sits
  /// underneath the bar and cannot be read or tapped.
  static double spaceFor(BuildContext context) =>
      barHeight + bottomGap + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // The gesture bar / navigation bar inset has to be added here: with a
      // fixed 16px margin the pill sat inside the system gesture area on
      // devices that draw edge to edge, which is every device from Android 15.
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomGap + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppConstants.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.cardBorder.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          final item = items[index];

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? AppConstants.aiGradient : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? AppConstants.glowShadow(AppConstants.accentIndigo) : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? AppConstants.onAccent : AppConstants.textMuted,
                    size: 22,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: AppConstants.onAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
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
  );
}
}
