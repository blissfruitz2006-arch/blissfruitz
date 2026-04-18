import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/admin/admin_image_picker.dart';
import '../../../providers/settings_provider.dart';
import '../components/admin_common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _configs = [
    {'title': 'General', 'icon': Icons.settings_rounded, 'table': 'settings_general'},
    {'title': 'Payment', 'icon': Icons.payment_rounded, 'table': 'settings_payment'},
    {'title': 'Shipping', 'icon': Icons.local_shipping_rounded, 'table': 'settings_shipping'},
    {'title': 'Coupons', 'icon': Icons.confirmation_number_rounded, 'table': 'settings_coupon_defaults'},
    {'title': 'Maintenance', 'icon': Icons.build_circle_rounded, 'table': 'settings_maintenance'},
    {'title': 'Sticker Settings', 'icon': Icons.label_important_rounded, 'table': 'settings_package_sticker'},
  ];

  final List<Map<String, dynamic>> _management = [
    {'title': 'Products', 'icon': Icons.inventory_2_rounded, 'route': '/admin/products'},
    {'title': 'Orders', 'icon': Icons.shopping_bag_rounded, 'route': '/admin/orders'},
    {'title': 'Banners', 'icon': Icons.view_carousel_rounded, 'route': '/admin/banners'},
    {'title': 'Offers & Deals', 'icon': Icons.local_offer_rounded, 'route': '/admin/offers'},
    {'title': 'Coupon Codes', 'icon': Icons.confirmation_number_rounded, 'route': '/admin/coupons'},
    {'title': 'Sticker Generator', 'icon': Icons.print_rounded, 'route': '/admin/sticker-generator'},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 1100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
      drawer: !isWide ? Drawer(
        child: _buildSidebar(isWide: true, inDrawer: true),
      ) : null,
      appBar: AppBar(
        title: Text(
          'Control Center', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: -0.5)
        ),
        leading: !isWide ? IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Row(
        children: [
          if (isWide) _buildSidebar(isWide: isWide),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SettingsGroupForm(
                  title: _configs[_selectedIndex]['title'],
                  table: _configs[_selectedIndex]['table'],
                  key: ValueKey(_configs[_selectedIndex]['table']),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isWide, bool inDrawer = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: isWide ? 280 : 80,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: isDark ? Colors.white10 : AppTheme.outlineVariant, width: 0.5)),
        color: isDark ? AppTheme.darkSurface : Colors.white,
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _buildSidebarSection('Configurations', _configs, isWide, inDrawer),
          const SizedBox(height: 32),
          _buildSidebarSection('Management', _management, isWide, inDrawer, isManagement: true),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Map<String, dynamic>> items, bool isWide, bool inDrawer, {bool isManagement = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWide)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final bool selected = !isManagement && _selectedIndex == index;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: InkWell(
              onTap: () {
                if (isManagement) {
                  context.go(item['route']);
                } else {
                  setState(() => _selectedIndex = index);
                  if (inDrawer) Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 0, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: isDark ? 0.2 : 1.0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: selected && isDark ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5)) : null,
                ),
                child: Row(
                  mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      size: 20,
                      color: selected 
                          ? (isDark ? AppTheme.primary : Colors.white) 
                          : (isDark ? Colors.white70 : AppTheme.onSurfaceVariant),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color: selected 
                                ? (isDark ? AppTheme.primary : Colors.white) 
                                : (isDark ? Colors.white70 : AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SettingsGroupForm extends ConsumerStatefulWidget {
  final String title;
  final String table;
  const SettingsGroupForm({super.key, required this.table, required this.title});

  @override
  ConsumerState<SettingsGroupForm> createState() => _SettingsGroupFormState();
}

class _SettingsGroupFormState extends ConsumerState<SettingsGroupForm> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final res = await AdminService.getSettings(widget.table);
      if (mounted) {
        setState(() {
          _data = Map<String, dynamic>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('SETTINGS LOAD ERROR (${widget.table}): $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading ${widget.title}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_data == null) return;
    setState(() => _isLoading = true);
    try {
      // Basic Validation
      if (_data!.containsKey('default_tax_rate_percent')) {
        final tax = double.tryParse(_data!['default_tax_rate_percent'].toString()) ?? 0;
        if (tax < 0 || tax > 100) throw 'Tax rate must be between 0 and 100';
      }

      await AdminService.updateSettings(widget.table, _data!);
      if (widget.table == 'settings_general') {
        ref.invalidate(generalSettingsProvider);
      }
      if (widget.table == 'settings_maintenance') {
        ref.invalidate(maintenanceSettingsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} saved successfully'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 64),
              const SizedBox(height: 16),
              Text('Failed to load ${widget.title}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loadData, 
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                child: const Text('Retry Connection')
              ),
            ],
          ),
        ),
      );
    }
    if (_data == null) return const Center(child: Text('Settings record not found (ID 1 required).'));

    final keys = _data!.keys.where((k) => k != 'id' && k != 'updated_at' && k != 'created_at').toList();

    return Column(
      children: [
        SectionHeader(
          title: widget.title,
          trailing: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppTheme.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: AdminGlassCard(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...keys.map((key) => _buildDynamicField(key, _data![key])),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicField(String key, dynamic value) {
    final label = key.replaceAll('_', ' ').toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Label Styling
    Widget fieldLabel = Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );

    // Filter sensitive fields
    bool isSensitive = key.contains('password') || key.contains('secret') || key.contains('token');
    if (isSensitive && value != null && value.toString().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant),
              ),
              child: Row(
                children: [
                   const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF10B981)),
                   const SizedBox(width: 12),
                   Text('SENSITIVE KEY CONFIGURED', style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w700)),
                   const Spacer(),
                   TextButton(
                     onPressed: () {
                        setState(() => _data![key] = '');
                     }, 
                     child: const Text('Reset'),
                   ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Imagery
    if (key == 'logo' || key == 'favicon' || key == 'pdf_logo_url') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel,
            AdminImagePicker(
              initialValue: value,
              folder: 'branding',
              onChanged: (url, bytes, name) async {
                if (bytes != null) {
                  final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$name';
                  final newUrl = await AdminService.uploadImageBytes('branding', uniqueName, bytes, 'image/png');
                  setState(() => _data![key] = newUrl);
                } else {
                  setState(() => _data![key] = url);
                }
              },
            ),
          ],
        ),
      );
    }

    // Color Picker
    if (key.contains('color')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: value?.toString() ?? '#000000',
                    decoration: InputDecoration(
                      hintText: '#HEXCODE',
                      fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                    ),
                    onChanged: (v) => setState(() => _data![key] = v),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _parseColor(value),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(value).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Toggles
    if (value is bool) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: SwitchListTile(
          title: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
          value: value,
          onChanged: (v) => setState(() => _data![key] = v),
          activeThumbColor: AppTheme.primary,
        ),
      );
    }

    // Dropdowns
    if (key == 'timezone' || key == 'language' || key == 'theme_mode') {
      List<String> options = [];
      if (key == 'timezone') options = ['Asia/Kolkata', 'UTC', 'America/New_York', 'Europe/London'];
      if (key == 'language') options = ['en', 'hi', 'fr', 'es'];
      if (key == 'theme_mode') options = ['light', 'dark', 'system'];

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel,
            DropdownButtonFormField<String>(
              initialValue: options.contains(value) ? value : options.first,
              decoration: InputDecoration(
                fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
              ),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _data![key] = v),
            ),
          ],
        ),
      );
    }

    // Default Fields
    bool isLargeField = key.contains('body') || key.contains('message') || key.contains('custom_css') || key.contains('custom_js') || key.contains('_text');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel,
          TextFormField(
            initialValue: value?.toString() ?? '',
            decoration: InputDecoration(
              alignLabelWithHint: true,
              fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
            ),
            style: GoogleFonts.beVietnamPro(fontSize: 14),
            maxLines: isLargeField ? 6 : 1,
            keyboardType: (value is num) ? TextInputType.number : TextInputType.text,
            onChanged: (v) {
              if (value is num) {
                _data![key] = num.tryParse(v) ?? value;
              } else {
                _data![key] = v;
              }
            },
          ),
        ],
      ),
    );
  }

  Color _parseColor(dynamic hex) {
    if (hex == null || hex.toString().isEmpty) return Colors.black;
    String cleanHex = hex.toString().replaceAll('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
    try {
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }
}

