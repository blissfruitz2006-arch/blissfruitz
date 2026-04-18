import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/admin/admin_dialogs.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/delivery_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    return _buildMainContent(context, ref, isDesktop);
  }

  // Removed sidebar methods as they are now in AdminLayout

  Widget _buildMainContent(BuildContext context, WidgetRef ref, bool isDesktop) {
    final ordersAsync = ref.watch(filteredAdminOrdersProvider);
    final allOrdersAsync = ref.watch(adminOrdersProvider);
    final customersAsync = ref.watch(adminCustomersProvider);
    final messagesAsync = ref.watch(adminMessagesProvider);
    final productsAsync = ref.watch(adminProductsProvider);
    final activeRidersCount = ref.watch(activeRiderCountProvider);
    final outForDeliveryCount = ref.watch(outForDeliveryCountProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
          leading: !isDesktop ? null : const SizedBox.shrink(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Welcome back, ${ref.watch(userProfileProvider).valueOrNull?.fullName?.split(' ').first ?? 'Chef'}!',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLiveDot(),
                ],
              ),
              Text(
                'Here is what is happening with your store today.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          actions: [
            if (isDesktop) ...[
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: (val) => ref.read(orderSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search orders, customers...',
                    hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            _buildActionChip(context, 'Live Feed', Icons.sensors_rounded, Colors.green),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                ref.invalidate(adminProductsProvider);
                ref.invalidate(adminOrdersProvider);
                ref.invalidate(adminCustomersProvider);
                ref.invalidate(adminMessagesProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showQuickAddMenu(context, ref),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final int crossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: width < 600 ? 1.1 : (width < 900 ? 1.2 : 1.5),
                  children: [
                    _buildHeroMetricCard(
                      context,
                      'Net Sales',
                      allOrdersAsync.when(
                        data: (o) => o.where((e) => e.paymentStatus == 'paid').fold<double>(0.0, (sum, e) => sum + (e.total)),
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      '+12.5% from last month',
                      Icons.payments_rounded,
                      const Color(0xFF10B981),
                      [10, 20, 15, 30, 25, 45, 40],
                      prefix: '₹',
                    ),
                    _buildHeroMetricCard(
                      context,
                      'Total Orders',
                      allOrdersAsync.when(
                        data: (o) => o.length,
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      '${allOrdersAsync.valueOrNull?.where((e) => e.orderStatus == 'pending').length ?? 0} active processing',
                      Icons.shopping_bag_rounded,
                      const Color(0xFF6366F1),
                      [5, 15, 10, 25, 20, 35, 30],
                    ),
                    _buildHeroMetricCard(
                      context,
                      'Active Customers',
                      customersAsync.when(
                        data: (c) => c.length,
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      'Target: 5k this quarter',
                      Icons.group_rounded,
                      const Color(0xFFF59E0B),
                      [20, 25, 30, 35, 40, 45, 50],
                    ),
                    _buildHeroMetricCard(
                      context,
                      'Pending Inquiries',
                      messagesAsync.when(
                        data: (m) => m.length,
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      'Response rate: 98%',
                      Icons.chat_bubble_rounded,
                      const Color(0xFFEC4899),
                      [30, 20, 25, 15, 10, 5, 2],
                    ),
                    _buildHeroMetricCard(
                      context,
                      'Active Riders',
                      activeRidersCount.when(
                        data: (c) => c,
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      'Available for dispatch',
                      Icons.delivery_dining_rounded,
                      const Color(0xFF0EA5E9),
                      [2, 5, 3, 8, 6, 10, 12],
                    ),
                    _buildHeroMetricCard(
                      context,
                      'Out for Delivery',
                      outForDeliveryCount.when(
                        data: (c) => c,
                        loading: () => null,
                        error: (_, _) => null,
                      ),
                      'Active tracking links',
                      Icons.local_shipping_rounded,
                      const Color(0xFF8B5CF6),
                      [5, 10, 8, 15, 12, 20, 18],
                    ),
                  ],
                );
              }),

              const SizedBox(height: 32),

              _StaggeredEntrance(
                index: 5,
                child: _buildRevenueAnalytics(context, ref, isDesktop),
              ),

              const SizedBox(height: 32),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _StaggeredEntrance(index: 6, child: _buildInventorySection(productsAsync)),
                          const SizedBox(height: 24),
                          _StaggeredEntrance(index: 7, child: _buildLatestOrdersSection(ordersAsync)),
                          const SizedBox(height: 24),
                          _StaggeredEntrance(index: 8, child: _buildQuickLinksSection(context)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _StaggeredEntrance(
                        index: 9,
                        child: _DashboardSection(
                          title: 'Recent Global Activity',
                          icon: Icons.history_rounded,
                          child: _ActivityTimeline(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _StaggeredEntrance(index: 6, child: _buildInventorySection(productsAsync)),
                    const SizedBox(height: 24),
                    _StaggeredEntrance(index: 7, child: _buildLatestOrdersSection(ordersAsync)),
                    const SizedBox(height: 24),
                    _StaggeredEntrance(index: 8, child: _buildQuickLinksSection(context)),
                    const SizedBox(height: 24),
                    _StaggeredEntrance(
                      index: 9,
                      child: _DashboardSection(
                        title: 'Recent Global Activity',
                        icon: Icons.history_rounded,
                        child: _ActivityTimeline(),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection(AsyncValue<List<Product>> productsAsync) {
    return _DashboardSection(
      title: 'Inventory Health',
      icon: Icons.inventory_2_rounded,
      child: productsAsync.when(
        data: (products) {
          final lowStock = products.where((p) => p.stockQuantity < 10).toList();
          if (lowStock.isEmpty) return const _EmptyStockState();
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStock.length.clamp(0, 5),
            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
            itemBuilder: (context, index) {
              final p = lowStock[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                ),
                title: Text(
                  p.name, 
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${p.stockQuantity} units left', style: GoogleFonts.beVietnamPro(fontSize: 12)),
                trailing: TextButton(
                  onPressed: () => context.push('/admin/products/edit/${p.id}'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('RESTOCK'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Error loading inventory'),
      ),
    );
  }

  Widget _buildLatestOrdersSection(AsyncValue<List<Order>> ordersAsync) {
    return _DashboardSection(
      title: 'Latest Orders',
      icon: Icons.receipt_long_rounded,
      child: ordersAsync.when(
        data: (orders) {
          final showOrders = orders.take(5).toList();
          if (showOrders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No matching orders found'),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: showOrders.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.05)),
            itemBuilder: (context, index) {
              final o = showOrders[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/admin/orders/${o.id}'),
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: o.statusColor.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: o.statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: o.statusColor.withValues(alpha: 0.1)),
                          ),
                          child: Center(
                            child: Icon(o.statusIcon, color: o.statusColor, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.shippingName ?? 'Guest User',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '#${o.orderNumber?.toUpperCase() ?? 'N/A'}',
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeAgo(o.createdAt),
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${o.total.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: o.statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: o.statusColor.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                o.statusLabel.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: o.statusColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Error loading orders'),
      ),
    );
  }



  Widget _buildQuickLinksSection(BuildContext context) {
    return _DashboardSection(
      title: 'System Quick Links',
      icon: Icons.auto_fix_high_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _QuickLink(label: 'Global Settings', icon: Icons.settings_rounded, color: Colors.grey, onTap: () => context.push('/admin/settings')),
          _QuickLink(label: 'View Store', icon: Icons.visibility_rounded, color: Colors.blue, onTap: () => context.go('/')),
          _QuickLink(label: 'Coupon Engine', icon: Icons.confirmation_number_rounded, color: Colors.indigo, onTap: () => context.push('/admin/coupons')),
          _QuickLink(label: 'Review Center', icon: Icons.star_rounded, color: Colors.amber, onTap: () => context.push('/admin/reviews')),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics(BuildContext context, WidgetRef ref, bool isDesktop) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        final now = DateTime.now();
        final List<double> revenueData = List.generate(7, (index) {
          final date = now.subtract(Duration(days: 6 - index));
          return orders
              .where((o) => 
                  o.paymentStatus == 'paid' && 
                  o.createdAt != null &&
                  o.createdAt!.day == date.day &&
                  o.createdAt!.month == date.month &&
                  o.createdAt!.year == date.year)
              .fold<double>(0.0, (sum, o) => sum + (o.total));
        });

        final totalRevenue = revenueData.fold(0.0, (sum, r) => sum + r);

        return _DashboardSection(
          title: 'Revenue Analytics',
          icon: Icons.auto_graph_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${totalRevenue.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Total revenue from last 7 days',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildTrendBadge(revenueData),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RevenueChartPainter(revenueData, AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final date = now.subtract(Duration(days: 6 - index));
                  final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final label = dayLabels[(date.weekday - 1) % 7];
                  
                  return Text(
                    label,
                    style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                  );
                }),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox(height: 300, child: Center(child: Text('Error loading analytics'))),
    );
  }

  Widget _buildTrendBadge(List<double> data) {
    if (data.length < 2) return const SizedBox.shrink();
    final latest = data.last;
    final previous = data[data.length - 2];
    final isUp = latest >= previous;
    final percent = previous == 0 ? 100 : ((latest - previous) / previous * 100).abs();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isUp ? Colors.green : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUp ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricCard(BuildContext context, String title, num? value, String subtext, IconData icon, Color color, List<double> points, {String prefix = '', String suffix = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return _StaggeredEntrance(
      index: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.15 : 0.1),
              color.withValues(alpha: isDark ? 0.05 : 0.02),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              // Decorative background glow
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (points.last > points[points.length - 2] ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              points.last > points[points.length - 2] ? Icons.trending_up_rounded : Icons.trending_down_rounded, 
                              size: 14, 
                              color: points.last > points[points.length - 2] ? Colors.green : Colors.red
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '8%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: points.last > points[points.length - 2] ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _AnimatedNumber(
                      value: value ?? 0,
                      prefix: prefix,
                      suffix: suffix,
                      decimals: prefix == '₹' ? 0 : 0,
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13, 
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 0.2,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtext,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11, 
                            fontWeight: FontWeight.w600, 
                            color: isDark ? Colors.white38 : Colors.grey[600]
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        height: 25,
                        child: CustomPaint(
                          painter: _SparklinePainter(points, color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showQuickAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Create',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _QuickActionTile(
                    icon: Icons.add_shopping_cart_rounded, 
                    label: 'Product', 
                    color: AppTheme.primary,
                    onTap: () { Navigator.pop(context); context.push('/admin/products/new'); }
                  ),
                  _QuickActionTile(
                    icon: Icons.confirmation_number_rounded, 
                    label: 'Coupon', 
                    color: Colors.indigo,
                    onTap: () { 
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => CouponFormDialog(onSaved: () => ref.invalidate(adminCouponsProvider)));
                    }
                  ),
                  _QuickActionTile(
                    icon: Icons.article_rounded, 
                    label: 'Blog', 
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => BlogFormDialog(onSaved: () => ref.invalidate(adminBlogsProvider)));
                    }
                  ),
                  _QuickActionTile(
                    icon: Icons.local_offer_rounded, 
                    label: 'Offer', 
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => OfferFormDialog(onSaved: () => ref.invalidate(adminOffersProvider)));
                    }
                  ),
                  _QuickActionTile(
                    icon: Icons.view_carousel_rounded, 
                    label: 'Banner', 
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => BannerFormDialog(onSaved: () => ref.invalidate(adminBannersProvider)));
                    }
                  ),
                  _QuickActionTile(
                    icon: Icons.people_rounded, 
                    label: 'Customer', 
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/customers');
                    }
                  ),
                  _QuickActionTile(
                    icon: Icons.delivery_dining_rounded, 
                    label: 'Rider', 
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/riders/new');
                    }
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLink({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTimeline extends ConsumerWidget {
  const _ActivityTimeline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(adminOrdersProvider);
    final productsAsync = ref.watch(adminProductsProvider);

    return ordersAsync.when(
      data: (orders) {
        final List<Map<String, dynamic>> activities = [];
        
        for (final o in orders.take(5)) {
          String title;
          IconData icon;
          Color color;

          switch (o.orderStatus) {
            case 'return_requested':
              title = 'Return Request: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.assignment_return_rounded;
              color = Colors.purple;
              break;
            case 'replacement_requested':
              title = 'Replacement Request: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.published_with_changes_rounded;
              color = Colors.blue;
              break;
            case 'cancelled':
              title = 'Order Cancelled: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.cancel_rounded;
              color = Colors.red;
              break;
            case 'failed':
              title = 'Payment Failed: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.error_outline_rounded;
              color = Colors.redAccent;
              break;
            case 'delivered':
              title = 'Order Delivered: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.home_rounded;
              color = Colors.green;
              break;
            case 'shipped':
              title = 'Order Shipped: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.local_shipping_rounded;
              color = Colors.blueAccent;
              break;
            case 'confirmed':
              title = 'Order Confirmed: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.check_circle_rounded;
              color = Colors.teal;
              break;
            case 'pending':
            default:
              title = 'New Order: ${o.orderNumber ?? 'N/A'}';
              icon = Icons.shopping_cart_rounded;
              color = AppTheme.primary;
          }

          activities.add({
            'title': title,
            'time': _formatTimeAgo(o.createdAt),
            'icon': icon,
            'color': color,
            'orderId': o.id,
          });
        }

        productsAsync.whenData((products) {
          final lowStock = products.where((p) => p.stockQuantity < 10).take(2);
          for (final p in lowStock) {
            activities.add({
              'title': 'Low Stock: ${p.name}',
              'time': 'Alert',
              'icon': Icons.inventory_2_rounded,
              'color': Colors.orange,
              'productId': p.id,
            });
          }
        });

        if (activities.isEmpty) {
          return const Center(child: Text('No recent activity'));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(activities.length, (index) {
              final a = activities[index];
              return _StaggeredEntrance(
                index: 10 + index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: (a['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: (a['color'] as Color).withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(a['icon'] as IconData, size: 22, color: a['color'] as Color),
                          ),
                          if (index != activities.length - 1)
                            Container(
                              width: 2,
                              height: 45,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (a['color'] as Color).withValues(alpha: 0.4),
                                    (activities[index + 1]['color'] as Color).withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    a['title'] as String,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  a['time'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              index == 0 ? 'Requires immediate reviewer attention' : 'System automated update log',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.white38 : Colors.grey[600],
                              ),
                            ),
                            if (a.containsKey('orderId')) ...[
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: () => context.push('/admin/orders/${a['orderId']}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.remove_red_eye_rounded, size: 14, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'VIEW FULL DETAILS',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.push('/admin/orders'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('EXPLORE FULL LOG', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading activity'),
    );
  }


}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyStockState extends StatelessWidget {
  const _EmptyStockState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Inventory Healthy', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.green)),
          Text('All products are in stock', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double step = size.width / (data.length - 1);
    final double max = data.reduce((a, b) => a > b ? a : b);
    final double min = data.reduce((a, b) => a < b ? a : b);
    final double range = max - min;

    for (int i = 0; i < data.length; i++) {
      final double x = i * step;
      final double y = size.height - ((data[i] - min) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    
    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _RevenueChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double effectiveMax = maxVal == 0 ? 100 : maxVal * 1.2;
    
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        final y = size.height - (data[i] / effectiveMax * size.height);
        points.add(Offset(x, y));
        
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            final prevX = (i - 1) * stepX;
            final prevY = size.height - (data[i - 1] / effectiveMax * size.height);
            
            // Premium cubic interpolation
            final cp1 = Offset(prevX + (x - prevX) / 2, prevY);
            final cp2 = Offset(prevX + (x - prevX) / 2, y);
            
            path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, x, y);
        }
    }

    // Draw background grid lines (extremely subtle)
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw area gradient with multiple stops for depth
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.25),
        color.withValues(alpha: 0.08),
        color.withValues(alpha: 0.01),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    
    // Draw shadows for the line glow
    canvas.drawPath(
      path, 
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
    );
    
    canvas.drawPath(path, paint);

    // Draw points with "ring and dot" design
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      
      // Glow background
      canvas.drawCircle(p, 10, Paint()..color = color.withValues(alpha: 0.1));
      
      // Ring
      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(p, 6, Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      
      // Center dot
      canvas.drawCircle(p, 3.5, Paint()..color = color);
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension ColorBrightness on Color {
  Brightness get brightness {
    final double relativeLuminance = computeLuminance();
    return relativeLuminance > 0.5 ? Brightness.light : Brightness.dark;
  }
}

class _AnimatedNumber extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final int decimals;

  const _AnimatedNumber({
    required this.value,
    this.prefix = '',
    this.suffix = '',
    required this.style,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredEntrance({required this.child, required this.index});

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

String _formatTimeAgo(DateTime? dt) {
  if (dt == null) return 'Unknown';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
