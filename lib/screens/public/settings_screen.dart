import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/contact_service.dart';


class PublicSettingsScreen extends ConsumerStatefulWidget {
  const PublicSettingsScreen({super.key});

  @override
  ConsumerState<PublicSettingsScreen> createState() => _PublicSettingsScreenState();
}

class _PublicSettingsScreenState extends ConsumerState<PublicSettingsScreen> {
  String _selectedLanguage = 'English (US)';

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is currently under development and will be available in a future update. Stay tuned!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = ['English (US)', 'Hindi', 'Spanish', 'French', 'German'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            title: Text(lang),
            trailing: _selectedLanguage == lang ? const Icon(Icons.check, color: AppTheme.primary) : null,
            onTap: () {
              setState(() => _selectedLanguage = lang);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to $lang (Simulation)')),
              );
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, dynamic user) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the issue you are facing...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await ContactService.submitMessage(
                name: user?.fullName ?? 'User',
                email: user?.email ?? 'anonymous',
                subject: 'App Problem Report',
                message: controller.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Our team will look into it!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: const Text('Your account will be disabled. You can reactivate it anytime by logging back in within 30 days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Account')),
          TextButton(
            onPressed: () async {
              await ref.read(userProfileProvider.notifier).deactivateAccount();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deactivated successfully.')),
                );
              }
            },
            child: const Text('Deactivate', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;

    return Title(
      title: 'Settings | Blissfruitz',
      color: AppTheme.primary,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // 👤 Account & Profile
            _buildSectionHeader('Account & Profile'),
            _buildSettingTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              subtitle: user?.fullName ?? 'Manage your info',
              onTap: () => context.push('/settings/edit-profile'),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              onTap: () => context.push('/settings/change-password'),
            ),
            _buildSettingTile(
              icon: Icons.share_rounded,
              title: 'Linked Accounts',
              subtitle: 'Google, Email',
              onTap: () => _showComingSoon(context, 'Linked Accounts'),
            ),
            _buildSettingTile(
              icon: Icons.no_accounts_outlined,
              title: 'Deactivate Account',
              iconColor: AppTheme.error,
              onTap: () => _showDeactivateDialog(context),
            ),

            const SizedBox(height: 24),

            // 🌐 App Preferences
            _buildSectionHeader('App Preferences'),
            _buildSettingTile(
              icon: themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              title: 'Appearance',
              subtitle: themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
              trailing: Switch.adaptive(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                activeThumbColor: AppTheme.primary,
              ),
            ),
            _buildSettingTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: _selectedLanguage,
              onTap: () => _showLanguageDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.public_rounded,
              title: 'Region',
              subtitle: 'India',
              onTap: () => _showComingSoon(context, 'Region'),
            ),
            _buildSettingTile(
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility',
              onTap: () => _showComingSoon(context, 'Accessibility'),
            ),

            const SizedBox(height: 24),

            // 🤝 Help & Support
            _buildSectionHeader('Help & Support'),
            _buildSettingTile(
              icon: Icons.help_outline_rounded,
              title: 'FAQ / Help Center',
              onTap: () => context.push('/settings/faq'),
            ),
            _buildSettingTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live Chat',
              subtitle: 'AI Chat Coming Soon',
              onTap: () => _showComingSoon(context, 'AI Assistant Chat'),
            ),
            _buildSettingTile(
              icon: Icons.report_problem_outlined,
              title: 'Report a Problem',
              onTap: () => _showReportDialog(context, user),
            ),
            _buildSettingTile(
              icon: Icons.star_outline_rounded,
              title: 'Rate the App',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you! Redirecting to App Store... (coming soon)')),
                );
              },
            ),

            const SizedBox(height: 24),

            // 📜 Legal
            _buildSectionHeader('Legal'),
            _buildSettingTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () => context.push('/terms'),
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push('/privacy'),
            ),
            _buildSettingTile(
              icon: Icons.assignment_return_outlined,
              title: 'Return & Refund Policy',
              onTap: () => context.push('/returns'),
            ),

            const SizedBox(height: 32),

            // 🚪 Account Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActionButton(
                label: 'Log Out',
                onTap: () async {
                  await ref.read(userProfileProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                color: AppTheme.error,
              ),
            ),

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(fontSize: 12),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

