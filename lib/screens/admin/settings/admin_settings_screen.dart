import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/settings_service.dart';
import '../components/admin_common_widgets.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _settingCategories = [
    {'id': 'general', 'label': 'General', 'icon': Icons.settings_rounded, 'table': 'settings_general'},
    {'id': 'payment', 'label': 'Payment', 'icon': Icons.payments_rounded, 'table': 'settings_payment'},
    {'id': 'shipping', 'label': 'Shipping', 'icon': Icons.local_shipping_rounded, 'table': 'settings_shipping'},
    {'id': 'catalog', 'label': 'Product Catalog', 'icon': Icons.inventory_2_rounded, 'table': 'settings_product_catalog'},
    {'id': 'coupons', 'label': 'Coupon Defaults', 'icon': Icons.confirmation_number_rounded, 'table': 'settings_coupon_defaults'},
    {'id': 'maintenance', 'label': 'Maintenance', 'icon': Icons.build_rounded, 'table': 'settings_maintenance'},
    {'id': 'ui_theme', 'label': 'UI Theme', 'icon': Icons.palette_rounded, 'table': 'settings_ui_theme'},
    {'id': 'security', 'label': 'Security', 'icon': Icons.security_rounded, 'table': 'settings_security'},
    {'id': 'analytics', 'label': 'Analytics', 'icon': Icons.analytics_rounded, 'table': 'settings_analytics'},
    {'id': 'app_update', 'label': 'App Updates', 'icon': Icons.system_update_rounded, 'table': 'settings_app_update'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _settingCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'System Settings',
              subtitle: 'Configure global application behavior and integrations',
            ),
            
            Expanded(
              child: isDesktop 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarNavigation(),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _settingCategories.map((cat) => _SettingsCategoryView(category: cat)).toList(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildTopNavigation(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _settingCategories.map((cat) => _SettingsCategoryView(category: cat)).toList(),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavigation() {
    return AdminGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      width: 240,
      child: Column(
        children: _settingCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isSelected = _tabController.index == index;

          return _SidebarNavItem(
            label: cat['label'],
            icon: cat['icon'],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _tabController.animateTo(index);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return AdminGlassCard(
      padding: EdgeInsets.zero,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        tabs: _settingCategories.map((cat) => Tab(
          text: cat['label'],
          icon: Icon(cat['icon'], size: 20),
        )).toList(),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppTheme.primary : Colors.grey),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCategoryView extends ConsumerStatefulWidget {
  final Map<String, dynamic> category;
  const _SettingsCategoryView({required this.category});

  @override
  ConsumerState<_SettingsCategoryView> createState() => _SettingsCategoryViewState();
}

class _SettingsCategoryViewState extends ConsumerState<_SettingsCategoryView> {
  Map<String, dynamic>? _formData;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await SettingsService.getSettings(widget.category['table']);
    setState(() {
      _formData = data;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    if (_formData == null) return;
    
    setState(() => _isSaving = true);
    try {
      await SettingsService.updateSettings(widget.category['table'], _formData!);
      
      // Invalidate relevant providers to sync changes
      ref.invalidate(generalSettingsProvider);
      ref.invalidate(paymentSettingsProvider);
      ref.invalidate(shippingSettingsProvider);
      ref.invalidate(maintenanceSettingsProvider);
      ref.invalidate(appUpdateSettingsProvider);
      ref.invalidate(productCatalogSettingsProvider);
      ref.invalidate(uiThemeSettingsProvider);
      ref.invalidate(securitySettingsProvider);
      ref.invalidate(analyticsSettingsProvider);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.category['label']} settings saved & synced successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_formData == null || _formData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No settings found for this category'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: AdminGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.category['label']} Configuration',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Reload from database',
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  ..._buildDynamicFormFields(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded),
                    const SizedBox(width: 12),
                    Text(
                      'SAVE & SYNC CHANGES',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicFormFields() {
    final List<Widget> fields = [];
    final keys = _formData!.keys.toList()
      ..remove('id')
      ..remove('updated_at')
      ..remove('created_at');

    for (final key in keys) {
      final value = _formData![key];
      final label = _formatKey(key);

      if (value is bool) {
        fields.add(_buildSwitchField(key, label, value));
      } else if (value is num) {
        fields.add(_buildTextField(key, label, value.toString(), isNumber: true));
      } else {
        fields.add(_buildTextField(key, label, value?.toString() ?? ''));
      }
      fields.add(const SizedBox(height: 20));
    }

    return fields;
  }

  String _formatKey(String key) {
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildSwitchField(String key, String label, bool value) {
    return SwitchListTile(
      title: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text('Enable or disable this feature', style: GoogleFonts.beVietnamPro(fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: (val) {
        setState(() {
          _formData![key] = val;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTextField(String key, String label, String value, {bool isNumber = false}) {
    // Specialized handling for secrets (optional improvement)
    final isSecret = key.contains('secret') || key.contains('key');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          obscureText: isSecret,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter $label',
            suffixIcon: isSecret ? const Icon(Icons.vpn_key_outlined, size: 18) : null,
          ),
          onChanged: (val) {
            if (isNumber) {
              _formData![key] = num.tryParse(val) ?? 0;
            } else {
              _formData![key] = val;
            }
          },
        ),
      ],
    );
  }
}
