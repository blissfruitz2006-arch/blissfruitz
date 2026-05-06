import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/settings_provider.dart';

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsAsync = ref.watch(generalSettingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF0F172A) 
              : const Color(0xFF132313),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
      padding: EdgeInsets.fromLTRB(
        24, 
        32, 
        24, 
        screenWidth < 768 ? 70 + MediaQuery.paddingOf(context).bottom : 32
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Main content
              screenWidth > 950 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandSection(context, settingsAsync, true),
                      const Spacer(),
                      _buildLinksSection(context, screenWidth, settingsAsync),
                    ],
                  )
                : Column(
                    children: [
                      _buildBrandSection(context, settingsAsync, false),
                      const SizedBox(height: 48),
                      _buildLinksSection(context, screenWidth, settingsAsync),
                    ],
                  ),
              
              const SizedBox(height: 40),
              
              // Bottom Section
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  return Flex(
                    direction: isSmall ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '© ${DateTime.now().year} BlissFruitz. Crafted for a Healthier You.',
                        textAlign: isSmall ? TextAlign.center : TextAlign.left,
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      if (isSmall) const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: isSmall ? MainAxisAlignment.center : MainAxisAlignment.end,
                        children: [
                          _socialIcon(Icons.facebook),
                          const SizedBox(width: 16),
                          _socialIcon(Icons.camera_alt_rounded),
                          const SizedBox(width: 16),
                          _socialIcon(Icons.business_rounded),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBrandSection(BuildContext context, AsyncValue settingsAsync, bool isLeft) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          settingsAsync.maybeWhen(
            data: (settings) => Text(
              settings.siteName ?? 'BlissFruitz',
              style: GoogleFonts.philosopher(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            orElse: () => Text(
              'BlissFruitz',
              style: GoogleFonts.philosopher(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nature\'s purest harvest, curated with care and delivered directly to your doorstep. From orchard to home, we prioritize quality, health, and transparency in every bite.',
            textAlign: isLeft ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context, double screenWidth, AsyncValue settingsAsync) {
    final isCentered = screenWidth <= 600;
    return Wrap(
      spacing: 64,
      runSpacing: 40,
      alignment: isCentered ? WrapAlignment.center : WrapAlignment.start,
      children: [
        _FooterColumn(
          title: 'Quick Links',
          links: const [
            {'label': 'Home', 'route': '/'},
            {'label': 'Shop', 'route': '/shop'},
            {'label': 'My Account', 'route': '/profile'},
            {'label': 'Contact Us', 'route': '/contact'},
          ],
        ),
        _FooterColumn(
          title: 'Customer Care',
          links: const [
            {'label': 'Track Order', 'route': '/track'},
            {'label': 'Shipping Policy', 'route': '/shipping'},
            {'label': 'Privacy Policy', 'route': '/privacy'},
            {'label': 'Terms of Service', 'route': '/terms'},
          ],
        ),
        _buildContactSection(context, isCentered, settingsAsync),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, bool isCentered, AsyncValue settingsAsync) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            'Connect',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          settingsAsync.maybeWhen(
            data: (settings) => Column(
              crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                _contactItem(Icons.mail_rounded, settings.email ?? 'hello@blissfruitz.com', !isCentered),
                const SizedBox(height: 12),
                _contactItem(Icons.phone_rounded, settings.phone ?? '+91 86559 58384', !isCentered),
                const SizedBox(height: 12),
                _contactItem(Icons.location_on_rounded, settings.address ?? 'Mumbai, Maharashtra, India', !isCentered),
              ],
            ),
            orElse: () => Column(
              crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                _contactItem(Icons.mail_rounded, 'hello@blissfruitz.com', !isCentered),
                const SizedBox(height: 12),
                _contactItem(Icons.phone_rounded, '+91 86559 58384', !isCentered),
                const SizedBox(height: 12),
                _contactItem(Icons.location_on_rounded, 'Mumbai, Maharashtra, India', !isCentered),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text, bool isLeftAligned) {
    return Row(
      mainAxisAlignment: isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryContainer),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            textAlign: isLeftAligned ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<Map<String, String>> links;

  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCentered = screenWidth <= 600;

    return Column(
      crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.go(link['route']!),
              child: Text(
                link['label']!,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

