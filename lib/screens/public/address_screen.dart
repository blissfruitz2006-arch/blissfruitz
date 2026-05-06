import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../models/address.dart';

import '../../widgets/address_form_modal.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  late Future<List<Address>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _refreshAddresses();
  }

  void _refreshAddresses() {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user != null && user.supabaseId != null) {
      setState(() {
        _addressesFuture = AddressService.getUserAddresses(user.supabaseId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull;

    if (user == null) {
      return Title(
        title: 'Saved Addresses | Blissfruitz',
        color: Colors.white,
        child: const Center(child: Text('Please login to manage addresses')),
      );
    }

    return Title(
      title: 'Saved Addresses | Blissfruitz',
      color: Colors.white,
      child: Stack(
        children: [
          FutureBuilder<List<Address>>(
            future: _addressesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final addresses = snapshot.data ?? [];

              if (addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.location_off_outlined, size: 64, color: AppTheme.outline),
                       const SizedBox(height: 16),
                      Text(
                        'No saved addresses',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an address for faster checkout',
                        style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressCard(
                    address: address,
                    onDelete: () async {
                      await AddressService.deleteAddress(address.id!);
                      _refreshAddresses();
                    },
                    onSetDefault: () async {
                      if (user.supabaseId != null) {
                        await AddressService.setDefault(address.id!, user.supabaseId!);
                        _refreshAddresses();
                      }
                    },
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => _showAddressForm(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressForm(BuildContext context, [Address? address]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormModal(
        address: address,
        onSave: (address, email) {
          _refreshAddresses();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault 
            ? AppTheme.primary.withValues(alpha: 0.5) 
            : Theme.of(context).colorScheme.outlineVariant,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.label?.toUpperCase() ?? 'HOME',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (address.isDefault)
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                  if (val == 'default') onSetDefault();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.fullName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address.displayString,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${address.phone}',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


