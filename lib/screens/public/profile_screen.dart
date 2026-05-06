import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProfileProvider);
    final user = userState.valueOrNull;

    if (!ref.watch(isLoggedInProvider)) {
      Future.microtask(() {
        if (context.mounted) {
          context.go('/login');
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // ─── PROFILE HEADER ───
          _buildProfileHeader(context, user),
          const SizedBox(height: 24),

          // ─── REWARDS CARD ───
          _buildRewardsCard(context),
          const SizedBox(height: 24),

          // ─── STATS ROW ───
          _buildStatsRow(),
          const SizedBox(height: 12),

          // ─── MENU ITEMS ───
          _buildSectionHeader(context, 'Account Settings'),
          _buildMenuItems(context, ref),

          // ─── ADMIN TOOLS ───
          if (ref.watch(isAdminProvider)) ...[
            const SizedBox(height: 12),
            _buildSectionHeader(context, 'Administrator'),
            _buildAdminMenu(context),
          ],

          // ─── RIDER TOOLS ───
          if (ref.watch(isRiderProvider)) ...[
            const SizedBox(height: 12),
            _buildSectionHeader(context, 'Rider Dashboard'),
            _buildRiderMenu(context),
          ],

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              image: user?.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user!.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: user?.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Fresh Fruiter',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (user?.email != null) ...[
            Text(
              user!.email!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              '',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context) {
    return const SizedBox.shrink(); // Rewards removed to match live simple profile
  }

  Widget _buildStatsRow() {
    return const SizedBox.shrink(); // Stats row removed to match simple profile
  }

  Widget _buildAdminMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: _buildMenuItem(
              context,
              Icons.dashboard_customize_outlined,
              'Admin Dashboard',
              iconColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.go('/rider/home'),
            child: _buildMenuItem(
              context,
              Icons.delivery_dining_outlined,
              'Rider Console',
              iconColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: _buildMenuItem(
              context,
              Icons.settings_outlined,
              'App Settings',
              iconColor: AppTheme.primary,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/order-history'),
            child: _buildMenuItem(
              context,
              Icons.shopping_bag_outlined,
              'My Orders',
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/addresses'),
            child: _buildMenuItem(
              context,
              Icons.location_on_outlined,
              'Addresses',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await ref.read(userProfileProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: _buildMenuItem(
              context,
              Icons.logout,
              'Sign Out',
              iconColor: AppTheme.error,
              textColor: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label, {
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

