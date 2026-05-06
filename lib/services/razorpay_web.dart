import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

@JS('Razorpay')
extension type Razorpay._(JSObject _) implements JSObject {
  external Razorpay(JSObject options);
  external void open();
}

extension type RazorpayResponse._(JSObject _) implements JSObject {
  @JS('razorpay_payment_id')
  external String get razorpayPaymentId;
  
  @JS('razorpay_order_id')
  external String? get razorpayOrderId;
  
  @JS('razorpay_signature')
  external String? get razorpaySignature;

  String get paymentId => razorpayPaymentId;
  String? get orderId => razorpayOrderId;
  String? get signature => razorpaySignature;
}

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
  try {
    if (globalContext.getProperty('Razorpay'.toJS).isUndefinedOrNull) {
      debugPrint('CRITICAL: Razorpay SDK not found on window object.');
      onFailure(-1, 'Razorpay SDK not loaded. Please ensure you are online and refresh the page.');
      return;
    }

    final options = JSObject();
    options.setProperty('key'.toJS, key.toJS);
    options.setProperty('amount'.toJS, amount.toJS);
    options.setProperty('currency'.toJS, currency.toJS);
    options.setProperty('name'.toJS, name.toJS);
    options.setProperty('description'.toJS, description.toJS);
    
    if (orderId != null && orderId.isNotEmpty) {
      options.setProperty('order_id'.toJS, orderId.toJS);
    }

    final prefill = JSObject();
    prefill.setProperty('contact'.toJS, contact.toJS);
    prefill.setProperty('email'.toJS, email.toJS);
    options.setProperty('prefill'.toJS, prefill);

    options.setProperty('handler'.toJS, ((RazorpayResponse response) {
      onSuccess(
        response.paymentId, 
        response.orderId ?? '', 
        response.signature ?? ''
      );
    }).toJS);

    final modal = JSObject();
    modal.setProperty('ondismiss'.toJS, (() {
      onFailure(0, 'Checkout dismissed by user');
    }).toJS);
    options.setProperty('modal'.toJS, modal);

    final theme = JSObject();
    theme.setProperty('color'.toJS, '#16a34a'.toJS);
    options.setProperty('theme'.toJS, theme);

    final razorpay = Razorpay(options);
    razorpay.open();
  } catch (e) {
    debugPrint('Error in openRazorpayCheckout: $e');
    onFailure(-2, 'Internal error opening Razorpay: $e');
  }
}
