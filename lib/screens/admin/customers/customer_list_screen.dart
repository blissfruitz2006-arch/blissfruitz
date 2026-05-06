import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../components/admin_common_widgets.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(filteredAdminCustomersProvider);
    final allCustomersAsync = ref.watch(adminCustomersProvider);
    final currentFilter = ref.watch(customerRoleFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 24, top: 48),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Manager',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage user roles, monitor status, and view insights',
                      style: GoogleFonts.beVietnamPro(
                        color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  ref.invalidate(adminCustomersProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Database',
              ),
              const SizedBox(width: 16),
            ],
          ),

          // Search & Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Statistics Row
                  allCustomersAsync.when(
                    data: (customers) {
                      final total = customers.length;
                      final admins = customers.where((c) => c['role'] == 'admin').length;
                      final blocked = customers.where((c) => c['isActive'] == false).length;
                      
                      return Row(
                        children: [
                          _buildMiniStat('TOTAL USERS', total.toString(), AppTheme.primary, isDark),
                          const SizedBox(width: 16),
                          _buildMiniStat('ADMINS', admins.toString(), AppTheme.tertiary, isDark),
                          const SizedBox(width: 16),
                          _buildMiniStat('BLOCKED', blocked.toString(), Colors.redAccent, isDark),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 60),
                    error: (_, _) => const SizedBox(),
                  ),
                  const SizedBox(height: 32),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val,
                      style: GoogleFonts.beVietnamPro(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.outlineVariant, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter & Sort Row
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'All Users',
                                isSelected: currentFilter == null,
                                onSelected: () => ref.read(customerRoleFilterProvider.notifier).state = null,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _FilterChip(
                                label: 'Admins',
                                isSelected: currentFilter == 'admin',
                                onSelected: () => ref.read(customerRoleFilterProvider.notifier).state = 'admin',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _FilterChip(
                                label: 'Customers',
                                isSelected: currentFilter == 'customer',
                                onSelected: () => ref.read(customerRoleFilterProvider.notifier).state = 'customer',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _FilterChip(
                                label: 'Blocked',
                                isSelected: currentFilter == 'blocked',
                                onSelected: () => ref.read(customerRoleFilterProvider.notifier).state = 'blocked',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      customersAsync.when(
                        data: (customers) {
                          final selectedSize = ref.watch(selectedCustomersProvider).length;
                          final isAllSelected = customers.isNotEmpty && selectedSize == customers.length;
                          
                          return IconButton(
                            onPressed: () {
                              if (isAllSelected) {
                                ref.read(selectedCustomersProvider.notifier).state = {};
                              } else {
                                ref.read(selectedCustomersProvider.notifier).state = 
                                  customers.map((c) => c['supabaseId'].toString()).toSet();
                              }
                            },
                            icon: Icon(
                              isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                              color: isAllSelected ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant),
                            ),
                            tooltip: isAllSelected ? 'Deselect All' : 'Select All',
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                      PopupMenuButton<CustomerSort>(
                        initialValue: ref.watch(customerSortProvider),
                        onSelected: (sort) => ref.read(customerSortProvider.notifier).state = sort,
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant, width: 0.5),
                          ),
                          child: const Icon(Icons.sort_rounded, size: 20),
                        ),
                        offset: const Offset(0, 48),
                        borderRadius: BorderRadius.circular(16),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: CustomerSort.newest, child: Text('Newest First')),
                          const PopupMenuItem(value: CustomerSort.oldest, child: Text('Oldest First')),
                          const PopupMenuItem(value: CustomerSort.nameAZ, child: Text('Name (A-Z)')),
                          const PopupMenuItem(value: CustomerSort.nameZA, child: Text('Name (Z-A)')),
                          const PopupMenuItem(value: CustomerSort.mostSpent, child: Text('Top Spenders')),
                          const PopupMenuItem(value: CustomerSort.mostOrders, child: Text('Frequent Buyers')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Selection Header
                  if (ref.watch(selectedCustomersProvider).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            '${ref.watch(selectedCustomersProvider).length} Selected Customers',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref.read(selectedCustomersProvider.notifier).state = {},
                            child: const Text('Clear all', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // List content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            sliver: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white10 : AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
                          const SizedBox(height: 20),
                          Text(
                            'No matching customers found',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or search query',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final customer = customers[index];
                      final name = customer['fullName'] ?? customer['email'] ?? 'Unknown User';
                      final email = customer['email'] ?? 'No Email';
                      final role = customer['role']?.toString() ?? 'customer';
                      final isActive = customer['isActive'] != false;
                      final customerId = customer['supabaseId']?.toString() ?? '';
                      final isSelected = ref.watch(selectedCustomersProvider).contains(customerId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: InkWell(
                            onTap: () {
                              if (ref.read(selectedCustomersProvider).isNotEmpty) {
                                _toggleSelection(ref, customer['supabaseId']);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
                                );
                              }
                            },
                            onLongPress: () => _toggleSelection(ref, customer['supabaseId']),
                            borderRadius: BorderRadius.circular(24),
                            child: AdminGlassCard(
                              padding: const EdgeInsets.all(16),
                              border: isSelected 
                                  ? Border.all(color: AppTheme.primary, width: 2)
                                  : null,
                              child: Row(
                                children: [
                                  if (ref.watch(selectedCustomersProvider).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleSelection(ref, customer['supabaseId']),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        activeColor: AppTheme.primary,
                                      ),
                                    ),
                                  
                                  // Avatar
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: !isActive 
                                          ? Colors.red.withValues(alpha: 0.1) 
                                          : (role == 'admin' ? AppTheme.tertiary.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1)),
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            color: !isActive ? Colors.red : (role == 'admin' ? AppTheme.tertiary : AppTheme.primary),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      if (!isActive)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            child: const Icon(Icons.block_rounded, color: Colors.red, size: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(width: 20),
                                  
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(
                                              label: role.toUpperCase(),
                                              color: role == 'admin' ? AppTheme.tertiary : AppTheme.primary,
                                              icon: role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildCompactInfo(
                                              Icons.shopping_bag_rounded, 
                                              '${(customer['Order'] as List? ?? []).length} Orders',
                                              AppTheme.primary,
                                              isDark,
                                            ),
                                            const SizedBox(width: 16),
                                            _buildCompactInfo(
                                              Icons.payments_rounded, 
                                              '₹${(customer['Order'] as List? ?? []).where((o) => o['orderStatus'] != 'cancelled' && o['orderStatus'] != 'returned').fold<double>(0, (sum, o) => sum + (double.tryParse(o['total']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(0)}',
                                              AppTheme.tertiary,
                                              isDark,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Contextual Badges
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final orders = customer['Order'] as List? ?? [];
                                            final totalSpent = orders.fold<double>(0, (sum, o) => sum + (double.tryParse(o['total']?.toString() ?? '0') ?? 0.0));
                                            
                                            DateTime? joinDate;
                                            try {
                                              if (customer['createdAt'] != null) {
                                                joinDate = DateTime.parse(customer['createdAt'].toString());
                                              }
                                            } catch (_) {}
                                            
                                            final isNew = joinDate != null && DateTime.now().difference(joinDate).inDays <= 7;
                                            
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                if (totalSpent > 10000 || orders.length > 5)
                                                  const Padding(
                                                    padding: EdgeInsets.only(bottom: 4),
                                                    child: StatusBadge(
                                                      label: 'TOP TIER', 
                                                      color: Colors.amber,
                                                      icon: Icons.star_rounded,
                                                    ),
                                                  ),
                                                if (isNew)
                                                  const Padding(
                                                    padding: EdgeInsets.only(bottom: 4),
                                                    child: StatusBadge(
                                                      label: 'NEW', 
                                                      color: Colors.blueAccent,
                                                      icon: Icons.auto_awesome_rounded,
                                                    ),
                                                  ),
                                                if (!isActive)
                                                  const StatusBadge(
                                                    label: 'BLOCKED', 
                                                    color: Colors.redAccent,
                                                    icon: Icons.block_rounded,
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.onSurfaceVariant.withValues(alpha: 0.2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: customers.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: ref.watch(selectedCustomersProvider).isNotEmpty
          ? _BulkActionBar(
              selectedCount: ref.watch(selectedCustomersProvider).length,
              onExport: () => _exportSelected(ref),
              onBlock: () => _bulkUpdateStatus(ref, false),
              onUnblock: () => _bulkUpdateStatus(ref, true),
              onDelete: () => _bulkDelete(ref),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCompactInfo(IconData icon, String text, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  void _toggleSelection(WidgetRef ref, String id) {
    final selected = Set<String>.from(ref.read(selectedCustomersProvider));
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    ref.read(selectedCustomersProvider.notifier).state = selected;
  }

  Future<void> _exportSelected(WidgetRef ref) async {
    final customers = ref.read(adminCustomersProvider).value ?? [];
    final selectedIds = ref.read(selectedCustomersProvider);
    
    List<List<dynamic>> rows = [];
    rows.add(['Full Name', 'Email', 'Phone', 'Role', 'Status', 'Total Orders', 'Total Spent', 'Created At']);
    
    for (final id in selectedIds) {
      final user = customers.firstWhere((c) => c['supabaseId'] == id, orElse: () => {});
      if (user.isNotEmpty) {
        final orders = user['Order'] as List? ?? [];
        final totalSpent = orders.fold<double>(0, (sum, o) => sum + (o['total'] ?? 0));
        
        rows.add([
          user['fullName'] ?? '',
          user['email'] ?? '',
          user['phone'] ?? '',
          user['role'] ?? '',
          user['isActive'] != false ? 'Active' : 'Blocked',
          orders.length,
          totalSpent.toStringAsFixed(2),
          user['createdAt'] ?? '',
        ]);
      }
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    if (kIsWeb) {
      debugPrint('Web Export: CSV generated');
      // For web, we'd typically trigger a browser download
      // For now, keep it simple as the user requested
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(content: Text('CSV Export not supported on web directly yet. Check console for data.')),
      );
      debugPrint(csvData);
    } else {
      // Mobile logic would go here if we had a conditional import or separate service
      // But since we are focusing on Web stabilization, we'll just log it
      debugPrint('Mobile Export: $csvData');
    }
    
    ref.read(selectedCustomersProvider.notifier).state = {};
  }

  Future<void> _bulkUpdateStatus(WidgetRef ref, bool activate) async {
    final selectedIds = ref.read(selectedCustomersProvider).toList();
    if (selectedIds.isEmpty) return;

    try {
      await AdminService.bulkUpdateCustomerStatus(selectedIds, activate);
      ref.invalidate(adminCustomersProvider);
      ref.read(selectedCustomersProvider.notifier).state = {};
      
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('${selectedIds.length} users ${activate ? 'unblocked' : 'blocked'} successfully'),
            backgroundColor: activate ? Colors.teal : AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text('Bulk update failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _bulkDelete(WidgetRef ref) async {
    final selectedIds = ref.read(selectedCustomersProvider).toList();
    if (selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selectedIds.length} Customers?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text('This action cannot be undone and might fail if they have existing orders. It\'s safer to Block users instead.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.bulkDeleteCustomers(selectedIds);
      ref.invalidate(adminCustomersProvider);
      ref.read(selectedCustomersProvider.notifier).state = {};
      
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(content: Text('Customers deleted successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text('Deletion failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildMiniStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: AdminGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: isDark ? Colors.white10 : Colors.white,
      selectedColor: AppTheme.primary,
      labelStyle: GoogleFonts.outfit(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.onSurfaceVariant),
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide.none : BorderSide(color: isDark ? Colors.white10 : AppTheme.outlineVariant, width: 0.5),
      ),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onExport;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;

  const _BulkActionBar({
    required this.selectedCount,
    required this.onExport,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdminGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      borderRadius: BorderRadius.circular(24),
      fillColor: AppTheme.primary.withValues(alpha: 0.95),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 24),
          _ActionButton(
            icon: Icons.download_rounded,
            label: 'Export',
            onTap: onExport,
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.block_flipped,
            label: 'Block',
            onTap: onBlock,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.check_circle_outline,
            label: 'Unblock',
            onTap: onUnblock,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: onDelete,
            color: Colors.red[900]!.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: color != null ? BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10,
                fontWeight: FontWeight.w700,
              )
            ),
          ],
        ),
      ),
    );
  }
}


