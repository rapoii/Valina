import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

/// Cupertino-style bottom tab bar dengan translucent blur (Apple HIG).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BlurredTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredTabBar extends StatelessWidget {
  const _BlurredTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (CupertinoIcons.heart_circle_fill, CupertinoIcons.heart_circle, 'Hari Ini'),
    (CupertinoIcons.calendar, CupertinoIcons.calendar, 'Kalender'),
    (CupertinoIcons.chart_bar_fill, CupertinoIcons.chart_bar, 'Wawasan'),
    (CupertinoIcons.chat_bubble_2_fill, CupertinoIcons.chat_bubble_2, 'Chat'),
    (
      CupertinoIcons.person_crop_circle_fill,
      CupertinoIcons.person_crop_circle,
      'Saya',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // RepaintBoundary mengisolasi layer tab bar dari layer scroll di atasnya
    // — tab bar tidak ikut di-rasterize ulang setiap frame saat user scroll.
    // BackdropFilter sigma diturunkan 24 → 16: secara visual hampir tidak
    // berubah, tapi cost blur turun ~50% (kompleksitas kuadratik).
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassNavBar,
              border: const Border(
                top: BorderSide(color: AppColors.separator, width: 0.3),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding + 6),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final selected = i == currentIndex;
                  final (filledIcon, outlineIcon, label) = _items[i];
                  return Expanded(
                    child: _TabItem(
                      icon: selected ? filledIcon : outlineIcon,
                      label: label,
                      selected: selected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentPrimary : AppColors.labelSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
