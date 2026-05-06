import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/footer.dart';

/// Local SEO landing page for neighborhood delivery areas.
/// Route: /delivery/:area (e.g. /delivery/andheri, /delivery/bandra)
///
/// These pages target local search queries like:
/// "fruit delivery in Andheri", "fresh fruits Bandra", etc.
class DeliveryAreaScreen extends ConsumerWidget {
  final String area;

  const DeliveryAreaScreen({super.key, required this.area});

  // Internal area data lookup
  static const Map<String, _AreaInfo> _areas = {
    'andheri': _AreaInfo(
      name: 'Andheri',
      description: 'Get premium fresh fruits and dry fruits delivered to your doorstep in Andheri, Mumbai. Same-day delivery available for Andheri East and Andheri West.',
      pinCodes: ['400053', '400058', '400069', '400093'],
      landmarks: ['Andheri Station', 'Lokhandwala', 'Versova', 'Oshiwara', 'Four Bungalows'],
    ),
    'bandra': _AreaInfo(
      name: 'Bandra',
      description: 'Order fresh fruits and premium dry fruits online in Bandra, Mumbai. Fast delivery to Bandra West, Bandra East, BKC, and surrounding areas.',
      pinCodes: ['400050', '400051'],
      landmarks: ['Bandra Station', 'Linking Road', 'Hill Road', 'Carter Road', 'BKC'],
    ),
    'juhu': _AreaInfo(
      name: 'Juhu',
      description: 'Fresh fruit and dry fruit delivery in Juhu, Mumbai. Premium organic fruits delivered from farm to your table in Juhu, JVPD, and Vile Parle.',
      pinCodes: ['400049', '400056'],
      landmarks: ['Juhu Beach', 'JVPD Scheme', 'Mithibai College area'],
    ),
    'powai': _AreaInfo(
      name: 'Powai',
      description: 'Premium fruits and dry fruits delivered fresh in Powai, Mumbai. Same-day delivery near IIT Bombay, Hiranandani Gardens, and Powai Lake area.',
      pinCodes: ['400076'],
      landmarks: ['Hiranandani Gardens', 'IIT Bombay', 'Powai Lake', 'Chandivali'],
    ),
    'borivali': _AreaInfo(
      name: 'Borivali',
      description: 'Buy fresh fruits and dry fruits online in Borivali, Mumbai. Express delivery to Borivali West, Borivali East, IC Colony, and Dahisar.',
      pinCodes: ['400066', '400091', '400092'],
      landmarks: ['Borivali Station', 'IC Colony', 'Sanjay Gandhi National Park area'],
    ),
    'dadar': _AreaInfo(
      name: 'Dadar',
      description: 'Fresh fruits and premium dry fruits delivery in Dadar, Mumbai. Quality produce delivered fast to Dadar West, Dadar East, Prabhadevi, and Mahim.',
      pinCodes: ['400014', '400028'],
      landmarks: ['Dadar Station', 'Shivaji Park', 'Prabhadevi', 'Mahim'],
    ),
    'thane': _AreaInfo(
      name: 'Thane',
      description: 'Order fresh fruits and dry fruits online in Thane. Premium fruit delivery to Thane West, Thane East, Ghodbunder Road, and Majiwada.',
      pinCodes: ['400601', '400602', '400607', '400610'],
      landmarks: ['Thane Station', 'Viviana Mall', 'Ghodbunder Road', 'Majiwada'],
    ),
    'malad': _AreaInfo(
      name: 'Malad',
      description: 'Premium fresh fruits and dry fruits delivered to Malad, Mumbai. Fast delivery covering Malad West, Malad East, Goregaon, and Kandivali.',
      pinCodes: ['400064', '400095', '400097'],
      landmarks: ['Malad Station', 'Inorbit Mall', 'Mindspace', 'Marve Road'],
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaInfo = _areas[area.toLowerCase()];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 768;

    if (areaInfo == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Delivery area not found', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Title(
      title: 'Fresh Fruit Delivery in ${areaInfo.name}, Mumbai | BlissFruitz',
      color: AppTheme.primary,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: isDesktop ? 80 : 48,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.85),
                      const Color(0xFF0f5132),
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '📍 ${areaInfo.name.toUpperCase()}, MUMBAI',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Fresh Fruit Delivery\nin ${areaInfo.name}',
                          style: GoogleFonts.philosopher(
                            color: Colors.white,
                            fontSize: isDesktop ? 52 : 36,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          areaInfo.description,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: isDesktop ? 18 : 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => context.go('/shop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: Text(
                            'ORDER NOW →',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Service Details
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40 : 24,
                      vertical: 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What We Deliver in ${areaInfo.name}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _DeliveryFeature(
                              icon: Icons.eco_rounded,
                              title: 'Fresh Seasonal Fruits',
                              subtitle: 'Handpicked from organic farms',
                              isDark: isDark,
                            ),
                            _DeliveryFeature(
                              icon: Icons.grain_rounded,
                              title: 'Premium Dry Fruits',
                              subtitle: 'Almonds, cashews, pistachios & more',
                              isDark: isDark,
                            ),
                            _DeliveryFeature(
                              icon: Icons.local_shipping_rounded,
                              title: 'Same-Day Delivery',
                              subtitle: 'Order before 2 PM for today',
                              isDark: isDark,
                            ),
                            _DeliveryFeature(
                              icon: Icons.verified_user_rounded,
                              title: 'Freshness Guaranteed',
                              subtitle: 'Farm to ${areaInfo.name} in 24 hours',
                              isDark: isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Delivery Coverage
                        Text(
                          'Delivery Coverage in ${areaInfo.name}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We deliver to the following areas and pin codes in ${areaInfo.name}:',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Landmarks
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: areaInfo.landmarks.map((landmark) => Chip(
                            label: Text(landmark),
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            labelStyle: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Pin codes
                        Text(
                          'Serviceable Pin Codes: ${areaInfo.pinCodes.join(', ')}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // CTA
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Ready to Order?',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Browse our collection of fresh fruits and dry fruits',
                                style: GoogleFonts.beVietnamPro(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context.go('/shop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                ),
                                child: Text(
                                  'SHOP NOW',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Other Areas
                        Text(
                          'We Also Deliver To',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _areas.entries
                              .where((e) => e.key != area.toLowerCase())
                              .map((e) => ActionChip(
                                    label: Text(e.value.name),
                                    onPressed: () => context.go('/delivery/${e.key}'),
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: AppFooter()),
          ],
        ),
      ),
    );
  }
}

class _AreaInfo {
  final String name;
  final String description;
  final List<String> pinCodes;
  final List<String> landmarks;

  const _AreaInfo({
    required this.name,
    required this.description,
    required this.pinCodes,
    required this.landmarks,
  });
}

class _DeliveryFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _DeliveryFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
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
