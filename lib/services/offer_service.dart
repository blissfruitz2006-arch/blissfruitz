import '../config/supabase_config.dart';
import '../models/offer.dart';

class OfferService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<Offer>> getActiveOffers() async {
    final data = await _client
        .from('Offer')
        .select()
        .eq('isActive', true)
        .order('sort_order', ascending: true);

    return (data as List).map((e) => Offer.fromJson(e)).toList();
  }
}
