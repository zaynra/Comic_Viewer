import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/chapter.dart';
import '../../shared/widgets/glass_app_bar.dart';

class ThumbnailViewerPage extends ConsumerStatefulWidget {
  const ThumbnailViewerPage({
    super.key,
    required this.chapter,
    required this.totalPages,
    this.currentPage = 0,
    this.onPageSelected,
  });

  final Chapter chapter;
  final int totalPages;
  final int currentPage;
  final ValueChanged<int>? onPageSelected;

  @override
  ConsumerState<ThumbnailViewerPage> createState() =>
      _ThumbnailViewerPageState();
}

class _ThumbnailViewerPageState extends ConsumerState<ThumbnailViewerPage> {
  late ScrollController _scrollController;
  late int _selectedPage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedPage = widget.currentPage;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    setState(() => _selectedPage = page);
    widget.onPageSelected?.call(page);

    // Scroll to make the selected page visible
    final targetOffset = page * 180.0; // Approximate item height
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            GlassAppBar(
              title: Text(
                widget.chapter.name,
                style: AppTextStyles.headlineMd,
              ),
              leading: GestureDetector(
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
              actions: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
            // Thumbnail grid
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1 / 1.4,
                ),
                itemCount: widget.totalPages,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedPage;
                  return _ThumbnailItem(
                    pageNumber: index + 1,
                    isSelected: isSelected,
                    onTap: () => _jumpToPage(index),
                  );
                },
              ),
            ),
            // Bottom navigation bar
            _BottomNavBar(
              currentPage: _selectedPage,
              totalPages: widget.totalPages,
              onPageTap: _jumpToPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailItem extends StatelessWidget {
  const _ThumbnailItem({
    required this.pageNumber,
    required this.isSelected,
    required this.onTap,
  });

  final int pageNumber;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.05),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Page content placeholder
                  Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.outline.withValues(alpha: 0.3),
                      size: 32,
                    ),
                  ),
                  // Active page glow overlay
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusLg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'P$pageNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    // Calculate page markers
    final markers = <int>[];
    if (totalPages <= 10) {
      for (var i = 0; i < totalPages; i++) {
        markers.add(i);
      }
    } else {
      markers.add(0);
      final step = (totalPages - 1) / 4;
      for (var i = 1; i < 4; i++) {
        markers.add((step * i).round());
      }
      markers.add(totalPages - 1);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.safeMargin,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: AppRadius.radiusXl,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page markers
          Row(
            children: markers.map((pageIndex) {
              final isSelected = pageIndex == currentPage;
              return GestureDetector(
                onTap: () => onPageTap(pageIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    pageIndex == 0
                        ? 'P1'
                        : pageIndex == totalPages - 1
                            ? 'End'
                            : 'P${pageIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Jump to button
          Container(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Jump to...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
