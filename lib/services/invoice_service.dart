import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

class InvoiceService {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  static Future<void> printInvoice(Order order) async {
    try {
      final pdf = await generateInvoice(order);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${order.orderNumber ?? order.id}.pdf',
      );
    } catch (e) {
      debugPrint('Error printing invoice: $e');
    }
  }

  static Future<void> downloadInvoice(Order order) async {
    try {
      final pdf = await generateInvoice(order);
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        // Trigger a layout which allows saving/printing on web
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Invoice_${order.orderNumber ?? order.id}.pdf',
          format: PdfPageFormat.a4,
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'Invoice_${order.orderNumber ?? order.id}.pdf',
        );
      }
    } catch (e) {
      debugPrint('Error downloading invoice: $e');
    }
  }

  static Future<void> printShippingLabel(Order order) async {
    try {
      final pdf = await generateShippingLabel(order);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'ShippingLabel_${order.orderNumber ?? order.id}.pdf',
      );
    } catch (e) {
      debugPrint('Error printing shipping label: $e');
    }
  }

  static Future<void> downloadShippingLabel(Order order) async {
    try {
      final pdf = await generateShippingLabel(order);
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'ShippingLabel_${order.orderNumber ?? order.id}.pdf',
          format: PdfPageFormat.a4,
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'ShippingLabel_${order.orderNumber ?? order.id}.pdf',
        );
      }
    } catch (e) {
      debugPrint('Error downloading shipping label: $e');
    }
  }

  static Future<pw.Document> generateInvoice(Order order) async {
    final pdf = pw.Document();
    final settings = await SettingsService.getGeneralSettings();
    bool useFallbackFont = false;
    
    pw.Font? font;
    pw.Font? boldFont;

    try {
      // Load font that supports Rupee symbol with extended timeout
      font = await PdfGoogleFonts.interRegular().timeout(const Duration(seconds: 15));
      boldFont = await PdfGoogleFonts.interBold().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Font loading failed, using fallback: $e');
      useFallbackFont = true;
    }

    String clean(double amount) {
      String formatted = _currencyFormat.format(amount);
      if (useFallbackFont || font == null) {
        // Helvetica (default) doesn't support ₹
        return formatted.replaceAll('₹', 'Rs. ');
      }
      return formatted;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (context) => [
          _buildHeader(settings),
          pw.SizedBox(height: 20),
          _buildOrderInfo(order),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(order),
          pw.SizedBox(height: 30),
          _buildItemsTable(order.items, clean),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          _buildSummary(order, clean),
          pw.SizedBox(height: 50),
          _buildFooter(settings),
        ],
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generateShippingLabel(Order order) async {
    final pdf = pw.Document();
    final settings = await SettingsService.getGeneralSettings();
    
    pw.Font? font;
    pw.Font? boldFont;
    try {
      font = await PdfGoogleFonts.interRegular().timeout(const Duration(seconds: 5));
      boldFont = await PdfGoogleFonts.interBold().timeout(const Duration(seconds: 5));
    } catch (_) {}

    // Sticker format: 4x6 inches approx
    const stickerFormat = PdfPageFormat(4 * PdfPageFormat.inch, 6 * PdfPageFormat.inch, 
      marginBottom: 0.2 * PdfPageFormat.inch, 
      marginTop: 0.2 * PdfPageFormat.inch, 
      marginLeft: 0.2 * PdfPageFormat.inch, 
      marginRight: 0.2 * PdfPageFormat.inch);

    pdf.addPage(
      pw.Page(
        pageFormat: stickerFormat,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          padding: const pw.EdgeInsets.all(15),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text((settings.siteName ?? 'BLISSFRUITZ').toUpperCase(), 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.green800)),
              ),
              pw.Center(
                child: pw.Text('PREMIUM FRESH FRUITS', 
                  style: pw.TextStyle(fontSize: 8, letterSpacing: 2)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              
              pw.Text('TO / SHIP TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text(order.shippingName ?? 'CUSTOMER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 5),
              pw.Text(order.shippingAddress ?? '', style: pw.TextStyle(fontSize: 12)),
              pw.Text('${order.shippingCity}, ${order.shippingState} - ${order.shippingPincode}', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('Mobile: ${order.shippingPhone ?? ''}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              
              pw.Spacer(),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ORDER ID:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.orderNumber ?? '#${order.id}', style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DATE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.createdAt != null ? DateFormat('dd-MM-yyyy').format(order.createdAt!) : '',
                        style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.SizedBox(
                  height: 60,
                  width: 200,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: order.orderNumber ?? order.id.toString(),
                    drawText: true,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Standard Shipping', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(GeneralSettings settings) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text((settings.siteName ?? 'BLISSFRUITZ').toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2E7D32), // green800
                )),
            pw.Text('Premium Fresh Fruits',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.Text('${settings.phone != null ? "Tel: ${settings.phone} | " : ""}${settings.siteName != null ? "www.${settings.siteName?.toLowerCase().replaceAll(' ', '')}.com" : "www.blissfruitz.com"}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                )),
            pw.Text('Original for Receiver', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildOrderInfo(Order order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Order Number', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.Text(order.orderNumber ?? '#${order.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Order Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.Text(order.createdAt != null ? _dateFormat.format(order.createdAt!) : '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
              pw.Text(order.orderStatus.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(Order order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DELIVERY TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(order.shippingName ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text(order.shippingAddress ?? '', style: pw.TextStyle(fontSize: 11)),
              pw.Text('${order.shippingCity}, ${order.shippingState} - ${order.shippingPincode}', style: pw.TextStyle(fontSize: 11)),
              pw.Text('Phone: ${order.shippingPhone ?? ''}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              if (order.guestEmail != null) pw.Text('Email: ${order.guestEmail}', style: pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('PAYMENT INFORMATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Payment Status: '),
                  pw.Text(order.paymentStatus.toUpperCase(), 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: order.paymentStatus == 'paid' ? PdfColors.green : PdfColors.red)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Method: '),
                  pw.Text(order.paymentMethod?.toUpperCase() ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (order.razorpayPaymentId != null)
                pw.Text('Transaction ID: ${order.razorpayPaymentId}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<OrderItem> items, String Function(double) clean) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: items.map((item) => [
        item.name,
        item.quantity.toString(),
        clean(item.price),
        clean(item.totalPrice),
      ]).toList(),
      cellStyle: const pw.TextStyle(fontSize: 10),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static pw.Widget _buildSummary(Order order, String Function(double) clean) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          children: [
            pw.SizedBox(height: 10),
            _buildSummaryRow('Subtotal', clean(order.subtotal)),
            if (order.discountAmount > 0)
              _buildSummaryRow('Discount (${order.couponCode ?? "Coupon"})', '- ${clean(order.discountAmount)}', color: PdfColors.red),
            _buildSummaryRow('Shipping Charges', clean(order.shippingAmount)),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            _buildSummaryRow('Total Amount', clean(order.total), isBold: true, fontSize: 14),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 5),
            pw.Text('Amounts are inclusive of all taxes.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 11, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(GeneralSettings settings) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('This is a computer-generated invoice and does not require a signature.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text('Thank you for choosing ${settings.siteName ?? "BlissFruitz"}!',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        ),
        if (settings.address != null)
          pw.Center(
            child: pw.Text(settings.address!, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
        pw.Center(
          child: pw.Text('Follow us on Instagram for fresh updates!',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ),
      ],
    );
  }
}
