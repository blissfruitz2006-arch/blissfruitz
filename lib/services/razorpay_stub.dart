void openRazorpayCheckout({
  required String key,
  required int amount,
  required String name,
  required String description,
  required String contact,
  required String email,
  String currency = 'INR',
  required void Function(String paymentId, String orderId, String signature) onSuccess,
  required void Function(int code, String message) onFailure,
}) {
  throw UnsupportedError('Cannot open Razorpay checkout without JS interop');
}
