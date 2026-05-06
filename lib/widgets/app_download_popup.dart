import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

final appDownloadDismissedProvider = StateProvider<bool>((ref) => false);

class AppDownloadPopup extends ConsumerStatefulWidget {
  const AppDownloadPopup({super.key});

  @override
  ConsumerState<AppDownloadPopup> createState() => _AppDownloadPopupState();
}

class _AppDownloadPopupState extends ConsumerState<AppDownloadPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Show after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDismissed = ref.watch(appDownloadDismissedProvider);
    if (isDismissed) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Positioned(
      bottom: isMobile ? 90 : 24, // Elevation to avoid bottom nav
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.install_mobile_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BlissFruitz for Android',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Download our app for better experience!',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    // Use Uri.base.origin to get the absolute domain (e.g., https://yourwebsite.com)
                    final url = Uri.parse('${Uri.base.origin}/downloads/app-release.apk'); 
                    try {
                      await launchUrl(
                        url, 
                        mode: LaunchMode.externalApplication,
                        webOnlyWindowName: '_blank',
                      );
                    } catch (e) {
                      debugPrint('Could not launch Android app download link: $e');
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Download', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => ref.read(appDownloadDismissedProvider.notifier).state = true,
                  icon: Icon(
                    Icons.close_rounded, 
                    size: 20, 
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

