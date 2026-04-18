import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../../../widgets/admin/admin_image_picker.dart';
import '../../../../config/theme.dart';
import '../../../../models/product.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/category_provider.dart';
import '../../../../providers/product_provider.dart';
import '../../../../services/admin_service.dart';
import '../components/admin_common_widgets.dart';
import '../../../../widgets/glass_card.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  final String? productId;
  const ProductFormScreen({super.key, this.product, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _stockController = TextEditingController(text: '0');
  final _imageUrlController = TextEditingController();
  
  int? _selectedCategoryId;
  bool _isActive = true;
  bool _isFeatured = false;
  String? _existingImagePath;
  int _imageSourceIndex = 0; // 0 for File, 1 for URL

  Uint8List? _uploadedImageBytes;
  String? _uploadedImageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields(widget.product!);
    } else if (widget.productId != null) {
      // In a real app we might want to fetch here or use ref.listen in build
      // For simplicity, we'll let the build method handle the loading state
    }
  }

  void _populateFields(Product p) {
    _nameController.text = p.name;
    _slugController.text = p.slug;
    _skuController.text = p.sku ?? '';
    _descriptionController.text = p.description ?? '';
    _shortDescriptionController.text = p.shortDescription ?? '';
    _priceController.text = p.price.toString();
    _comparePriceController.text = p.comparePrice != null ? p.comparePrice.toString() : '';
    _unitController.text = p.unit;
    _stockController.text = p.stockQuantity.toString();
    _selectedCategoryId = p.categoryId;
    _isActive = p.isActive;
    _isFeatured = p.isFeatured;
    _existingImagePath = p.imageMain;
    if (p.imageMain != null && p.imageMain!.startsWith('http')) {
      _imageUrlController.text = p.imageMain!;
      _imageSourceIndex = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // If we only have an ID, we need to fetch the product first
    if (widget.product == null && widget.productId != null) {
      final productAsync = ref.watch(productByIdProvider(widget.productId!));
      return productAsync.when(
        data: (product) {
          if (product == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Product not found')),
            );
          }
          // We can't call setState in build, so we'll use a post-frame callback
          // or just render the form with the fetched product
          return _buildForm(context, product);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      );
    }

    return _buildForm(context, widget.product);
  }

  Widget _buildForm(BuildContext context, Product? product) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // If we just got the product from provider, populate fields
    // This is a bit tricky since build can run many times
    // Better to handle population once
    if (product != null && _nameController.text.isEmpty && !_isLoading) {
      // Small delay to avoid setState during build
      Future.microtask(() {
        if (mounted) _populateFields(product);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Edit Product' : 'Add Product', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          )
        ),
        centerTitle: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Details Section
                  // Basic Details Section
                  const SectionHeader(title: 'Basic Details'),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('Product Name', Icons.shopping_bag_outlined),
                          validator: (v) => v!.isEmpty ? 'Name is required' : null,
                          onChanged: (val) {
                            if (product == null) {
                              _slugController.text = val.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]+'), '');
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _slugController,
                          style: GoogleFonts.beVietnamPro(fontSize: 15),
                          decoration: _inputDecoration('Slug (URL Handle)', Icons.link_rounded),
                          validator: (v) => v!.isEmpty ? 'Slug is required' : null,
                        ),
                        const SizedBox(height: 24),
                        categoriesAsync.when(
                          data: (categories) => DropdownButtonFormField<int>(
                            style: GoogleFonts.beVietnamPro(fontSize: 16, color: AppTheme.onSurface),
                            decoration: _inputDecoration('Category', Icons.category_outlined),
                            initialValue: categories.any((cat) => cat.id == _selectedCategoryId) 
                              ? _selectedCategoryId 
                              : null,
                            items: categories.map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text('Error loading categories', style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Pricing & Stock
                  const SectionHeader(title: 'Pricing & Inventory'),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _priceController,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                                decoration: _inputDecoration('Price (₹)', Icons.payments_outlined),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _comparePriceController,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant),
                                decoration: _inputDecoration('Old Price', Icons.strikethrough_s_rounded),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: _inputDecoration('Stocks', Icons.inventory_2_outlined),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _unitController,
                                style: GoogleFonts.beVietnamPro(fontSize: 16),
                                decoration: _inputDecoration('Unit', Icons.scale_outlined),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _skuController,
                                style: GoogleFonts.beVietnamPro(fontSize: 16),
                                decoration: _inputDecoration('SKU', Icons.qr_code_scanner_rounded),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Descriptions
                  const SectionHeader(title: 'Detailed Descriptions'),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _shortDescriptionController,
                          style: GoogleFonts.beVietnamPro(fontSize: 15),
                          decoration: _inputDecoration('Short Summary', Icons.short_text_rounded),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _descriptionController,
                          style: GoogleFonts.beVietnamPro(fontSize: 15),
                          decoration: _inputDecoration('Full Details', Icons.description_outlined).copyWith(
                            helperText: 'HTML tags supported (<b>, <i>, <br>, <ul>, etc.)',
                            helperStyle: TextStyle(color: AppTheme.primary, fontSize: 12),
                          ),
                          maxLines: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Display & Images
                  const SectionHeader(title: 'Media & Visibility'),
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminImagePicker(
                          initialValue: _existingImagePath,
                          folder: 'products',
                          onChanged: (url, bytes, name) {
                            setState(() {
                              if (url != null) {
                                _imageUrlController.text = url;
                                _imageSourceIndex = 1;
                              } else {
                                _uploadedImageBytes = bytes;
                                _uploadedImageName = name;
                                _imageSourceIndex = 0;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _buildToggleSwitch(
                                'Storefront Visibility', 
                                'Show product to customers', 
                                _isActive, 
                                (v) => setState(() => _isActive = v)
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildToggleSwitch(
                                'Promotion Feature', 
                                'Highlight on homepage', 
                                _isFeatured, 
                                (v) => setState(() => _isFeatured = v)
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _saveProductById(product),
                      child: Text(
                        'Save Product Changes', 
                        style: GoogleFonts.outfit(
                          fontSize: 16, 
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      labelStyle: GoogleFonts.beVietnamPro(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }


  Widget _buildToggleSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.beVietnamPro(fontSize: 11, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProductById(Product? product) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? imagePath = _existingImagePath;
      
      if (_imageSourceIndex == 1 && _imageUrlController.text.isNotEmpty) {
        imagePath = _imageUrlController.text.trim();
      } else if (_uploadedImageBytes != null && _uploadedImageName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueName = '${timestamp}_$_uploadedImageName';
        imagePath = await AdminService.uploadImageBytes(
          'products', 
          uniqueName, 
          _uploadedImageBytes!, 
          'image/jpeg'
        );
      }
      
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'slug': _slugController.text.trim(),
        'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'shortDescription': _shortDescriptionController.text.trim().isEmpty ? null : _shortDescriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'comparePrice': double.tryParse(_comparePriceController.text),
        'unit': _unitController.text.trim().isEmpty ? 'kg' : _unitController.text.trim(),
        'stockQuantity': int.tryParse(_stockController.text) ?? 0,
        'categoryId': _selectedCategoryId,
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'imageMain': imagePath,
      };

      if (product != null) {
        await AdminService.updateProduct(product.id, data);
      } else {
        await AdminService.createProduct(data);
      }
      
      ref.invalidate(adminProductsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(productsProvider);
      if (product != null) {
        ref.invalidate(productBySlugProvider(product.slug));
        ref.invalidate(productByIdProvider(product.id.toString()));
      }
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product saved successfully!', style: GoogleFonts.outfit()))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e', style: GoogleFonts.outfit()))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
