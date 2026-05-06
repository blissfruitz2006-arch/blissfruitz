import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'mobile_bottom_nav.dart';
import 'navbar.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const ResponsiveScaffold({
    super.key, 
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final showBottomNav = isMobile;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(85 + MediaQuery.paddingOf(context).top),
          child: AppNavbar(state: state),
        ),
        body: child,
        bottomNavigationBar: showBottomNav ? MobileBottomNav(state: state) : null,
      ),
    );
  }
}

