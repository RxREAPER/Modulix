import 'package:flutter/material.dart';
import '../../models/timer_theme.dart';
import '../../theme/app_theme.dart';

class TimerBackgroundPicker extends StatelessWidget {
  final TimerThemeData activeTheme;
  final ValueChanged<TimerThemeData> onSelectTheme;

  const TimerBackgroundPicker({
    super.key,
    required this.activeTheme,
    required this.onSelectTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required TimerThemeData activeTheme,
    required ValueChanged<TimerThemeData> onSelectTheme,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (ctx) => TimerBackgroundPicker(
        activeTheme: activeTheme,
        onSelectTheme: onSelectTheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.paperBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, color: AppTheme.primaryBlue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Live Screen Backgrounds',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.inkForeground,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select animated themes that transform your timer room and color palette.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // 4 Theme Cards
          ...kTimerThemes.map((thm) {
            final isSelected = thm.id == activeTheme.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.sketchBorderColor : Colors.grey.shade300,
                  width: isSelected ? 2.2 : 1.2,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x221C1C1C),
                          offset: Offset(3, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: thm.gradientColors),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_awesome, color: thm.accentColor, size: 20),
                  ),
                ),
                title: Text(
                  thm.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                subtitle: Text(
                  thm.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 22)
                    : null,
                onTap: () {
                  onSelectTheme(thm);
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
