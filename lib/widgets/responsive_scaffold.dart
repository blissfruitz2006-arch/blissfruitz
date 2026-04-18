import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'mobile_bottom_nav.dart';
import 'navbar.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isNativeApp = !kIsWeb;
    final showBottomNav = isNativeApp || isMobile;

    final currentPath = GoRouterState.of(context).uri.path;
    // We check if the current navigator (shell navigator) can pop.
    // This allows sub-pages pushed with context.push() to work naturally.
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      // We allow system pop if there's a history stack OR if we're already at home.
      // Otherwise, we intercept to handle the redirection.
      canPop: canPop || currentPath == '/',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If we didn't pop (meaning no history) and we are not on home,
        // we redirect the user to the home screen.
        if (currentPath != '/') {
          context.go('/');
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(85 + MediaQuery.paddingOf(context).top),
          child: const AppNavbar(),
        ),
        body: child,
        bottomNavigationBar: showBottomNav ? const MobileBottomNav() : null,
      ),
    );
  }
}

