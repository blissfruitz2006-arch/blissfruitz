/// General site settings from settings_general table
class GeneralSettings {
  final String? siteName;
  final String? logo;
  final String? favicon;
  final String? email;
  final String? phone;
  final String? address;

  const GeneralSettings({
    this.siteName,
    this.logo,
    this.favicon,
    this.email,
    this.phone,
    this.address,
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      siteName: json['site_name'] as String?,
      logo: json['logo'] as String?,
      favicon: json['favicon'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

/// Payment settings from settings_payment table
class PaymentSettings {
  final String currency;
  final bool codEnabled;
  final bool razorpayEnabled;
  final String? razorpayKeyId;
  // NOTE: razorpayKeySecret intentionally excluded from client model.
  // Payment verification must happen server-side via Supabase Edge Function.

  const PaymentSettings({
    this.currency = 'INR',
    this.codEnabled = true,
    this.razorpayEnabled = false,
    this.razorpayKeyId,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      if (value is int) return value == 1;
      return defaultValue;
    }

    return PaymentSettings(
      currency: json['currency'] as String? ?? 'INR',
      codEnabled: parseBool(json['cod_enabled'], true),
      razorpayEnabled: parseBool(json['razorpay_enabled'], false),
      razorpayKeyId: json['razorpay_key_id'] as String?,
    );
  }
}

/// Shipping settings from settings_shipping table
class ShippingSettings {
  final double flatRate;
  final double freeShippingMin;
  final String? deliveryEtaNote;

  const ShippingSettings({
    this.flatRate = 50,
    this.freeShippingMin = 500,
    this.deliveryEtaNote,
  });

  factory ShippingSettings.fromJson(Map<String, dynamic> json) {
    return ShippingSettings(
      flatRate: (json['flat_rate'] as num?)?.toDouble() ?? 50,
      freeShippingMin: (json['free_shipping_min'] as num?)?.toDouble() ?? 500,
      deliveryEtaNote: json['delivery_eta_note'] as String?,
    );
  }

  /// Calculate shipping cost for given subtotal
  double calculateShipping(double subtotal) {
    return subtotal >= freeShippingMin ? 0 : flatRate;
  }
}

/// Maintenance mode settings
class MaintenanceSettings {
  final bool enabled;
  final String? message;

  const MaintenanceSettings({
    this.enabled = false,
    this.message,
  });

  factory MaintenanceSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      if (value is int) return value == 1;
      return defaultValue;
    }

    return MaintenanceSettings(
      enabled: parseBool(json['enabled'], false),
      message: json['message'] as String?,
    );
  }
}

/// App update settings for self-hosted updates
class AppUpdateSettings {
  final String latestVersion;
  final String? apkUrl;
  final bool forceUpdate;
  final String? updateNotes;

  const AppUpdateSettings({
    required this.latestVersion,
    this.apkUrl,
    this.forceUpdate = false,
    this.updateNotes,
  });

  factory AppUpdateSettings.fromJson(Map<String, dynamic> json) {
    return AppUpdateSettings(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      apkUrl: json['apk_url'] as String?,
      forceUpdate: json['force_update'] as bool? ?? false,
      updateNotes: json['update_notes'] as String?,
    );
  }
}
