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
                  'Omnivious Reader',
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
    return GestureDetector(
      onTap: () => _showViewModeDialog(settings.fitMode),
      child: _SettingsSection(
        title: 'View Mode',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Row(
            children: [
              const Icon(Icons.fit_screen, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.fitMode.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Optimal untuk webtoon vertical scroll',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Active',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollModeSection(SettingsState settings) {
    return GestureDetector(
      onTap: () => _showScrollModeDialog(settings.readingMode),
      child: _SettingsSection(
        title: 'Scroll Mode',
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppRadius.radiusLg,
          ),
          child: Row(
            children: [
              const Icon(Icons.swap_vert, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.readingMode.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Webtoon-style continuous scroll',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Active',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
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
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceContainer,
                  title: const Text('Omnivious Reader'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Versi: 0.2.0', style: TextStyle(color: AppColors.onSurface)),
                      SizedBox(height: 4),
                      Text('Phase 6 — Vault Flat PDF Mode', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                  ],
                ),
              );
            },
          ),
          _NavigationTile(
            icon: Icons.code_outlined,
            title: 'Built with',
            subtitle: 'Flutter + Riverpod',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceContainer,
                  title: const Text('Tech Stack'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flutter', style: TextStyle(color: AppColors.onSurface)),
                      Text('Dart', style: TextStyle(color: AppColors.onSurface)),
                      Text('Riverpod — State Management', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                      Text('SQLite (sqflite) — Database', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                      Text('pdfx — PDF Rendering', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                  ],
                ),
              );
            },
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

  void _showViewModeDialog(FitMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View Mode', style: AppTextStyles.titleLg),
            const SizedBox(height: AppSpacing.md),
            ...FitMode.values.map((mode) {
              final isSelected = mode == current;
              return ListTile(
                title: Text(mode.label,
                  style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurface)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setFitMode(mode);
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

  void _showScrollModeDialog(ReadingMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scroll Mode', style: AppTextStyles.titleLg),
            const SizedBox(height: AppSpacing.md),
            ...ReadingMode.values.map((mode) {
              final isSelected = mode == current;
              return ListTile(
                title: Text(mode.label,
                  style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurface)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setReadingMode(mode);
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
