import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass_card.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceSettingsProvider);
    final maintenanceMessage = maintenanceAsync.valueOrNull?.message ?? 
        'We are currently performing scheduled maintenance to improve our services. We will be back online shortly.';

    return Scaffold(
      body: Stack(
        children: [
          // Elegant Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  Colors.white,
                  const Color(0xFFFFF9F0),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          
          // Subtle Decorative Shapes
          Positioned(
            top: -100,
            right: -50,
            child: _DecorativeCircle(size: 300, color: AppTheme.primary.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _DecorativeCircle(size: 400, color: AppTheme.primary.withValues(alpha: 0.02)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                padding: const EdgeInsets.all(40),
                borderRadius: BorderRadius.circular(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 72,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Text(
                      'Pardon Our Dust',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'UPGRADING YOUR EXPERIENCE',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary.withValues(alpha: 0.6),
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      maintenanceMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 17,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Action Row
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(maintenanceSettingsProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'CHECK STATUS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Link to contact or twitter
                          },
                          child: Text(
                            'Contact Support',
                            style: TextStyle(
                              color: AppTheme.primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

