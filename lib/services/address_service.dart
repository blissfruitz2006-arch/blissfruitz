import '../config/supabase_config.dart';
import '../models/address.dart';

class AddressService {
  static final _client = SupabaseConfig.client;

  /// Get all saved addresses for a user
  static Future<List<Address>> getUserAddresses(int userId) async {
    final data = await _client
        .from('Address')
        .select()
        .eq('userId', userId)
        .order('isDefault', ascending: false);

    return (data as List).map((e) => Address.fromJson(e)).toList();
  }

  /// Add a new address
  static Future<Address> addAddress(Address address) async {
    // If setting as default, unset other defaults first
    if (address.isDefault && address.userId != null) {
      await _client
          .from('Address')
          .update({'isDefault': false})
          .eq('userId', address.userId!);
    }

    final data = await _client
        .from('Address')
        .insert(address.toInsertJson())
        .select()
        .single();

    return Address.fromJson(data);
  }

  /// Update an existing address
  static Future<Address> updateAddress(Address address) async {
    if (address.id == null) throw Exception('Cannot update address without id');

    // If setting as default, unset other defaults first
    if (address.isDefault && address.userId != null) {
      await _client
          .from('Address')
          .update({'isDefault': false})
          .eq('userId', address.userId!);
    }

    final data = await _client
        .from('Address')
        .update(address.toInsertJson())
        .eq('id', address.id!)
        .select()
        .single();

    return Address.fromJson(data);
  }

  /// Delete an address
  static Future<void> deleteAddress(int addressId) async {
    await _client.from('Address').delete().eq('id', addressId);
  }

  /// Set an address as default
  static Future<void> setDefault(int addressId, int userId) async {
    // Unset all defaults for this user
    await _client
        .from('Address')
        .update({'isDefault': false})
        .eq('userId', userId);

    // Set the specified address as default
    await _client
        .from('Address')
        .update({'isDefault': true})
        .eq('id', addressId);
  }

  /// Get the default address for a user
  static Future<Address?> getDefaultAddress(int userId) async {
    final data = await _client
        .from('Address')
        .select()
        .eq('userId', userId)
        .eq('isDefault', true)
        .maybeSingle();

    if (data != null) {
      return Address.fromJson(data);
    }
    return null;
  }
}
