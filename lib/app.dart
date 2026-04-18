import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/theme_provider.dart';

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'package:flutter/services.dart';
import 'services/update_service.dart';

class BlissFruitzApp extends ConsumerStatefulWidget {
  const BlissFruitzApp({super.key});

  @override
  ConsumerState<BlissFruitzApp> createState() => _BlissFruitzAppState();
}

class _BlissFruitzAppState extends ConsumerState<BlissFruitzApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    
    // Check for Android In-App Updates
    UpdateService.checkForUpdate();

    _authSubscription = AuthService.onAuthStateChange.listen((data) {
      debugPrint('Auth State Change Event: ${data.event}');
      
      if (data.event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Password recovery mode detected! Navigating to change password screen...');
        // Navigation often needs a small delay on web to allow the initial 
        // GoRouter lifecycle to complete before we force a redirect.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(routerProvider).go('/settings/change-password');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            View.of(context).platformDispatcher.platformBrightness == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: MaterialApp.router(
        title: 'BlissFruitz — Premium Fresh Fruits',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
