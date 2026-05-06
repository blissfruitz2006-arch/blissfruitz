import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../providers/rider_provider.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final riderAsync = ref.watch(riderProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: riderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rider) {
          if (rider == null) return const Center(child: Text('No profile found'));
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (rider.fullName.isNotEmpty) ? rider.fullName[0].toUpperCase() : 'R',
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  rider.fullName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Center(
                child: Text(
                  rider.phone ?? 'No phone',
                  style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  _stat('Deliveries', '${rider.totalDeliveries}', Icons.local_shipping_rounded, isDark, cs),
                  const SizedBox(width: 16),
                  _stat('Earned', '₹${rider.totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, isDark, cs),
                ],
              ),
              
              const SizedBox(height: 32),
              
              _infoTile('Vehicle Type', rider.vehicleType ?? 'Not set', Icons.two_wheeler_rounded, cs),
              _infoTile('Assigned Zone', rider.zone ?? 'Not set', Icons.map_outlined, cs),
              _infoTile('Member Since', rider.createdAt != null ? '${rider.createdAt!.day}/${rider.createdAt!.month}/${rider.createdAt!.year}' : 'N/A', Icons.calendar_today_rounded, cs),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String val, IconData ic, bool isDark, ColorScheme cs) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(ic, color: cs.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );

  Widget _infoTile(String label, String val, IconData ic, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ic, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    ),
  );
}

