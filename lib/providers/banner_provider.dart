import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

final bannersByPlacementProvider = FutureProvider.family<List<BannerModel>, String>((ref, placement) async {
  return BannerService.getBannersByPlacement(placement);
});
