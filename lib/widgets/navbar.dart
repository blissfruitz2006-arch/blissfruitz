import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../models/user_profile.dart';
import 'app_image.dart';

class AppNavbar extends ConsumerWidget implements PreferredSizeWidget {
  final GoRouterState state;
  const AppNavbar({super.key, required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(85);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final generalSettings = ref.watch(generalSettingsProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentPath = state.uri.path;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Container(
      height: 85 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.98 : 0.95),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 40 : (screenWidth < 350 ? 12 : 20), 
          8, 
          isDesktop ? 40 : (screenWidth < 350 ? 12 : 20), 
          8
        ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  // --- Brand / Logo ---
                  GestureDetector(
                    onTap: () {
                      if (userProfile?.role == 'rider') {
                        context.go('/rider/home');
                      } else if (userProfile?.role == 'admin') {
                        context.go('/admin/dashboard');
                      } else {
                        context.go('/');
                      }
                    },
                    child: generalSettings.when(
                      data: (settings) => Hero(
                        tag: 'app_logo',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settings.logo != null && settings.logo!.isNotEmpty) ...[
                              SizedBox(
                                height: 36, // Slightly larger for impact
                                child: AppImage(
                                  path: settings.logo,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ShaderMask(
                              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                              child: Text(
                                settings.siteName ?? 'BlissFruitz',
                                style: GoogleFonts.philosopher(
                                  fontSize: isDesktop ? 32 : (screenWidth < 280 ? 18 : (screenWidth < 350 ? 22 : 28)),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white, // Color is provided by ShaderMask
                                  letterSpacing: -0.5,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => _LogoTextPlaceholder(isDesktop: isDesktop),
                      error: (_, _) => _LogoTextPlaceholder(isDesktop: isDesktop),
                    ),
                  ),

                  if (!isMobile && userProfile?.role != 'rider') ...[
                    const SizedBox(width: 48),
                    // --- Desktop Navigation Links ---
                    _DesktopNavLink(
                      label: 'Home',
                      active: currentPath == '/' || currentPath == '/home',
                      onTap: () => context.go('/'),
                    ),
                    _DesktopNavLink(
                      label: 'Shop',
                      active: currentPath.startsWith('/shop'),
                      onTap: () => context.go('/shop'),
                    ),
                    _DesktopNavLink(
                      label: 'Contact',
                      active: currentPath == '/contact',
                      onTap: () => context.go('/contact'),
                    ),
                  ],

                  if (!isMobile && userProfile?.role == 'rider') ...[
                    const SizedBox(width: 48),
                    // --- Desktop Rider Links ---
                    _DesktopNavLink(
                      label: 'Dashboard',
                      active: currentPath == '/rider/home',
                      onTap: () => context.go('/rider/home'),
                    ),
                    _DesktopNavLink(
                      label: 'Earnings',
                      active: currentPath == '/rider/earnings',
                      onTap: () => context.go('/rider/earnings'),
                    ),
                  ],

                  const Spacer(),

                  // --- Search Bar (Desktop/Tablet) ---
                  if (isDesktop || isTablet)
                    Container(
                      width: isDesktop ? 280 : 200,
                      height: 42,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: TextField(
                        onSubmitted: (value) {
                          if (value.isNotEmpty) context.go('/shop?search=$value');
                        },
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search fresh fruits...',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),

                  // --- Actions Row ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMobile && userProfile?.role != 'rider') ...[
                        // Cart
                        _NavbarIconButton(
                          icon: Icons.shopping_basket_outlined,
                          onPressed: () => context.go('/cart'),
                          badgeCount: cart.totalItems,
                          tooltip: 'Cart',
                        ),
                        
                        const SizedBox(width: 4),
                      ],

                      // Theme Toggle
                      _NavbarIconButton(
                        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                        tooltip: 'Toggle Theme',
                      ),

                      if (!isMobile) ...[
                        const SizedBox(width: 12),

                        // Account
                        if (isLoggedIn)
                          _ProfileDropdown(userProfile: userProfile)
                        else
                          _LoginButton(isDesktop: isDesktop),
                      ],
                    ],
                  ),
                ],
              ),
          ),
      );
  }
}

class _NavbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;
  final String tooltip;

  const _NavbarIconButton({
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Badge(
        isLabelVisible: badgeCount > 0,
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppTheme.tertiary,
        child: Icon(icon, size: 22, color: colorScheme.onSurface),
      ),
      style: IconButton.styleFrom(
        hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      ),
    );
  }
}

class _LogoTextPlaceholder extends StatelessWidget {
  final bool isDesktop;
  const _LogoTextPlaceholder({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ],
      ).createShader(bounds),
      child: Text(
        'BlissFruitz',
        style: GoogleFonts.philosopher(
          fontSize: isDesktop ? 28 : 24,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _DesktopNavLink extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DesktopNavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_DesktopNavLink> createState() => _DesktopNavLinkState();
}

class _DesktopNavLinkState extends State<_DesktopNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: widget.active
                  ? colorScheme.primary
                  : _isHovered
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              boxShadow: widget.active 
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
            ),
            child: Text(
              widget.label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
                color: widget.active 
                  ? colorScheme.onPrimary 
                  : _isHovered 
                      ? colorScheme.primary 
                      : colorScheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isDesktop;
  const _LoginButton({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go('/login'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.5,
          ),
          color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded, 
              size: 18, 
              color: colorScheme.primary,
            ),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Text(
                'Login',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _ProfileDropdown extends ConsumerWidget {
  final UserProfile? userProfile;
  const _ProfileDropdown({this.userProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final isRider = ref.watch(isRiderProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary.withValues(alpha: 0.1),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          child: userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: AppImage(path: userProfile!.avatarUrl, fit: BoxFit.cover),
                )
              : const Icon(Icons.person_rounded, size: 20, color: AppTheme.primary),
        ),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await AuthService.signOut();
          if (context.mounted) context.go('/');
        } else {
          context.go(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProfile?.fullName ?? 'Valued Customer',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                userProfile?.email ?? '',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
            ],
          ),
        ),
        _buildPopupItem(context, Icons.person_outline, 'My Profile', '/profile'),
        if (isAdmin)
          _buildPopupItem(
            context,
            Icons.admin_panel_settings_outlined,
            'Admin Panel',
            '/admin',
            color: AppTheme.primary,
          ),
        if (isRider)
          _buildPopupItem(
            context,
            Icons.delivery_dining_outlined,
            'Rider Dashboard',
            '/rider/home',
            color: AppTheme.primary,
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: AppTheme.tertiary),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
