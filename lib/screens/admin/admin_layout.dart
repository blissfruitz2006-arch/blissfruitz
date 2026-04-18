import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    
    // Security: Only allow admins
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: !isDesktop ? _buildSidebar(context, ref, isMobile: true) : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, ref),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, {bool isMobile = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
              ? [AppTheme.darkSurfaceContainerLowest, Colors.black] 
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BlissFruitz',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Admin Console',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarSection(context, 'MAIN DASHBOARD', [
                  _SidebarItem(
                    icon: Icons.grid_view_rounded, 
                    label: 'Overview', 
                    isActive: GoRouterState.of(context).matchedLocation == '/admin/dashboard' || GoRouterState.of(context).matchedLocation == '/admin', 
                    onTap: () => context.goNamed('admin-dashboard'),
                  ),
                  _SidebarItem(
                    icon: Icons.analytics_rounded, 
                    label: 'Sales Analytics', 
                    isActive: GoRouterState.of(context).matchedLocation.contains('/analytics'),
                    onTap: () => context.goNamed('admin-analytics'),
                  ),
                ]),
                _buildSidebarSection(context, 'OPERATIONS', [
                  _SidebarItem(
                    icon: Icons.shopping_bag_rounded, 
                    label: 'Orders', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/orders'),
                    onTap: () => context.goNamed('admin-orders'),
                  ),
                  _SidebarItem(
                    icon: Icons.inventory_2_rounded, 
                    label: 'Products', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/products'),
                    onTap: () => context.goNamed('admin-products'),
                  ),
                  _SidebarItem(
                    icon: Icons.people_rounded, 
                    label: 'Customers', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/customers'),
                    onTap: () => context.goNamed('admin-customers'),
                  ),
                  _SidebarItem(
                    icon: Icons.delivery_dining_rounded, 
                    label: 'Delivery Riders', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/riders'),
                    onTap: () => context.push('/admin/riders'),
                  ),
                  _SidebarItem(
                    icon: Icons.print_rounded, 
                    label: 'Sticker Generator', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/sticker-generator'),
                    onTap: () => context.goNamed('admin-sticker-generator'),
                  ),
                ]),
                _buildSidebarSection(context, 'STOREFRONT', [
                  _SidebarItem(
                    icon: Icons.brush_rounded, 
                    label: 'Banners', 
                    isActive: GoRouterState.of(context).matchedLocation.contains('/banners'),
                    onTap: () => context.goNamed('admin-banners'),
                  ),
                  _SidebarItem(
                    icon: Icons.article_rounded, 
                    label: 'Blog Posts', 
                    isActive: GoRouterState.of(context).matchedLocation.contains('/blogs'),
                    onTap: () => context.goNamed('admin-blogs'),
                  ),
                  _SidebarItem(
                    icon: Icons.confirmation_number_rounded, 
                    label: 'Coupons', 
                    isActive: GoRouterState.of(context).matchedLocation.contains('/coupons'),
                    onTap: () => context.goNamed('admin-coupons'),
                  ),
                ]),
                _buildSidebarSection(context, 'SYSTEM', [
                  _SidebarItem(
                    icon: Icons.settings_rounded, 
                    label: 'Store Settings', 
                    isActive: GoRouterState.of(context).matchedLocation.startsWith('/admin/settings'),
                    onTap: () => context.goNamed('admin-settings'),
                  ),
                ]),
              ],
            ),
          ),

          _buildSidebarUserSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildSidebarUserSection(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProfileProvider).valueOrNull;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4), 
                width: 1.5
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                (user?.fullName ?? 'A')[0].toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.fullName ?? 'Admin User',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.role.toUpperCase() ?? 'SUPER ADMIN',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                Icons.power_settings_new_rounded, 
                size: 18, 
                color: Colors.red.withValues(alpha: 0.7)
              ),
              onPressed: () => ref.read(userProfileProvider.notifier).signOut(),
              style: IconButton.styleFrom(
                hoverColor: Colors.red.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSidebarSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 24, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive 
                    ? AppTheme.primary 
                    : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive 
                      ? (isDark ? Colors.white : AppTheme.primary)
                      : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
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
