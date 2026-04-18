import '../config/supabase_config.dart';
import '../models/settings.dart';
import 'logger_service.dart';

class SettingsService {
  static final _client = SupabaseConfig.client;

  /// Fetch general site settings
  static Future<GeneralSettings> getGeneralSettings() async {
    try {
      final data = await _client
          .from('public_settings_general')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        return GeneralSettings.fromJson(data);
      }
    } catch (e) {
      LoggerService.logError('SettingsService.getGeneralSettings error: $e');
    }
    return const GeneralSettings();
  }

  /// Fetch payment settings
  static Future<PaymentSettings> getPaymentSettings() async {
    try {
      final data = await _client
          .from('public_settings_payment')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        return PaymentSettings.fromJson(data);
      } else {
        LoggerService.logEvent(
          event: 'settings_missing',
          message: 'Payment settings not found for ID 1',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      LoggerService.logError('SettingsService.getPaymentSettings error: $e');
    }
    return const PaymentSettings();
  }

  /// Fetch shipping settings
  static Future<ShippingSettings> getShippingSettings() async {
    try {
      final data = await _client
          .from('public_settings_shipping')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        return ShippingSettings.fromJson(data);
      }
    } catch (e) {
      LoggerService.logError('SettingsService.getShippingSettings error: $e');
    }
    return const ShippingSettings();
  }

  /// Fetch maintenance mode settings
  static Future<MaintenanceSettings> getMaintenanceSettings() async {
    try {
      final data = await _client
          .from('public_settings_maintenance')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        return MaintenanceSettings.fromJson(data);
      }
    } catch (e) {
      LoggerService.logError('SettingsService.getMaintenanceSettings error: $e');
    }
    return const MaintenanceSettings();
  }

  /// Get a stream of maintenance mode settings
  static Stream<MaintenanceSettings> getMaintenanceSettingsStream() {
    return _client
        .from('public_settings_maintenance')
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .map((data) => data.isNotEmpty 
            ? MaintenanceSettings.fromJson(data.first) 
            : const MaintenanceSettings());
  }

  /// Fetch app update settings
  static Future<AppUpdateSettings> getAppUpdateSettings() async {
    try {
      final data = await _client
          .from('settings_app_update')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (data != null) {
        return AppUpdateSettings.fromJson(data);
      }
    } catch (e) {
      LoggerService.logError('SettingsService.getAppUpdateSettings error: $e');
    }
    return const AppUpdateSettings(latestVersion: '1.0.0');
  }
}
