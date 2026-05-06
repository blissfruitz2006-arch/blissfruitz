import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';

/// Earnings screen — shows delivery earnings with date filters and summary stats.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});
  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  int _selectedFilter = 0; // 0=Today, 1=This Week, 2=This Month
  List<Map<String, dynamic>> _earnings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 0: return DateTime(now.year, now.month, now.day);
      case 1: return now.subtract(Duration(days: now.weekday - 1));
      case 2: return DateTime(now.year, now.month, 1);
      default: return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _fetchEarnings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final riderId = SupabaseConfig.client.auth.currentUser?.id;
      if (riderId == null) throw Exception('Not authenticated');

      final start = _startDate.toIso8601String();
      final response = await SupabaseConfig.client
          .from('delivery_earnings')
          .select('*, delivery_assignments!inner(order_id, delivered_at)')
          .eq('rider_id', riderId)
          .gte('created_at', start)
          .order('created_at', ascending: false);

      setState(() {
        _earnings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _totalEarnings => _earnings.fold(0.0, (sum, e) => sum + ((e['total_earnings'] as num?)?.toDouble() ?? 0));
  int get _totalDeliveries => _earnings.length;
  double get _avgPerDelivery => _totalDeliveries > 0 ? _totalEarnings / _totalDeliveries : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: Column(
          children: [
            // Date filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(3, (i) {
                  final labels = ['Today', 'This Week', 'This Month'];
                  final selected = _selectedFilter == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { setState(() => _selectedFilter = i); _fetchEarnings(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? cs.primary : (isDark ? AppTheme.darkSurfaceContainerLow : AppTheme.surfaceContainerLow),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),

            // Summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _summaryCard('Total Earnings', '₹${_totalEarnings.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFF059669), isDark, cs),
                  const SizedBox(width: 10),
                  _summaryCard('Deliveries', '$_totalDeliveries', Icons.local_shipping_rounded, const Color(0xFF3B82F6), isDark, cs),
                  const SizedBox(width: 10),
                  _summaryCard('Avg/Delivery', '₹${_avgPerDelivery.toStringAsFixed(0)}', Icons.trending_up_rounded, const Color(0xFF8B5CF6), isDark, cs),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Earnings list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error', style: TextStyle(color: cs.error)))
                      : _earnings.isEmpty
                          ? _emptyState(cs)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _earnings.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) => _earningTile(_earnings[i], isDark, cs),
                            ),
            ),

            // Total bar at bottom
            if (!_isLoading && _earnings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
                  border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    Text('Total', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                    const Spacer(),
                    Text(
                      '₹${_totalEarnings.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color accent, bool isDark, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _earningTile(Map<String, dynamic> earning, bool isDark, ColorScheme cs) {
    final base = (earning['base_earnings'] as num?)?.toDouble() ?? 0;
    final bonus = (earning['bonus_earnings'] as num?)?.toDouble() ?? 0;
    final total = (earning['total_earnings'] as num?)?.toDouble() ?? 0;
    final assignmentData = earning['delivery_assignments'];
    
    // Handle both Map and List responses from Supabase joins
    Map<String, dynamic>? assignment;
    if (assignmentData is Map) {
      assignment = Map<String, dynamic>.from(assignmentData);
    } else if (assignmentData is List && assignmentData.isNotEmpty) {
      assignment = Map<String, dynamic>.from(assignmentData.first);
    }

    final orderId = assignment?['order_id'];
    final deliveredAt = assignment?['delivered_at'] != null
        ? DateTime.tryParse(assignment!['delivered_at'] as String)
        : (earning['created_at'] != null ? DateTime.tryParse(earning['created_at'] as String) : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 12),

          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId != null ? 'Order #$orderId' : 'Delivery',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  deliveredAt != null ? _formatDate(deliveredAt) : 'N/A',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Base ₹${base.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    if (bonus > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: Text('+₹${bonus.toStringAsFixed(0)} bonus', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF92400E))),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹${total.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    final labels = ['today', 'this week', 'this month'];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_outlined, size: 40, color: cs.outline),
          ),
          const SizedBox(height: 16),
          Text('No earnings ${labels[_selectedFilter]}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('Complete deliveries to start earning!', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${ist.day} ${months[ist.month - 1]} ${ist.year}, ${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')} IST';
  }
}

