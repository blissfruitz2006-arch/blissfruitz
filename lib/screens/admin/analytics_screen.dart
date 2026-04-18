import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import 'components/admin_common_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Detailed Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Overview Metrics'),
              _buildHeader(context, stats),
              const SizedBox(height: 40),
              const SectionHeader(title: 'Growth Trends'),
              _buildCharts(context),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 1200 ? 4 : (width > 600 ? 2 : 1);
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: width > 1200 ? 1.5 : (width > 600 ? 1.8 : 2.5),
          children: [
            _buildStatCard(
              context,
              'Total Revenue',
              '₹${stats['total_revenue']?.toStringAsFixed(0) ?? '0'}',
              Icons.payments_rounded,
              const Color(0xFF10B981),
            ),
            _buildStatCard(
              context,
              'Total Orders',
              stats['total_orders']?.toString() ?? '0',
              Icons.shopping_bag_rounded,
              const Color(0xFF6366F1),
            ),
            _buildStatCard(
              context,
              'Active Products',
              stats['total_products']?.toString() ?? '0',
              Icons.inventory_2_rounded,
              const Color(0xFFF59E0B),
            ),
            _buildStatCard(
              context,
              'Customers',
              stats['total_customers']?.toString() ?? '0',
              Icons.people_rounded,
              const Color(0xFFEC4899),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AdminGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context) {
    return Column(
      children: [
        _buildChartCard(
          context, 
          'Revenue Trend', 
          'Daily revenue over the last 7 days',
          const _RevenueChartPainter(
            data: [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.85],
            color: Color(0xFF10B981),
          ),
          '₹12,450',
          '+12.5%',
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          context, 
          'Order Volume', 
          'Successful orders processed daily',
          const _RevenueChartPainter(
            data: [0.3, 0.4, 0.6, 0.4, 0.7, 0.5, 0.8],
            color: Color(0xFF6366F1),
          ),
          '156',
          '+8.2%',
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    CustomPainter painter,
    String mainValue,
    String trend,
  ) {
    return AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mainValue,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        color: Colors.green, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 11
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: painter,
            ),
          ),
        ],
      ),
    );
  }

}

class _RevenueChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _RevenueChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double dx = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final double x = i * dx;
      final double y = size.height - (data[i] * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * dx;
        final double prevY = size.height - (data[i - 1] * size.height);
        final double cx = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, cx, (prevY + y) / 2);
        fillPath.quadraticBezierTo(prevX, prevY, cx, (prevY + y) / 2);
      }
    }
    
    path.lineTo(size.width, size.height - (data.last * size.height));
    fillPath.lineTo(size.width, size.height - (data.last * size.height));
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    final dotBgPaint = Paint()..color = Colors.white;
    for (int i = 0; i < data.length; i++) {
      final double x = i * dx;
      final double y = size.height - (data[i] * size.height);
      canvas.drawCircle(Offset(x, y), 5, dotBgPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
