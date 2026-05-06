import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/offer.dart';
import '../services/offer_service.dart';

final offersProvider = FutureProvider<List<Offer>>((ref) async {
  return OfferService.getActiveOffers();
});
