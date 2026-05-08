import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../config/theme.dart';
import '../config/flavor_config.dart';
import '../screens/public/chat_screen.dart';

class GlobalChatToggle extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const GlobalChatToggle({
    super.key,
    required this.child,
    required this.router,
  });

  @override
  State<GlobalChatToggle> createState() => _GlobalChatToggleState();
}

class _GlobalChatToggleState extends State<GlobalChatToggle> {
  bool _showPopup = false;

  @override
  Widget build(BuildContext context) {
    // Only show for Customer App
    if (FlavorConfig.isRider) return widget.child;

    // Hide the floating button on mobile-sized screens (width < 700)
    // On mobile, users access chat via the Profile page.
    final isLargeScreen = MediaQuery.of(context).size.width > 700;

    return Stack(
      children: [
        widget.child,
        // Persistent Toggle / Popup for PC
        if (isLargeScreen)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                // The actual Chat Window Popup
                if (_showPopup)
                  Positioned(
                    right: 24,
                    bottom: 90, // Above the FAB
                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: 400,
                        height: 600,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                          maxWidth: 400,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header for the popup
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: AppTheme.primary,
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'BlissFruitz AI Support',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    onPressed: () => setState(() => _showPopup = false),
                                  ),
                                ],
                              ),
                            ),
                            // The Chat Screen content
                            Expanded(
                              child: Navigator(
                                onGenerateRoute: (settings) => MaterialPageRoute(
                                  builder: (context) => const ChatScreen(isEmbedded: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // The Floating Action Button Toggle
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () => setState(() => _showPopup = !_showPopup),
                    backgroundColor: _showPopup ? Colors.white : AppTheme.primary,
                    foregroundColor: _showPopup ? AppTheme.primary : Colors.white,
                    elevation: 4,
                    icon: Icon(_showPopup ? Icons.close_rounded : Icons.auto_awesome_rounded),
                    label: Text(_showPopup ? 'Close Chat' : 'Chat with AI'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
