import '../config/supabase_config.dart';
import '../models/banner_model.dart';

class BannerService {
  static final _client = SupabaseConfig.client;

  static Future<List<BannerModel>> getActiveBanners() async {
    final data = await _client
        .from('Banner')
        .select()
        .eq('isActive', true)
        .order('sortOrder', ascending: true);

    return (data as List).map((e) => BannerModel.fromJson(e)).toList();
  }

  static Future<List<BannerModel>> getBannersByPlacement(String placement) async {
    final data = await _client
        .from('Banner')
        .select()
        .eq('isActive', true)
        .eq('placement', placement)
        .order('sortOrder', ascending: true);

    return (data as List).map((e) => BannerModel.fromJson(e)).toList();
  }
}
