import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/settings.dart';

class SettingsService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // --- Generic Methods for Dynamic Architecture ---

  /// Fetches settings from a specific table (assumes 1-row table with id=1)
  static Future<Map<String, dynamic>> getSettings(String tableName) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .limit(1)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      debugPrint('SettingsService.getSettings ($tableName) error: $e');
      return {};
    }
  }

  /// Updates settings in a specific table
  static Future<void> updateSettings(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      // Remove any fields that shouldn't be updated (like id, created_at, updated_at)
      final payload = Map<String, dynamic>.from(data);
      payload['id'] = 1;
      payload['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from(tableName).upsert(payload);
    } catch (e) {
      debugPrint('SettingsService.updateSettings ($tableName) error: $e');
      rethrow;
    }
  }

  /// Returns a stream for real-time updates (useful for maintenance mode)
  static Stream<Map<String, dynamic>> watchSettings(String tableName) {
    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  // --- Specific Typed Methods ---

  static Future<GeneralSettings> getGeneralSettings() async {
    final data = await getSettings('settings_general');
    return GeneralSettings.fromJson(data);
  }

  static Future<PaymentSettings> getPaymentSettings() async {
    final data = await getSettings('settings_payment');
    return PaymentSettings.fromJson(data);
  }

  static Future<ShippingSettings> getShippingSettings() async {
    final data = await getSettings('settings_shipping');
    return ShippingSettings.fromJson(data);
  }

  static Stream<MaintenanceSettings> watchMaintenanceSettings() {
    return watchSettings(
      'settings_maintenance',
    ).map((data) => MaintenanceSettings.fromJson(data));
  }

  static Future<AppUpdateSettings> getAppUpdateSettings() async {
    final data = await getSettings('settings_app_update');
    return AppUpdateSettings.fromJson(data);
  }
}
