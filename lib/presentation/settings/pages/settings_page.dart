import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildBrightnessSection(settings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildViewModeSection(settings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildScrollModeSection(settings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDisplaySection(settings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildReadingSection(settings),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAboutSection(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppRadius.pill,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OmnivousReader',
                  style: AppTextStyles.headlineMd,
                ),
                const SizedBox(height: 2),
                Text(
                  'SETTINGS',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppRadius.pill,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSection(SettingsState settings) {
    return _SettingsSection(
      title: 'Brightness',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadius.radiusLg,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.light_mode_outlined,
              color: AppColors.outline,
              size: 24,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  thumbColor: AppColors.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 20,
                ),
                ),
                child: Slider(
                  value: settings.readingBrightness,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setReadingBrightness(value);
                  },
                ),
              ),
            ),
            Icon(
              Icons.light_mode,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeSection(SettingsState settings) {
    final modes = [
      (FitMode.fitWidth, Icons.fit_screen, 'Fit Width'),
      (FitMode.fitHeight, Icons.height, 'Fit Height'),
      (FitMode.fitScreen, Icons.crop_free, 'Fit Screen'),
      (FitMode.original, Icons.aspect_ratio, 'Original'),
    ];

    return _SettingsSection(
      title: 'View Mode',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.6,
        children: modes.map((mode) {
          final isSelected = mode.$1 == settings.fitMode;
          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).setFitMode(mode.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceContainerHigh,
                borderRadius: AppRadius.radiusLg,
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mode.$2,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 28,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    mode.$3,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScrollModeSection(SettingsState settings) {
    final modes = [
      (ReadingMode.vertical, Icons.swap_vert, 'Vertical'),
      (ReadingMode.single, Icons.swap_horiz, 'Horizontal'),
      (ReadingMode.doublePage, Icons.view_stream, 'Continuous'),
    ];

    return _SettingsSection(
      title: 'Scroll Mode',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: modes.map((mode) {
            final isSelected = mode.$1 == settings.readingMode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setReadingMode(mode.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceContainer
                        : Colors.transparent,
                    borderRadius: AppRadius.radiusMd,
                    border: isSelected
                        ? Border.all(
                            color:
                                AppColors.outlineVariant.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode.$2,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mode.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDisplaySection(SettingsState settings) {
    return _SettingsSection(
      title: 'Display',
      child: Column(
        children: [
          _ToggleTile(
            icon: Icons.dark_mode_outlined,
            iconColor: AppColors.onSurfaceVariant,
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain',
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
          ),
          _ToggleTile(
            icon: Icons.nightlight_outlined,
            iconColor: AppColors.tertiary,
            title: 'Night Filter',
            subtitle: 'Warmer tint for reading',
            value: settings.darkOverlay > 0,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setDarkOverlay(value ? 0.3 : 0.0);
            },
          ),
          _ToggleTile(
            icon: Icons.stay_current_portrait_outlined,
            iconColor: AppColors.onSurfaceVariant,
            title: 'Keep Screen On',
            subtitle: 'Prevent sleep while reading',
            value: settings.keepScreenOn,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setKeepScreenOn(value);
            },
          ),
          _ToggleTile(
            icon: Icons.skip_next_outlined,
            iconColor: AppColors.onSurfaceVariant,
            title: 'Auto Lanjut File',
            subtitle: 'Otomatis ke file berikutnya',
            value: settings.autoContinue,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setAutoContinue(value);
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingSection(SettingsState settings) {
    return _SettingsSection(
      title: 'Reading',
      child: Column(
        children: [
          _NavigationTile(
            icon: Icons.menu_book_outlined,
            title: 'Reading Direction',
            subtitle: settings.readingDirection.label,
            onTap: () => _showReadingDirectionDialog(settings.readingDirection),
          ),
          _NavigationTile(
            icon: Icons.screen_lock_rotation_outlined,
            title: 'Orientation',
            subtitle: settings.orientationMode.label,
            onTap: () =>
                _showOrientationDialog(settings.orientationMode),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _SettingsSection(
      title: 'About',
      child: Column(
        children: [
          _NavigationTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '0.2.0',
            onTap: () {},
          ),
          _NavigationTile(
            icon: Icons.code_outlined,
            title: 'Built with',
            subtitle: 'Flutter + Riverpod',
            onTap: () {},
            showDivider: false,
          ),
        ],
      ),
    );
  }

  void _showReadingDirectionDialog(ReadingDirection current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reading Direction',
              style: AppTextStyles.titleLg,
            ),
            const SizedBox(height: AppSpacing.md),
            ...ReadingDirection.values.map((direction) {
              final isSelected = direction == current;
              return ListTile(
                title: Text(
                  direction.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setReadingDirection(direction);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showOrientationDialog(OrientationMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Orientation',
              style: AppTextStyles.titleLg,
            ),
            const SizedBox(height: AppSpacing.md),
            ...OrientationMode.values.map((mode) {
              final isSelected = mode == current;
              return ListTile(
                title: Text(
                  mode.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setOrientationMode(mode);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceVariant,
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: AppRadius.pill,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.onPrimary,
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.surfaceVariant,
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceVariant,
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: AppRadius.pill,
          ),
          child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.outline,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}
