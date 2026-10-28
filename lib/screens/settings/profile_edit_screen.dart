import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/modulix_theme.dart';
import '../../widgets/animations/apple_pressable.dart';
import '../../widgets/feedback/modulix_toast.dart';
import '../../widgets/profile/profile_customization.dart';

/// Full-page Profile Edit Sub-page.
/// Allows doctor name editing and avatar/palette customization with a top-bar Save action.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late String _selectedColorId;
  late String _selectedIconId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appState = ref.read(appStateProvider).valueOrNull ?? AppState.empty;
    _nameController = TextEditingController(text: appState.doctorName);
    _selectedColorId = appState.avatarColorId;
    _selectedIconId = appState.avatarIconId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final inputName = _nameController.text.trim();
      await ref.read(appStateProvider.notifier).saveProfile(
            doctorName: inputName,
            avatarColorId: _selectedColorId,
            avatarIconId: _selectedIconId,
          );

      if (mounted) {
        ModulixToast.showSuccess(
          context,
          message: 'Profile saved successfully',
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/settings');
        }
      }
    } catch (_) {
      if (mounted) {
        ModulixToast.showError(
          context,
          message: 'Failed to save profile changes',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.modulixTheme;

    return Scaffold(
      backgroundColor: activeTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: activeTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: activeTheme.inkForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          'Profile',
          style: AppTheme.headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: activeTheme.inkForeground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ApplePressable(
                onTap: _isSaving ? null : _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
        children: [
          // Centered Live Avatar Preview
          Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeTheme.borderSubtle,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ProfileAvatar(
                size: 96,
                colorId: _selectedColorId,
                iconId: _selectedIconId,
                doctorName: _nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim()
                    : 'Doctor',
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Doctor Name Input Field
          Text(
            'DOCTOR NAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: activeTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeTheme.borderSubtle,
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: activeTheme.inkForeground,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Safi or Dr. House',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: activeTheme.mutedText.withValues(alpha: 0.6),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 28),

          // Avatar Character Grid
          Text(
            'AVATAR CHARACTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: activeTheme.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.9,
            ),
            itemCount: kProfileAvatars.length,
            itemBuilder: (context, index) {
              final item = kProfileAvatars[index];
              final isSelected = item.id == _selectedIconId;
              final selectedHighlight = AppTheme.accentPrimary;

              return ApplePressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIconId = item.id);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedHighlight.withValues(alpha: 0.08)
                        : activeTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? selectedHighlight : activeTheme.borderSubtle,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProfileAvatar(
                        size: 48,
                        colorId: _selectedColorId,
                        iconId: item.id,
                        doctorName: _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Doctor',
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? selectedHighlight : activeTheme.inkForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
