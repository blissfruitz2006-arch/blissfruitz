import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/flavor_config.dart';
import 'config/theme_customer.dart';
import 'config/theme_rider.dart';
import 'config/routes.dart';
import 'config/router_rider.dart';
import 'providers/theme_provider.dart';

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'package:flutter/services.dart';
import 'services/update_service.dart';
import 'package:blissfruitz/services/initialization_service.dart';
import 'package:blissfruitz/config/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/double_back_exit_wrapper.dart';
import 'widgets/global_chat_toggle.dart';

class BlissFruitzApp extends ConsumerStatefulWidget {
  const BlissFruitzApp({super.key});

  @override
  ConsumerState<BlissFruitzApp> createState() => _BlissFruitzAppState();
}

class _BlissFruitzAppState extends ConsumerState<BlissFruitzApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  String? _error;
  String _loadingMessage = 'Booting up...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingMessage = 'Initializing services...';
        _error = null;
      });
      await InitializationService.initialize();
      
      setState(() => _loadingMessage = 'Checking for updates...');
      // Check for Android In-App Updates
      UpdateService.checkForUpdate();

      setState(() => _loadingMessage = 'Connecting to gateway...');
      _authSubscription = AuthService.onAuthStateChange.listen((data) {
        debugPrint('Auth State Change Event: ${data.event}');
        
        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('Password recovery mode detected! Navigating to change password screen...');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final activeRouter = FlavorConfig.isRider ? ref.read(riderRouterProvider) : ref.read(routerProvider);
              activeRouter.go('/settings/change-password');
            }
          });
        }
      });

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('Fatal initialization error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingMessage = 'Initialization failed';
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    // Determine which theme to use based on flavor
    final lightTheme = FlavorConfig.isRider ? riderLightTheme : customerLightTheme;
    final darkTheme = FlavorConfig.isRider ? riderDarkTheme : customerDarkTheme;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _error != null ? AppTheme.error : AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _error != null ? Icons.error_outline_rounded : Icons.shopping_bag_rounded, 
                    color: Colors.white, 
                    size: 60
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'BlissFruitz',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _error != null ? AppTheme.error : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error == null)
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'Something went wrong during startup.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initializeApp,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (_error == null)
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final router = FlavorConfig.isRider ? ref.watch(riderRouterProvider) : ref.watch(routerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: MaterialApp.router(
        title: FlavorConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return GlobalChatToggle(
            router: router,
            child: DoubleBackExitWrapper(
              enabled: !kIsWeb,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
