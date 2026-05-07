import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleBackExitWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DoubleBackExitWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<DoubleBackExitWrapper> createState() => _DoubleBackExitWrapperState();
}

class _DoubleBackExitWrapperState extends State<DoubleBackExitWrapper> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(
                bottom: 100, // Show above bottom nav
                left: 50,
                right: 50,
              ),
            ),
          );
          return;
        }

        // Second press within 2 seconds, exit the app
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: widget.child,
    );
  }
}
