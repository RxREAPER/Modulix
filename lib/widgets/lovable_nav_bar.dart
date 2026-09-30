import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class LovableNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LovableNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class LovableNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onTimerTap;
  final List<LovableNavItem> items;

  const LovableNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onTimerTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // items: [Home, Curriculum, Analytics, Profile]
    // Center pinched-off Focus Timer button sits between index 1 and 2
    final isTimerActive = currentIndex == 4;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.sketchBorderColor,
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bottom Nav Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Tab 0: Home
                    Expanded(child: _buildNavItem(0, items[0])),
                    // Tab 1: Curriculum
                    Expanded(child: _buildNavItem(1, items[1])),

                    // Spacer for the center pinched button
                    const SizedBox(width: 68),

                    // Tab 2: Analytics
                    Expanded(child: _buildNavItem(2, items[2])),
                    // Tab 3: Profile
                    Expanded(child: _buildNavItem(3, items[3])),
                  ],
                ),
              ),

              // Pinched-off Center Elevated Focus Timer Button
              Positioned(
                top: -24,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTimerTap();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isTimerActive
                          ? AppTheme.primaryBlue
                          : AppTheme.inkForeground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x321C1C1C),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, LovableNavItem item) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
        }
        onTap(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 22,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade600,
                fontFamily: 'sans-serif',
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
