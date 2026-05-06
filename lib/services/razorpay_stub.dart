import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:io' show Platform;

void openRazorpayCheckout({
  required String key,
  required int amount,
  required String name,
  required String description,
  required String contact,
  required String email,
  String currency = 'INR',
  String? orderId,
  required void Function(String paymentId, String orderId, String signature) onSuccess,
  required void Function(int code, String message) onFailure,
}) {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    onFailure(-1, 'Razorpay is only supported on Android, iOS, and Web. Desktop platforms are not supported.');
    return;
  }

  final razorpay = Razorpay();

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    razorpay.clear();
    onSuccess(
      response.paymentId ?? '',
      response.orderId ?? orderId ?? '',
      response.signature ?? '',
    );
  }

  void handlePaymentError(PaymentFailureResponse response) {
    razorpay.clear();
    onFailure(response.code ?? 0, response.message ?? 'Payment failed');
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    razorpay.clear();
    onFailure(0, 'External wallet selected: ${response.walletName}');
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

  final options = <String, dynamic>{
    'key': key,
    'amount': amount,
    'name': name,
    'description': description,
    'prefill': {
      'contact': contact,
      'email': email,
    },
    'theme': {
      'color': '#16a34a',
    }
  };

  if (orderId != null && orderId.isNotEmpty) {
    options['order_id'] = orderId;
  }
  
  if (currency.isNotEmpty) {
    options['currency'] = currency;
  }

  try {
    razorpay.open(options);
  } catch (e) {
    debugPrint('Error starting Razorpay: $e');
    razorpay.clear();
    onFailure(-1, 'Error starting Razorpay: $e');
  }
}
