import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

/// Provider for general site settings
final generalSettingsProvider = FutureProvider<GeneralSettings>((ref) async {
  return SettingsService.getGeneralSettings();
});

/// Provider for payment settings
final paymentSettingsProvider = StreamProvider<PaymentSettings>((ref) {
  return SettingsService.watchSettings('settings_payment')
      .map((data) => PaymentSettings.fromJson(data));
});

/// Provider for shipping settings
final shippingSettingsProvider = FutureProvider<ShippingSettings>((ref) async {
  return SettingsService.getShippingSettings();
});

/// Provider for maintenance settings
final maintenanceSettingsProvider = StreamProvider<MaintenanceSettings>((ref) {
  return SettingsService.watchMaintenanceSettings();
});

/// Provider for app update settings
final appUpdateSettingsProvider = FutureProvider<AppUpdateSettings>((ref) async {
  return SettingsService.getAppUpdateSettings();
});

/// Provider for product catalog settings
final productCatalogSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return SettingsService.getSettings('settings_product_catalog');
});

/// Provider for UI theme settings
final uiThemeSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return SettingsService.getSettings('settings_ui_theme');
});

/// Provider for security settings
final securitySettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return SettingsService.getSettings('settings_security');
});

/// Provider for analytics settings
final analyticsSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return SettingsService.getSettings('settings_analytics');
});


