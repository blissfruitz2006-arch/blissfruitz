import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

/// Provider for general site settings
final generalSettingsProvider = FutureProvider<GeneralSettings>((ref) async {
  return SettingsService.getGeneralSettings();
});

/// Provider for payment settings
final paymentSettingsProvider = FutureProvider<PaymentSettings>((ref) async {
  return SettingsService.getPaymentSettings();
});

/// Provider for shipping settings
final shippingSettingsProvider = FutureProvider<ShippingSettings>((ref) async {
  return SettingsService.getShippingSettings();
});

/// Provider for maintenance settings
final maintenanceSettingsProvider = StreamProvider<MaintenanceSettings>((ref) {
  return SettingsService.getMaintenanceSettingsStream();
});

/// Provider for app update settings
final appUpdateSettingsProvider = FutureProvider<AppUpdateSettings>((ref) async {
  return SettingsService.getAppUpdateSettings();
});
