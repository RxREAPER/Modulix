import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class BulkCompleteAnimationWidget extends StatefulWidget {
  const BulkCompleteAnimationWidget({super.key});

  @override
  State<BulkCompleteAnimationWidget> createState() =>
      _BulkCompleteAnimationWidgetState();
}

class _BulkCompleteAnimationWidgetState
    extends State<BulkCompleteAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0.0 to 1.0

        // Phase 1 (0.0 to 0.25): 0% done
        // Phase 2 (0.25 to 0.40): Tap Bulk Mark button
        // Phase 3 (0.40 to 0.75): Cascading checkmarks
        // Phase 4 (0.75 to 1.00): 100% done

        final bool tapButton = t >= 0.25 && t < 0.40;
        final bool item1Done = t >= 0.40;
        final bool item2Done = t >= 0.55;

        final double percent =
            t < 0.40 ? 0.0 : (t < 0.75 ? ((t - 0.40) / 0.35) : 1.0);

        final int completedCount = item2Done ? 2 : (item1Done ? 1 : 0);

        return Container(
          height: 195,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.sketchBorderColor, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221C1C1C),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Screen App Bar Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valvular Heart Diseases',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.inkForeground,
                        ),
                      ),
                      Text(
                        '$completedCount / 2 videos done',
                        style: TextStyle(
                            fontSize: 8.5,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  // Bulk Complete Button (Modulix style)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tapButton
                          ? const Color(0xFF10B981)
                          : const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1.3,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: tapButton
                              ? Colors.white
                              : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bulk Complete',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: tapButton
                                ? Colors.white
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Modulix Chapter Linear Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 3.5,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                ),
              ),

              const SizedBox(height: 10),

              // Exact Modulix VideoTile 1
              _buildModulixVideoTile(
                serialNumber: 1,
                title: 'Mitral Stenosis: Hemodynamics & Murmurs',
                duration: '34 mins',
                isCompleted: item1Done,
                tileColor: Colors.deepPurple,
              ),

              const SizedBox(height: 6),

              // Exact Modulix VideoTile 2
              _buildModulixVideoTile(
                serialNumber: 2,
                title: 'Aortic Regurgitation: Peripheral Signs',
                duration: '28 mins',
                isCompleted: item2Done,
                tileColor: Colors.pink,
              ),

              const Spacer(),

              // Subtitle tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, size: 13, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      '1-tap syncs offline lectures to your curriculum progress',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Exact Modulix VideoTile component replica
  Widget _buildModulixVideoTile({
    required int serialNumber,
    required String title,
    required String duration,
    required bool isCompleted,
    required Color tileColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : AppTheme.borderLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Marrow-style serial number thumbnail tile
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.15)
                  : tileColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.green, size: 16)
                  : Text(
                      '$serialNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: tileColor,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? Colors.grey.shade400
                        : AppTheme.inkForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 9, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      duration,
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
