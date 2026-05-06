import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/delivery_assignment.dart';
import '../../models/rider.dart';
import '../../providers/rider_provider.dart';
import '../../providers/location_provider.dart';
import 'package:go_router/go_router.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});
  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  bool _isToggling = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _toggleOnline(bool val, String riderId) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      final loc = ref.read(locationServiceProvider);
      if (val) { await loc.requestPermission(); loc.startBroadcasting(riderId); }
      else { await loc.stopBroadcasting(riderId); }
      await loc.updateAvailability(riderId, val);
      setState(() => _isOnline = val);
      ref.invalidate(riderProfileProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppTheme.error));
    } finally { if (mounted) setState(() => _isToggling = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    
    final riderAsync = ref.watch(riderProfileProvider);
    return riderAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (rider) {
        if (rider == null) return const Scaffold(body: Center(child: Text('Rider profile not found.')));
        if (!_isToggling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isOnline != rider.isAvailable) setState(() => _isOnline = rider.isAvailable);
          });
        }
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(rider, cs)),
                SliverToBoxAdapter(child: _toggle(rider, isDark, cs)),
                if (_isOnline) _assignmentsList(isDark, cs) else SliverFillRemaining(child: _offlineState(cs)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(Rider rider, ColorScheme cs) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Center(child: Text(
          (rider.fullName.isNotEmpty) ? rider.fullName[0].toUpperCase() : 'R',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        )),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hey, ${rider.fullName.split(' ').first} 👋', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 2),
        Row(children: [
          _statMiniItem('₹${rider.totalEarnings.toStringAsFixed(0)}', 'Earned', cs),
          const SizedBox(width: 12),
          _statMiniItem('${rider.totalDeliveries}', 'Deliveries', cs),
        ]),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text('4.8', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E))),
        ]),
      ),
    ]));
  }

  Widget _statMiniItem(String val, String label, ColorScheme cs) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: cs.primary)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
    ]);
  }

  Widget _toggle(Rider rider, bool isDark, ColorScheme cs) {
    return AnimatedBuilder(animation: _pulseCtrl, builder: (ctx, _) {
      final glow = _isOnline ? 0.15 + (_pulseCtrl.value * 0.1) : 0.0;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _isOnline
              ? LinearGradient(colors: [const Color(0xFF059669).withValues(alpha: 0.12), const Color(0xFF10B981).withValues(alpha: 0.06)])
              : LinearGradient(colors: [cs.surfaceContainerHighest.withValues(alpha: 0.5), cs.surfaceContainerHighest.withValues(alpha: 0.3)]),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: _isOnline ? const Color(0xFF10B981).withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.3)),
          boxShadow: _isOnline ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: glow), blurRadius: 30)] : null,
        ),
        child: Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 400), width: 48, height: 48,
            decoration: BoxDecoration(color: _isOnline ? const Color(0xFF059669) : cs.outline.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(_isOnline ? Icons.electric_bolt_rounded : Icons.power_settings_new_rounded, color: _isOnline ? Colors.white : cs.onSurfaceVariant, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_isOnline ? "You're Online" : "You're Offline", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: _isOnline ? const Color(0xFF059669) : cs.onSurfaceVariant)),
            Text(_isOnline ? 'Receiving delivery requests' : 'Go online to receive orders', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          Transform.scale(scale: 1.2, child: Switch.adaptive(value: _isOnline, onChanged: _isToggling ? null : (v) => _toggleOnline(v, rider.id),
            activeTrackColor: const Color(0xFF6EE7B7), thumbColor: WidgetStateProperty.resolveWith((s) => _isOnline ? const Color(0xFF059669) : null))),
        ]),
      );
    });
  }

  Widget _assignmentsList(bool isDark, ColorScheme cs) {
    final async = ref.watch(myAssignmentsProvider);
    return async.when(
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
      data: (all) {
        final active = all.where((a) => a.status != DeliveryStatus.delivered && a.status != DeliveryStatus.failed).toList();
        final history = all.where((a) => a.status == DeliveryStatus.delivered || a.status == DeliveryStatus.failed).take(5).toList();

        if (active.isEmpty && history.isEmpty) {
          return SliverFillRemaining(child: _offlineState(cs, msg: 'No deliveries yet', sub: 'New orders will appear here'));
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                // Active Section
                if (active.isNotEmpty) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text('Active Deliveries (${active.length})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    );
                  }
                  if (i <= active.length) {
                    return _assignmentCard(active[i - 1], isDark, cs);
                  }
                }

                // History Section
                final historyIndex = active.isNotEmpty ? i - active.length - 1 : i;
                if (history.isNotEmpty) {
                  if (historyIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Row(
                        children: [
                          Text('Recent History', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.pushNamed('rider-earnings'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (historyIndex > 0 && historyIndex <= history.length) {
                    return _historyCard(history[historyIndex - 1], isDark, cs);
                  }
                }
                return null;
              },
              childCount: (active.isNotEmpty ? active.length + 1 : 0) + (history.isNotEmpty ? history.length + 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _assignmentCard(DeliveryAssignment a, bool isDark, ColorScheme cs) {
    final o = a.order;
    final name = o?.shippingName ?? 'Customer';
    final addr = [o?.shippingAddress, o?.shippingCity, o?.shippingPincode].where((s) => s != null && s.isNotEmpty).join(', ');
    final total = o?.total ?? 0;
    final sColor = a.status == DeliveryStatus.assigned ? const Color(0xFF3B82F6) : a.status == DeliveryStatus.pickedUp ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6);
    return GestureDetector(
      onTap: () => context.pushNamed('rider-order-detail', pathParameters: {'id': a.orderId.toString()}, extra: a),
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceContainerLowest : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)), boxShadow: AppTheme.softShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(a.statusLabel, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: sColor))),
            const Spacer(),
            Text('#${a.orderId}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 12),
          Row(children: [Icon(Icons.person_outline_rounded, size: 18, color: cs.onSurfaceVariant), const SizedBox(width: 8),
            Expanded(child: Text(name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)))]),
          if (addr.isNotEmpty) ...[const SizedBox(height: 6), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.location_on_outlined, size: 18, color: cs.onSurfaceVariant), const SizedBox(width: 8),
            Expanded(child: Text(addr, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis))])],
          const SizedBox(height: 12),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary))),
            const SizedBox(width: 12), Icon(Icons.route_rounded, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 4),
            Text('~5 km', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const Spacer(), Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.outline),
          ]),
        ])),
    );
  }

  Widget _historyCard(DeliveryAssignment a, bool isDark, ColorScheme cs) {
    final o = a.order;
    final name = o?.shippingName ?? 'Customer';
    final deliveredAt = a.deliveredAt ?? a.assignedAt;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainerLowest.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${a.orderId} • $name', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                Text(
                  deliveredAt != null ? _formatTime(deliveredAt) : 'Delivered',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final ist = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.day}/${ist.month} ${ist.hour}:${ist.minute.toString().padLeft(2, '0')}';
  }

  Widget _offlineState(ColorScheme cs, {String msg = 'Go online to receive orders', String sub = 'Toggle the switch above to start receiving delivery requests.'}) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.delivery_dining_outlined, size: 52, color: cs.outline)),
      const SizedBox(height: 20),
      Text(msg, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
    ]));
  }

}

