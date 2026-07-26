import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GlassAppBar(
                  title: Text('Recent Activity', style: AppTextStyles.headlineMd),
                  leading: GestureDetector(
                    onTap: () => context.go('/'),
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
                  actions: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: AppRadius.pill,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: historyAsync.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 64,
                                color: AppColors.outline,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No recent activity',
                                style: AppTextStyles.titleLg.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Start reading to see your history here',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, groupIndex) {
                          final group = groups[groupIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  group.label,
                                  style: AppTextStyles.titleLg.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              ...group.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _HistoryCard(
                                    item: item,
                                    onTap: () {
                                      context.push('/reader', extra: item.chapter);
                                    },
                                  ),
                                ),
                              ),
                              if (groupIndex < groups.length - 1)
                                const SizedBox(height: AppSpacing.lg),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error loading history',
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            GlassBottomNav(
              currentIndex: 1,
              items: const [
                GlassBottomNavItem(
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view,
                  label: 'Library',
                ),
                GlassBottomNavItem(
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history,
                  label: 'History',
                ),
                GlassBottomNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    break;
                  case 2:
                    context.push('/settings');
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.onTap,
  });

  final HistoryItem item;
  final VoidCallback onTap;

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (item.progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.radiusMd,
                child: item.series.coverPath != null
                    ? Image.asset(
                        item.series.coverPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.series.name,
                    style: AppTextStyles.titleLg.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.chapter.name} • Read ${_timeAgo(item.lastOpenedAt)}',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pill,
                          child: LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$progressPercent%',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Play button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: AppRadius.pill,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primaryFixedDim,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: AppColors.outline,
          size: 24,
        ),
      ),
    );
  }
}
