import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/order.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';

class EmailService {
  static final _client = SupabaseConfig.client;

  /// Send order confirmation email
  static Future<void> sendOrderConfirmation(Order order) async {
    final email = order.guestEmail;
    if (email == null || email.isEmpty) {
      debugPrint('EmailService: No email found for order ${order.orderNumber}');
      return;
    }

    final settings = await SettingsService.getGeneralSettings();
    final storeName = settings.siteName ?? 'BlissFruitz';

    final subject = 'Order Confirmed - ${order.orderNumber}';
    final html = '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #f0f0f0; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
        <div style="background-color: #4CAF50; color: white; padding: 25px; text-align: center;">
          <h1 style="margin: 0; font-size: 24px;">Thank you for your order!</h1>
          <p style="margin: 10px 0 0 0; opacity: 0.9;">Order #${order.orderNumber}</p>
        </div>
        <div style="padding: 30px; line-height: 1.6; color: #333;">
          <p>Hi <strong>${order.shippingName}</strong>,</p>
          <p>We've received your order and we're getting it ready for you. You'll receive another email when it's on the way!</p>
          
          <div style="background-color: #f9f9f9; padding: 20px; border-radius: 6px; margin: 25px 0;">
            <h3 style="margin-top: 0; color: #4CAF50;">Order Summary</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 5px 0; color: #666;">Total Amount:</td>
                <td style="padding: 5px 0; text-align: right; font-weight: bold;">₹${order.total.toStringAsFixed(2)}</td>
              </tr>
              <tr>
                <td style="padding: 5px 0; color: #666;">Payment Method:</td>
                <td style="padding: 5px 0; text-align: right;">${order.paymentMethod?.toUpperCase() ?? 'N/A'}</td>
              </tr>
            </table>
          </div>

          <p>Shipping to:<br/>
          <span style="color: #666;">
            ${order.shippingAddress},<br/>
            ${order.shippingCity}, ${order.shippingState} - ${order.shippingPincode}
          </span></p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;"/>
          
          <p style="margin-bottom: 0;">Best regards,</p>
          <p style="margin-top: 5px; font-weight: bold; color: #4CAF50;">The $storeName Team</p>
        </div>
        <div style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 12px; color: #999;">
          &copy; ${DateTime.now().year} $storeName. All rights reserved.
        </div>
      </div>
    ''';

    try {
      await _client.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': subject,
          'html': html,
        },
      );
      debugPrint('EmailService: Sent confirmation email to $email');
    } catch (e) {
      debugPrint('EmailService Error (Confirmation): $e');
    }
  }

  /// Send shipping update email
  static Future<void> sendOrderShipped(Order order) async {
    final email = order.guestEmail;
    if (email == null || email.isEmpty) return;

    final settings = await SettingsService.getGeneralSettings();
    final storeName = settings.siteName ?? 'BlissFruitz';

    final subject = 'Your Order is on the way! - ${order.orderNumber}';
    final html = '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #f0f0f0; border-radius: 8px; overflow: hidden;">
        <div style="background-color: #2196F3; color: white; padding: 25px; text-align: center;">
          <h1 style="margin: 0; font-size: 24px;">Your order has shipped!</h1>
          <p style="margin: 10px 0 0 0; opacity: 0.9;">Order #${order.orderNumber}</p>
        </div>
        <div style="padding: 30px; line-height: 1.6; color: #333;">
          <p>Hi <strong>${order.shippingName}</strong>,</p>
          <p>Great news! Your order is on its way to you.</p>
          
          ${order.trackingNumber != null ? '''
          <div style="background-color: #e3f2fd; padding: 20px; border-radius: 6px; margin: 25px 0; text-align: center;">
            <p style="margin-top: 0; color: #1976D2; font-weight: bold;">Tracking Details</p>
            <p style="font-size: 20px; margin: 10px 0;">${order.trackingNumber}</p>
            ${order.locationLink != null ? '''
            <a href="${order.locationLink}" style="background-color: #2196F3; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px; font-weight: bold;">Track My Package</a>
            ''' : ''}
          </div>
          ''' : ''}

          <p>Expect your delivery soon. Thank you for shopping with us!</p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;"/>
          
          <p style="margin-bottom: 0;">Best regards,</p>
          <p style="margin-top: 5px; font-weight: bold; color: #2196F3;">The $storeName Team</p>
        </div>
        <div style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 12px; color: #999;">
          &copy; ${DateTime.now().year} $storeName. All rights reserved.
        </div>
      </div>
    ''';

    try {
      await _client.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': subject,
          'html': html,
        },
      );
      debugPrint('EmailService: Sent shipping email to $email');
    } catch (e) {
      debugPrint('EmailService Error (Shipped): $e');
    }
  }

  /// Send order completed email with PDF invoice attachment
  static Future<void> sendOrderCompletedWithInvoice(Order order) async {
    final email = order.guestEmail;
    if (email == null || email.isEmpty) return;

    final settings = await SettingsService.getGeneralSettings();
    final storeName = settings.siteName ?? 'BlissFruitz';

    final subject = 'Order Delivered & Invoice - ${order.orderNumber}';
    final html = '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #f0f0f0; border-radius: 8px; overflow: hidden;">
        <div style="background-color: #673AB7; color: white; padding: 25px; text-align: center;">
          <h1 style="margin: 0; font-size: 24px;">Order Delivered!</h1>
          <p style="margin: 10px 0 0 0; opacity: 0.9;">Order #${order.orderNumber}</p>
        </div>
        <div style="padding: 30px; line-height: 1.6; color: #333;">
          <p>Hi <strong>${order.shippingName}</strong>,</p>
          <p>Your order has been successfully delivered. We hope you love your fresh fruits!</p>
          <p>For your records, we have attached the official invoice to this email.</p>
          
          <div style="background-color: #f3e5f5; padding: 15px; border-radius: 6px; margin: 25px 0; border-left: 4px solid #673AB7;">
            <p style="margin: 0; color: #512DA8;"><strong>Note:</strong> You can also download your invoice anytime from the "My Orders" section in our app.</p>
          </div>

          <p>Thank you for choosing $storeName. We look forward to serving you again!</p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;"/>
          
          <p style="margin-bottom: 0;">Best regards,</p>
          <p style="margin-top: 5px; font-weight: bold; color: #673AB7;">The $storeName Team</p>
        </div>
        <div style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 12px; color: #999;">
          &copy; ${DateTime.now().year} $storeName. All rights reserved.
        </div>
      </div>
    ''';

    try {
      debugPrint('EmailService: Generating invoice for order ${order.orderNumber}...');
      // Generate PDF Invoice
      final pdfDoc = await InvoiceService.generateInvoice(order);
      final pdfBytes = await pdfDoc.save();
      final base64Pdf = base64Encode(pdfBytes);

      await _client.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': subject,
          'html': html,
          'attachments': [
            {
              'filename': 'Invoice_${order.orderNumber}.pdf',
              'content': base64Pdf,
              'contentType': 'application/pdf',
            }
          ],
        },
      );
      debugPrint('EmailService: Sent completed email with invoice to $email');
    } catch (e) {
      debugPrint('EmailService Error (Completed/Invoice): $e');
    }
  }
}
