import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'auth_provider.dart';

final userOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;
  if (userProfile == null || userProfile.supabaseId == null) return [];

  return OrderService.getUserOrders(userProfile.supabaseId!);
});

final orderDetailsProvider = FutureProvider.autoDispose.family<Order?, int>((
  ref,
  orderId,
) async {
  return OrderService.getOrderById(orderId);
});

final orderDetailsStreamProvider = StreamProvider.autoDispose.family<Order?, int>((
  ref,
  orderId,
) {
  return OrderService.getOrderStream(orderId);
});
