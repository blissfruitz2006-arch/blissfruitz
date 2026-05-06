import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/offer.dart';
import '../../../widgets/app_image.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';
import '../../../providers/offer_provider.dart';
import '../../../widgets/admin/admin_dialogs.dart';

class OfferManagerScreen extends ConsumerWidget {
  const OfferManagerScreen({super.key});

  void _showOfferForm(BuildContext context, WidgetRef ref, [Offer? offer]) {
    showDialog(
      context: context,
      builder: (context) => OfferFormDialog(offer: offer, onSaved: () {
        ref.invalidate(adminOffersProvider);
        ref.invalidate(offersProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Offers & Deals', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showOfferForm(context, ref),
          ),
        ],
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) return const Center(child: Text('No offers found'));
          return ListView.builder(
            itemCount: offers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                elevation: 0,
                color: AppTheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: AppImage(path: offer.imageUrl ?? '', fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(offer.title ?? 'Untitled Offer', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Code: ${offer.couponCode ?? "N/A"} • ${offer.discountValue} Off'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showOfferForm(context, ref, offer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Offer?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await AdminService.deleteOffer(offer.id);
                            ref.invalidate(adminOffersProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error loading offers: $e', textAlign: TextAlign.center),
              TextButton(onPressed: () => ref.invalidate(adminOffersProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOfferForm(context, ref),
        label: const Text('Add Offer'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

