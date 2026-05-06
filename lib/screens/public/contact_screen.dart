import 'package:flutter/material.dart';
import '../../services/contact_service.dart';
import '../../config/theme.dart';
import '../../widgets/footer.dart';
import '../../widgets/glass_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ContactService.submitMessage(
        name: _nameController.text,
        email: _emailController.text,
        subject: _subjectController.text,
        message: _messageController.text,
      );
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final settingsAsync = ref.watch(generalSettingsProvider);
    final isDesktop = screenWidth > 900;

    return CustomScrollView(
      slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Text(
                      'GET IN TOUCH',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'d Love to Help You',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: screenWidth > 640 ? 48 : (screenWidth < 280 ? 24 : 32),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        'Have questions about our products or premium dry fruits? Our team is here to provide you with a blissful experience.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _sent ? _buildSuccess() : _buildForm()),
                        const SizedBox(width: 60),
                        Expanded(flex: 2, child: _buildContactInfo(settingsAsync)),
                      ],
                    )
                  : Column(
                      children: [
                        _sent ? _buildSuccess() : _buildForm(),
                        const SizedBox(height: 48),
                        _buildContactInfo(settingsAsync),
                      ],
                    ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: AppFooter()),
      ],
    );
  }

  Widget _buildContactInfo(AsyncValue settingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          icon: Icons.mail_outline_rounded,
          title: 'Email Us',
          content: settingsAsync.maybeWhen(
            data: (s) => s.email ?? 'support@blissfruitz.com',
            orElse: () => 'support@blissfruitz.com',
          ),
          subtitle: 'Our support team responds within 24 hours.',
        ),
        const SizedBox(height: 24),
        _infoCard(
          icon: Icons.phone_outlined,
          title: 'Call Us',
          content: settingsAsync.maybeWhen(
            data: (s) => s.phone ?? '+91 86559 58384',
            orElse: () => '+91 86559 58384',
          ),
          subtitle: 'Mon-Sun, 9am to 9pm IST',
        ),
        const SizedBox(height: 24),
        _infoCard(
          icon: Icons.location_on_outlined,
          title: 'Visit Us',
          content: settingsAsync.maybeWhen(
            data: (s) => s.address ?? '45 Orchard Avenue, Mumbai, MH',
            orElse: () => '45 Orchard Avenue, Mumbai, MH',
          ),
          subtitle: 'Premium fruit outlet & pickup point.',
        ),
      ],
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String content, required String subtitle}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTiny = screenWidth < 280;
    
    return Container(
      padding: EdgeInsets.all(isTiny ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTiny ? 8 : 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: isTiny ? 20 : 24),
          ),
          SizedBox(width: isTiny ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: isTiny ? 16 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Message Sent!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for reaching out. We\'ll get back to you soon.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTiny = screenWidth < 280;
    
    return GlassCard(
      padding: EdgeInsets.all(isTiny ? 20 : 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a Message',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildLabel('Full Name'),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'e.g. John Doe',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Email Address'),
            TextFormField(
              controller: _emailController,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'e.g. john@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Subject'),
            TextFormField(
              controller: _subjectController,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'What is this regarding?',
                prefixIcon: Icon(Icons.subject_rounded, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Your Message'),
            TextFormField(
              controller: _messageController,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'How can we help you?',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'Message is required' : null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

