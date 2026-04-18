import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import '../../../config/theme.dart';
import '../../../services/admin_service.dart';
import '../../../models/product.dart';
import './components/admin_common_widgets.dart';

class StickerGeneratorScreen extends ConsumerStatefulWidget {
  const StickerGeneratorScreen({super.key});

  @override
  ConsumerState<StickerGeneratorScreen> createState() => _StickerGeneratorScreenState();
}

class _StickerGeneratorScreenState extends ConsumerState<StickerGeneratorScreen> {
  Product? _selectedProduct;
  List<Product> _products = [];
  bool _isLoading = true;
  
  // Sticker Settings
  Map<String, dynamic>? _stickerSettings;
  Map<String, dynamic>? _generalSettings;

  // Dynamic Fields
  late TextEditingController _batchController;
  late TextEditingController _quantityController;
  late TextEditingController _mrpController;
  late TextEditingController _sellPriceController;
  late TextEditingController _ingredientsController;
  DateTime _pkdDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _batchController = TextEditingController();
    _quantityController = TextEditingController();
    _mrpController = TextEditingController();
    _sellPriceController = TextEditingController();
    _ingredientsController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _quantityController.dispose();
    _mrpController.dispose();
    _sellPriceController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final products = await AdminService.getAdminProducts();
      final stickerSettings = await AdminService.getSettings('settings_package_sticker');
      final generalSettings = await AdminService.getSettings('settings_general');
      
      setState(() {
        _products = products;
        _stickerSettings = stickerSettings;
        _generalSettings = generalSettings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sticker generator data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onProductSelected(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _mrpController.text = (product.comparePrice ?? product.price).toStringAsFixed(2);
        _sellPriceController.text = product.price.toStringAsFixed(2);
        _quantityController.text = product.unit;
        _ingredientsController.text = _stripHtml(product.description ?? '');
      }
    });
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    // Basic HTML stripping logic
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>|&nbsp;|&amp;|&quot;|&rsquo;|&#39;|&lt;|&gt;'), ' ');
    // Remove extra whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  Future<void> _generateSticker() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first')),
      );
      return;
    }

    final pdf = pw.Document();
    
    // Get sticker dimensions from settings or use 3x2 inch as requested
    final double width = (_stickerSettings?['sticker_width_mm'] ?? 76.2) * PdfPageFormat.mm;
    final double height = (_stickerSettings?['sticker_height_mm'] ?? 50.8) * PdfPageFormat.mm;
    final double fontSize = _stickerSettings?['font_size'] ?? 7.0;

    final barcode = Barcode.code128();
    final barcodeSvg = barcode.toSvg(
      _selectedProduct!.sku ?? _selectedProduct!.id.toString(),
      width: 140,
      height: 35,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height, marginAll: 0),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
              // Header Row: Brand & FSSAI
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    (_stickerSettings?['company_name'] ?? _generalSettings?['site_name'] ?? 'BlissFruitz').toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize + 3),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('fssai', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize - 2)),
                      pw.Text('Lic No: ${_stickerSettings?['fssai_license'] ?? 'N/A'}', style: pw.TextStyle(fontSize: fontSize - 2)),
                    ]
                  )
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Product Name Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 0.5),
                    bottom: pw.BorderSide(width: 0.5),
                  ),
                ),
                child: pw.Text(
                  _selectedProduct!.name.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize + 1),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),
              
              // Key Details Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfInfoRow('BATCH NO', _batchController.text, fontSize),
                        _buildPdfInfoRow('PKD DATE', DateFormat('dd/MM/yyyy').format(_pkdDate), fontSize),
                        _buildPdfInfoRow('NET QTY', _quantityController.text, fontSize),
                      ]
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('MRP: Rs. ${_mrpController.text}', 
                                style: pw.TextStyle(
                                  fontSize: fontSize - 3, 
                                  decoration: pw.TextDecoration.lineThrough,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text('OFFER PRICE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize - 3)),
                                  pw.Text('Rs. ${_sellPriceController.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize + 1)),
                                ],
                              ),
                              if (double.tryParse(_mrpController.text) != null && 
                                  double.tryParse(_sellPriceController.text) != null &&
                                  double.parse(_mrpController.text) > double.parse(_sellPriceController.text))
                                pw.Container(
                                  margin: const pw.EdgeInsets.only(top: 1),
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                  decoration: const pw.BoxDecoration(color: PdfColors.black),
                                  child: pw.Text(
                                    'SAVE ${((double.parse(_mrpController.text) - double.parse(_sellPriceController.text)) / double.parse(_mrpController.text) * 100).round()}%',
                                    style: pw.TextStyle(color: PdfColors.white, fontSize: fontSize - 3, fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                            ]
                          ),
                        ),
                      ]
                    ),
                  ),
                ]
              ),

              pw.SizedBox(height: 6),
              
              // Ingredients / Notes
              if (_ingredientsController.text.isNotEmpty) ...[
                pw.Text('INGREDIENTS: ${_stripHtml(_ingredientsController.text)}', 
                  style: pw.TextStyle(fontSize: fontSize - 2.5),
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
              ],

              pw.Spacer(),
              
              // Footer: Contact & Barcode
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Marketed by: BlissFruitz Enterprises', style: pw.TextStyle(fontSize: fontSize - 3)),
                        pw.Text('Customer Care: ${_stickerSettings?['customer_care_phone'] ?? _generalSettings?['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: fontSize - 3)),
                        pw.Text('Email: ${_stickerSettings?['customer_care_email'] ?? _generalSettings?['email'] ?? 'N/A'}', style: pw.TextStyle(fontSize: fontSize - 3)),
                      ]
                    ),
                  ),
                  if (_stickerSettings?['show_barcode'] ?? true)
                    pw.Container(
                      height: 25,
                      width: 80,
                      child: pw.SvgImage(svg: barcodeSvg),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

    // Use specific page format for printing to ensure same layout
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      format: PdfPageFormat(width, height, marginAll: 0),
      name: 'sticker_${_selectedProduct!.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Package Sticker Generator', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Sticker Details',
                  subtitle: 'Select a product and configure unit-specific details',
                  trailing: ElevatedButton.icon(
                    onPressed: _generateSticker,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Generate & Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Configuration Form
                    Expanded(
                      flex: 3,
                      child: AdminGlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('SELECT PRODUCT'),
                            Autocomplete<Product>(
                              displayStringForOption: (Product product) => product.name,
                              initialValue: TextEditingValue(text: _selectedProduct?.name ?? ''),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text == '') {
                                  return _products;
                                }
                                return _products.where((Product product) {
                                  return product.name.toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (Product selection) {
                                _onProductSelected(selection);
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                    hintText: 'Type to search product...',
                                    suffixIcon: const Icon(Icons.search_rounded),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(16),
                                    clipBehavior: Clip.antiAlias,
                                    child: Container(
                                      width: 400, // Fixed width for the options menu
                                      constraints: const BoxConstraints(maxHeight: 300),
                                      color: isDark ? AppTheme.darkSurface : Colors.white,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final Product option = options.elementAt(index);
                                          return ListTile(
                                            title: Text(option.name, style: GoogleFonts.beVietnamPro(fontSize: 14)),
                                            subtitle: Text('SKU: ${option.sku ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
                                            onTap: () => onSelected(option),
                                            hoverColor: AppTheme.primary.withValues(alpha: 0.1),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('BATCH NO'),
                                      TextFormField(
                                        controller: _batchController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                          hintText: 'e.g. B2024-01',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('PKD DATE'),
                                      InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _pkdDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) setState(() => _pkdDate = date);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: isDark ? Colors.white10 : AppTheme.outlineVariant),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 18),
                                              const SizedBox(width: 12),
                                              Text(DateFormat('dd MMM yyyy').format(_pkdDate)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('NET QUANTITY'),
                                      TextFormField(
                                        controller: _quantityController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                          hintText: 'e.g. 1 kg',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('MRP (RS)'),
                                      TextFormField(
                                        controller: _mrpController,
                                        onChanged: (_) => setState(() {}),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                          hintText: '0.00',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('SELL PRICE (RS)'),
                                      TextFormField(
                                        controller: _sellPriceController,
                                        onChanged: (_) => setState(() {}),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                          hintText: '0.00',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            _buildLabel('INGREDIENTS / NOTES'),
                            TextFormField(
                              controller: _ingredientsController,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                fillColor: isDark ? Colors.black26 : AppTheme.surfaceContainerLow,
                                hintText: 'List of ingredients or additional notes...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    
                    // Live Preview
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('STIKER PREVIEW'),
                          const SizedBox(height: 8),
                          AdminGlassCard(
                            padding: const EdgeInsets.all(24),
                            child: _buildStickerPreview(),
                          ),
                          const SizedBox(height: 24),
                          AdminGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow('Width', '${_stickerSettings?['sticker_width_mm'] ?? 50}mm'),
                                _buildInfoRow('Height', '${_stickerSettings?['sticker_height_mm'] ?? 25}mm'),
                                _buildInfoRow('Font Size', '${_stickerSettings?['font_size'] ?? 6}pt'),
                                const Divider(),
                                Text(
                                  'Change these in Sticker Settings',
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize - 2)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize - 2)),
        ],
      ),
    );
  }

  Widget _buildStickerPreview() {
    if (_selectedProduct == null) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text('Select a product to see preview', style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (_stickerSettings?['company_name'] ?? _generalSettings?['site_name'] ?? 'BlissFruitz').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('fssai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.black)),
                    Text('Lic No: 1234567890', style: TextStyle(fontSize: 7, color: Colors.black)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Product Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(width: 0.5), bottom: BorderSide(width: 0.5)),
              ),
              child: Text(
                _selectedProduct!.name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            
            // Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewRow('BATCH', _batchController.text),
                      _buildPreviewRow('PKD', DateFormat('dd/MM/yyyy').format(_pkdDate)),
                      _buildPreviewRow('QTY', _quantityController.text),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(border: Border.all(width: 0.5)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('MRP: Rs. ${_mrpController.text}', 
                            style: const TextStyle(
                              fontSize: 6, 
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('OFFER PRICE:', style: TextStyle(fontSize: 6, color: Colors.black)),
                              Text('Rs. ${_sellPriceController.text}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.black),
                              ),
                            ],
                          ),
                          if (double.tryParse(_mrpController.text) != null && 
                              double.tryParse(_sellPriceController.text) != null &&
                              double.parse(_mrpController.text) > double.parse(_sellPriceController.text))
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              color: Colors.black,
                              child: Text(
                                'SAVE ${((double.parse(_mrpController.text) - double.parse(_sellPriceController.text)) / double.parse(_mrpController.text) * 100).round()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Ingredients in Preview
            if (_ingredientsController.text.isNotEmpty) ...[
              Text(
                'INGREDIENTS: ${_stripHtml(_ingredientsController.text)}',
                style: const TextStyle(fontSize: 6, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const Spacer(),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marketed by: BlissFruitz Enterprises', style: TextStyle(fontSize: 6, color: Colors.black)),
                    Text('Customer Care: +91 9876543210', style: TextStyle(fontSize: 6, color: Colors.black)),
                  ],
                ),
                Container(
                  height: 20,
                  width: 60,
                  color: Colors.black,
                  child: const Center(child: Text('||||||||||', style: TextStyle(color: Colors.white, fontSize: 8))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 7, color: Colors.black)),
          Text(value, style: const TextStyle(fontSize: 7, color: Colors.black)),
        ],
      ),
    );
  }
}
