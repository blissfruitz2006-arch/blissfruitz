import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/order.dart';
import '../../../providers/admin_provider.dart';
import '../orders/order_detail_screen.dart';
import '../components/admin_common_widgets.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late Map<String, dynamic> _currentCustomer;
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Order>> _ordersFuture;
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _notesController.text = _currentCustomer['adminNotes'] ?? '';
    _loadData();
  }

  void _loadData() {
    final supabaseId = _currentCustomer['supabaseId']?.toString() ?? '';
    final rawId = _currentCustomer['id'];
    final userId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    
    _statsFuture = AdminService.getUserStats(userId);
    _ordersFuture = _fetchUserOrders(supabaseId);
  }

  Future<List<Order>> _fetchUserOrders(String supabaseId) async {
    final rawId = _currentCustomer['id'];
    if (rawId == null) return [];
    final userId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    if (userId == 0) return [];
    return AdminService.getUserOrders(userId);
  }

  Future<void> _toggleStatus() async {
    final newStatus = !(_currentCustomer['isActive'] ?? true);
    try {
      await AdminService.toggleUserStatus(_currentCustomer['supabaseId'], newStatus);
      ref.invalidate(adminCustomersProvider);
      setState(() {
        _currentCustomer['isActive'] = newStatus;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'User unblocked' : 'User blocked'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _changeRole(String currentRole) async {
    final newRole = currentRole == 'admin' ? 'customer' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('Do you want to change this user\'s role to ${newRole.toUpperCase()}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.updateUserRole(_currentCustomer['supabaseId'], newRole);
        ref.invalidate(adminCustomersProvider);
        setState(() {
          _currentCustomer['role'] = newRole;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      await AdminService.updateAdminNotes(_currentCustomer['supabaseId'], _notesController.text);
      ref.invalidate(adminCustomersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes updated successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _currentCustomer['fullName']?.toString() ?? 'Unknown User';
    final email = _currentCustomer['email']?.toString() ?? 'No Email';
    final phone = _currentCustomer['phone']?.toString() ?? 'No Phone';
    final role = (_currentCustomer['role']?.toString() ?? 'customer').toUpperCase();
    final isActive = _currentCustomer['isActive'] ?? true;
    
    DateTime? createdAt;
    try {
      if (_currentCustomer['createdAt'] != null) {
        createdAt = DateTime.parse(_currentCustomer['createdAt'].toString());
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Customer Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            AdminGlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? AppTheme.primary.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isActive ? AppTheme.primary : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.beVietnamPro(
                            color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusBadge(
                              label: role, 
                              color: role == 'ADMIN' ? AppTheme.tertiary : AppTheme.primary,
                              icon: role == 'ADMIN' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                            ),
                            StatusBadge(
                              label: isActive ? 'ACTIVE' : 'BLOCKED', 
                              color: isActive ? Colors.green : Colors.red,
                              icon: isActive ? Icons.check_circle_outline : Icons.block_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Row
            FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {
                  'orderCount': 0, 
                  'totalSpent': 0.0,
                  'avgOrderValue': 0.0,
                  'lastOrderDate': null,
                };
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Orders',
                            stats['orderCount'].toString(),
                            Icons.shopping_bag_outlined,
                            AppTheme.primary,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Spent',
                            '₹${((stats['totalSpent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                            Icons.account_balance_wallet_outlined,
                            AppTheme.tertiary,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Avg. Value',
                            '₹${((stats['avgOrderValue'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                            Icons.analytics_outlined,
                            Colors.blueAccent,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Last Order',
                            stats['lastOrderDate'] != null 
                              ? DateFormat('MMM dd').format(DateTime.parse(stats['lastOrderDate']))
                              : 'None',
                            Icons.history_rounded,
                            Colors.orangeAccent,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Profile Info
            const SectionHeader(title: 'Profile Information'),
            AdminGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildInfoRow('Phone Number', phone, Icons.phone_outlined, isDark),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  _buildInfoRow(
                    'Membership Date', 
                    createdAt != null ? DateFormat('MMMM dd, yyyy').format(createdAt) : 'N/A', 
                    Icons.calendar_today_outlined,
                    isDark,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  _buildInfoRow(
                    'Primary Address', 
                    _currentCustomer['address'] ?? 'No address provided', 
                    Icons.location_on_outlined,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Admin Notes
            SectionHeader(
              title: 'Internal Admin Notes',
              trailing: (_notesController.text != (_currentCustomer['adminNotes'] ?? ''))
                ? TextButton.icon(
                    onPressed: _isSavingNotes ? null : _saveNotes,
                    icon: _isSavingNotes 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                : null,
            ),
            AdminGlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Add internal notes about this customer (behavior, preferences, issues)...',
                  hintStyle: TextStyle(color: (isDark ? Colors.white38 : AppTheme.onSurfaceVariant).withValues(alpha: 0.5), fontSize: 13),
                  contentPadding: const EdgeInsets.all(20),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Order History
            SectionHeader(
              title: 'Order History',
              trailing: TextButton.icon(
                onPressed: () => setState(() => _ordersFuture = _fetchUserOrders(_currentCustomer['supabaseId'])),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return AdminGlassCard(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 48, color: (isDark ? Colors.white10 : AppTheme.onSurfaceVariant.withValues(alpha: 0.1))),
                          const SizedBox(height: 16),
                          Text(
                            'No orders placed yet', 
                            style: GoogleFonts.beVietnamPro(
                              color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id.toString())),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: AdminGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.orderNumber ?? order.id}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt ?? DateTime.now()),
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${order.total.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildCompactStatusBadge(
                                    order.statusLabel,
                                    _getStatusColor(order.orderStatus),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
            
            // Management Tools
            const SectionHeader(title: 'Management Tools'),
            Row(
              children: [
                Expanded(
                  child: _ManagementButton(
                    onTap: _toggleStatus,
                    icon: isActive ? Icons.block_rounded : Icons.check_circle_outline,
                    label: isActive ? 'Block User' : 'Unblock User',
                    color: isActive ? Colors.red : Colors.green,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ManagementButton(
                    onTap: () => _changeRole(_currentCustomer['role']),
                    icon: Icons.admin_panel_settings_outlined,
                    label: role == 'ADMIN' ? 'Demote to User' : 'Make Admin',
                    color: AppTheme.tertiary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _ManagementButton(
                onTap: _deleteUser,
                icon: Icons.delete_forever_rounded,
                label: 'Delete Account Permanently',
                color: Colors.red,
                isDark: isDark,
                isOutlined: true,
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: const Text('This action is permanent and cannot be undone. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteUserAccount(_currentCustomer['supabaseId']);
        if (mounted) {
          ref.invalidate(adminCustomersProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User account deleted successfully'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'shipped': return Colors.blue;
      case 'processing': return Colors.orange;
      default: return AppTheme.primary;
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: (isDark ? Colors.white38 : AppTheme.onSurfaceVariant).withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ManagementButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isOutlined;

  const _ManagementButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

