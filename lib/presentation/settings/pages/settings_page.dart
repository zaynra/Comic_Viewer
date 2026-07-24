import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Tampilan',
            children: [
              _SettingsTile(
                icon: Symbols.dark_mode,
                title: 'Tema',
                subtitle: _getThemeModeLabel(settings.themeMode),
                onTap: () => _showThemeDialog(context, ref, settings.themeMode),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Membaca',
            children: [
              _SettingsTile(
                icon: Symbols.menu_book,
                title: 'Mode Baca',
                subtitle: settings.readingMode.label,
                onTap: () => _showReadingModeDialog(context, ref, settings.readingMode),
              ),
              _SettingsTile(
                icon: Symbols.swap_horiz,
                title: 'Arah Baca',
                subtitle: settings.readingDirection.label,
                onTap: () => _showReadingDirectionDialog(context, ref, settings.readingDirection),
              ),
              _SettingsTile(
                icon: Symbols.fit_screen,
                title: 'Mode Tampilan',
                subtitle: settings.fitMode.label,
                onTap: () => _showFitModeDialog(context, ref, settings.fitMode),
              ),
              _SettingsTile(
                icon: Symbols.screen_lock_rotation,
                title: 'Orientasi Layar',
                subtitle: settings.orientationMode.label,
                onTap: () => _showOrientationDialog(context, ref, settings.orientationMode),
              ),
              SwitchListTile(
                secondary: const Icon(Symbols.screen_lock_rotation, color: AppColors.onSurfaceVariant),
                title: const Text('Kunci Layar Aktif'),
                subtitle: Text(settings.keepScreenOn ? 'Aktif' : 'Nonaktif'),
                value: settings.keepScreenOn,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setKeepScreenOn(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Symbols.skip_next, color: AppColors.onSurfaceVariant),
                title: const Text('Auto Lanjut File'),
                subtitle: const Text('Otomatis ke file berikutnya'),
                value: settings.autoContinue,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAutoContinue(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Tentang',
            children: [
              _SettingsTile(
                icon: Symbols.info,
                title: 'Versi',
                subtitle: '0.2.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Symbols.code,
                title: 'Dibuat dengan',
                subtitle: 'Flutter + Riverpod',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Terang'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Gelap'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sistem'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingDirectionDialog(BuildContext context, WidgetRef ref, ReadingDirection current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arah Baca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReadingDirection.values.map((direction) {
            return RadioListTile<ReadingDirection>(
              title: Text(direction.label),
              value: direction,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReadingDirection(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReadingModeDialog(BuildContext context, WidgetRef ref, ReadingMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Baca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReadingMode.values.map((mode) {
            return RadioListTile<ReadingMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReadingMode(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFitModeDialog(BuildContext context, WidgetRef ref, FitMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FitMode.values.map((mode) {
            return RadioListTile<FitMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFitMode(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOrientationDialog(BuildContext context, WidgetRef ref, OrientationMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Orientasi Layar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrientationMode.values.map((mode) {
            return RadioListTile<OrientationMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setOrientationMode(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.lg,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Symbols.chevron_right, color: AppColors.outline),
      onTap: onTap,
    );
  }
}
