import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../providers/rider_provider.dart';
import '../../../providers/delivery_provider.dart';
import '../../../models/rider.dart';
import '../../../models/delivery_assignment.dart';
import '../../../widgets/glass_card.dart';

class RiderListScreen extends ConsumerStatefulWidget {
  const RiderListScreen({super.key});

  @override
  ConsumerState<RiderListScreen> createState() => _RiderListScreenState();
}

class _RiderListScreenState extends ConsumerState<RiderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(allRidersProvider);
    final assignmentsAsync = ref.watch(allAssignmentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Delivery Riders',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  ref.invalidate(allRidersProvider);
                  ref.invalidate(allAssignmentsProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          ridersAsync.when(
            data: (riders) {
              final filteredRiders = riders.where((rider) {
                final name = rider.fullName.toLowerCase();
                final phone = (rider.phone ?? '').toLowerCase();
                return name.contains(_searchQuery) || phone.contains(_searchQuery);
              }).toList();

              if (filteredRiders.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No riders found',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final rider = filteredRiders[index];
                      return _RiderCard(
                        rider: rider,
                        assignmentsAsync: assignmentsAsync,
                      );
                    },
                    childCount: filteredRiders.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SliverFillRemaining(
              child: Center(child: Text('Error loading riders')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/riders/new'),
        label: const Text('Add Rider'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  final Rider rider;
  final AsyncValue<List<DeliveryAssignment>> assignmentsAsync;

  const _RiderCard({
    required this.rider,
    required this.assignmentsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayCount = assignmentsAsync.when(
      data: (list) => list.where((a) => 
        a.riderId == rider.id && 
        a.status == DeliveryStatus.delivered &&
        a.deliveredAt != null &&
        a.deliveredAt!.day == today.day &&
        a.deliveredAt!.month == today.month &&
        a.deliveredAt!.year == today.year
      ).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () {
          // Navigation to details or assign
          // context.push('/admin/riders/${rider.id}');
        },
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rider.fullName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(isAvailable: rider.isAvailable),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rider.zone ?? 'No Zone'} • ${rider.vehicleType ?? 'No Vehicle'}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRating(),
                ],
              ),
            ),
            _buildBadge(todayCount),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = rider.fullName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.outfit(
            color: AppTheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < 4 ? Icons.star_rounded : Icons.star_half_rounded, // Placeholder for actual rating
          size: 14,
          color: Colors.amber,
        );
      }).toList(),
    );
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAvailable;

  const _StatusChip({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isAvailable ? Colors.green : Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isAvailable ? Colors.green : Colors.grey).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        isAvailable ? 'ONLINE' : 'OFFLINE',
        style: GoogleFonts.outfit(
          color: isAvailable ? Colors.green : Colors.grey,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

