class FlavorConfig {
  static const String flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'customer');
  static bool get isRider => flavor == 'rider';
  static bool get isCustomer => flavor == 'customer';
  static String get appName => isRider ? 'BlissFruitz Rider' : 'BlissFruitz';
  static String get packageName => isRider ? 'com.blissfruitz.rider' : 'com.blissfruitz.app';
}
