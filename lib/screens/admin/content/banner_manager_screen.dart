import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/banner_model.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/app_image.dart';
import '../../../providers/banner_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/admin/admin_dialogs.dart';

class BannerManagerScreen extends ConsumerWidget {
  const BannerManagerScreen({super.key});

  void _showBannerForm(BuildContext context, WidgetRef ref, [BannerModel? banner]) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(banner: banner, onSaved: () {
        ref.invalidate(adminBannersProvider);
        // Invalidate specific placements
        ref.invalidate(bannersByPlacementProvider('hero'));
        ref.invalidate(bannersByPlacementProvider('home_top'));
        ref.invalidate(bannersByPlacementProvider('home_middle'));
        ref.invalidate(bannersByPlacementProvider('home_bottom'));
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.surfaceContainerLowest.withValues(alpha: 0.8),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Banner Manager',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            actions: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                ),
                icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
                onPressed: () => _showBannerForm(context, ref),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: bannersAsync.when(
              data: (banners) {
                if (banners.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No banners found')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final banner = banners[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 120,
                                  height: 68,
                                  child: AppImage(
                                    path: banner.imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      banner.title ?? 'Untitled Banner',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Placement: ${banner.placement.toUpperCase()}',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
                                onPressed: () => _showBannerForm(context, ref, banner),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Banner?'),
                                      content: const Text('This will permanently remove this banner.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await AdminService.deleteBanner(banner.id);
                                    ref.invalidate(adminBannersProvider);
                                    ref.invalidate(bannersByPlacementProvider('hero'));
                                    ref.invalidate(bannersByPlacementProvider('home_top'));
                                    ref.invalidate(bannersByPlacementProvider('home_middle'));
                                    ref.invalidate(bannersByPlacementProvider('home_bottom'));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: banners.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerForm(context, ref),
        label: const Text('Add Banner'),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
