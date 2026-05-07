import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MobileBottomNav extends ConsumerWidget {
  final GoRouterState state;
  const MobileBottomNav({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = state.uri.toString();
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isRider = ref.watch(isRiderProvider);
    
    int currentIndex = 0;
    if (isRider) {
      if (location.startsWith('/rider/home')) {
        currentIndex = 0;
      } else if (location.startsWith('/rider/order')) {
        currentIndex = 1; // Highlight Deliveries when viewing an order
      } else if (location.startsWith('/rider/earnings')) {
        currentIndex = 2;
      } else if (location.startsWith('/rider/profile')) {
        currentIndex = 3;
      }
    } else {
      if (location == '/' || location.startsWith('/home')) {
        currentIndex = 0;
      } else if (location.startsWith('/shop')) {
        currentIndex = 1;
      } else if (location.startsWith('/cart')) {
        currentIndex = 2;
      } else if (location.startsWith('/profile') ||
          location.startsWith('/login') ||
          location.startsWith('/register')) {
        currentIndex = 3;
      }
    }

    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: isRider ? 'Dashboard' : 'Home',
        isActive: currentIndex == 0,
      ),
      isRider 
        ? _NavItem(
            icon: Icons.delivery_dining_outlined,
            activeIcon: Icons.delivery_dining,
            label: 'Deliveries',
            isActive: currentIndex == 1,
          )
        : _NavItem(
            icon: Icons.shopping_basket_outlined,
            activeIcon: Icons.shopping_basket,
            label: 'Shop',
            isActive: currentIndex == 1,
          ),
      isRider
        ? _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Earnings',
            isActive: currentIndex == 2,
          )
        : _NavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Cart',
            isActive: currentIndex == 2,
          ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Account',
        isActive: currentIndex == 3,
      ),
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 4,
        top: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 280 ? 8 : (screenWidth < 350 ? 12 : 16),
          vertical: screenWidth < 280 ? 2 : 4,
        ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildNavItem(context, ref, item, index, currentIndex);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    _NavItem item,
    int index,
    int currentIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRider = ref.watch(isRiderProvider);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          
          final routes = isRider 
            ? ['/rider/home', '/rider/home', '/rider/earnings', '/rider/profile']
            : ['/', '/shop', '/cart', '/profile'];
          
          if (index == 3 && !state.uri.toString().contains('login')) {
            final isLoggedIn = AuthService.isLoggedIn;
            if (!isLoggedIn) {
              context.push('/login');
              return;
            }
          }
          context.go(routes[index]);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: item.isActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    item.isActive ? item.activeIcon : item.icon,
                    size: MediaQuery.sizeOf(context).width < 280 ? 20 : 26,
                    color: item.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: GoogleFonts.outfit(
                    fontSize: MediaQuery.sizeOf(context).width < 280 ? 9 : 10,
                    fontWeight: item.isActive ? FontWeight.w800 : FontWeight.w600,
                    color: item.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
  });
}
