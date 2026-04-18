import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../../models/coupon.dart';
import '../../models/blog_post.dart';
import '../../models/offer.dart';
import '../../models/banner_model.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';
import 'admin_image_picker.dart';
import '../glass_card.dart';

class CouponFormDialog extends StatefulWidget {
  final Coupon? coupon;
  final VoidCallback onSaved;

  const CouponFormDialog({super.key, this.coupon, required this.onSaved});

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _discountController;
  late TextEditingController _minOrderController;
  String _discountType = 'percent';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code);
    _discountController = TextEditingController(text: widget.coupon?.discountValue.toString());
    _minOrderController = TextEditingController(text: widget.coupon?.minOrder.toString() ?? '0');
    _discountType = widget.coupon?.discountType ?? 'percent';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'code': _codeController.text.trim().toUpperCase(),
        'discountValue': double.tryParse(_discountController.text) ?? 0,
        'discountType': _discountType,
        'minOrder': double.tryParse(_minOrderController.text) ?? 0,
        'isActive': true,
      };

      if (widget.coupon != null) {
        await AdminService.updateCoupon(widget.coupon!.id, data);
      } else {
        await AdminService.createCoupon(data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    widget.coupon == null ? 'Add Coupon' : 'Edit Coupon',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Coupon Code',
                          hintText: 'e.g. WELCOME10',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: ['percent', 'flat'].contains(_discountType) ? _discountType : 'percent',
                        decoration: const InputDecoration(labelText: 'Discount Type'),
                        items: const [
                          DropdownMenuItem(value: 'percent', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'flat', child: Text('Flat Amount (₹)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _discountType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountController,
                        decoration: const InputDecoration(labelText: 'Discount Value'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minOrderController,
                        decoration: const InputDecoration(labelText: 'Min Order Amount'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Coupon'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogFormDialog extends StatefulWidget {
  final BlogPost? blog;
  final VoidCallback onSaved;

  const BlogFormDialog({super.key, this.blog, required this.onSaved});

  @override
  State<BlogFormDialog> createState() => _BlogFormDialogState();
}

class _BlogFormDialogState extends State<BlogFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _excerptController;
  late TextEditingController _authorController;
  
  String? _imagePath;
  Uint8List? _uploadedBytes;
  String? _uploadedName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blog?.title);
    _contentController = TextEditingController(text: widget.blog?.content);
    _excerptController = TextEditingController(text: widget.blog?.excerpt);
    _authorController = TextEditingController(text: widget.blog?.author ?? 'Admin');
    _imagePath = widget.blog?.coverImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? finalImagePath = _imagePath;

      if (_uploadedBytes != null) {
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_uploadedName';
        finalImagePath = await AdminService.uploadImageBytes('blog', uniqueName, _uploadedBytes!, 'image/jpeg');
      }

      final slug = _titleController.text.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');

      final data = {
        'title': _titleController.text.trim(),
        'slug': widget.blog?.slug ?? slug,
        'content': _contentController.text.trim(),
        'excerpt': _excerptController.text.trim(),
        'author': _authorController.text.trim(),
        'coverImage': finalImagePath,
        'isPublished': true,
        'publishedAt': widget.blog?.publishedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      if (widget.blog != null) {
        await AdminService.updateBlog(widget.blog!.id, data);
      } else {
        await AdminService.createBlog(data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    widget.blog == null ? 'New Blog Post' : 'Edit Blog Post',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AdminImagePicker(
                        initialValue: _imagePath,
                        folder: 'blog',
                        onChanged: (url, bytes, name) {
                          setState(() {
                            _imagePath = url;
                            _uploadedBytes = bytes;
                            _uploadedName = name;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _excerptController,
                        decoration: const InputDecoration(labelText: 'Excerpt'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Markdown/HTML supported',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(labelText: 'Author Name'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publish Post'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferFormDialog extends StatefulWidget {
  final Offer? offer;
  final VoidCallback onSaved;

  const OfferFormDialog({super.key, this.offer, required this.onSaved});

  @override
  State<OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends State<OfferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _codeController;
  late TextEditingController _discountController;
  late TextEditingController _orderController;
  
  String? _imagePath;
  Uint8List? _uploadedBytes;
  String? _uploadedName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.offer?.title);
    _descController = TextEditingController(text: widget.offer?.description);
    _codeController = TextEditingController(text: widget.offer?.couponCode);
    _discountController = TextEditingController(text: widget.offer?.discountValue.toString());
    _orderController = TextEditingController(text: (widget.offer?.sortOrder ?? 0).toString());
    _imagePath = widget.offer?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _codeController.dispose();
    _discountController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? finalImagePath = _imagePath;

      if (_uploadedBytes != null) {
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_uploadedName';
        finalImagePath = await AdminService.uploadImageBytes('offers', uniqueName, _uploadedBytes!, 'image/jpeg');
      }

      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'couponCode': _codeController.text.trim(),
        'discountValue': double.tryParse(_discountController.text) ?? 0.0,
        'sort_order': int.tryParse(_orderController.text) ?? 0,
        'image_url': finalImagePath,
        'isActive': true,
      };

      if (widget.offer != null) {
        await AdminService.updateOffer(widget.offer!.id, data);
      } else {
        await AdminService.createOffer(data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    widget.offer == null ? 'New Offer' : 'Edit Offer',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AdminImagePicker(
                        initialValue: _imagePath,
                        folder: 'offers',
                        onChanged: (url, bytes, name) {
                          setState(() {
                            _imagePath = url;
                            _uploadedBytes = bytes;
                            _uploadedName = name;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(labelText: 'Coupon Code'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              decoration: const InputDecoration(labelText: 'Discount Text'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orderController,
                        decoration: const InputDecoration(labelText: 'Sort Order'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Offer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerFormDialog extends StatefulWidget {
  final BannerModel? banner;
  final VoidCallback onSaved;

  const BannerFormDialog({super.key, this.banner, required this.onSaved});

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _linkController;
  late TextEditingController _orderController;
  String _placement = 'home_top';
  
  String? _imagePath;
  Uint8List? _uploadedBytes;
  String? _uploadedName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title);
    _subtitleController = TextEditingController(text: widget.banner?.subtitle);
    _linkController = TextEditingController(text: widget.banner?.linkUrl);
    _orderController = TextEditingController(text: (widget.banner?.sortOrder ?? 0).toString());
    _placement = (widget.banner?.placement ?? 'hero').toLowerCase().trim();
    if (!['hero', 'home_top', 'home_middle', 'home_bottom'].contains(_placement)) {
      _placement = 'hero';
    }
    _imagePath = widget.banner?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null && _uploadedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String finalImagePath = _imagePath ?? '';

      if (_uploadedBytes != null) {
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_uploadedName';
        finalImagePath = await AdminService.uploadImageBytes('banners', uniqueName, _uploadedBytes!, 'image/jpeg');
      }

      final data = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'linkUrl': _linkController.text.trim(),
        'placement': _placement,
        'sortOrder': int.tryParse(_orderController.text) ?? 0,
        'imagePath': finalImagePath,
        'isActive': true,
      };

      if (widget.banner != null) {
        await AdminService.updateBanner(widget.banner!.id, data);
      } else {
        await AdminService.createBanner(data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Internal Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    widget.banner == null ? 'New Banner' : 'Edit Banner',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BANNER VISUAL',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AdminImagePicker(
                        initialValue: _imagePath,
                        folder: 'banners',
                        onChanged: (url, bytes, name) {
                          setState(() {
                            _imagePath = url;
                            _uploadedBytes = bytes;
                            _uploadedName = name;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'CONFIGURATION',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Summer Sale 2024',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                          hintText: 'e.g. Up to 50% Off',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          labelText: 'Action URL',
                          hintText: '/shop/organic-fruits',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _placement,
                        decoration: const InputDecoration(labelText: 'Placement'),
                        items: ['hero', 'home_top', 'home_middle', 'home_bottom']
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.replaceAll('_', ' ').toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _placement = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orderController,
                        decoration: const InputDecoration(labelText: 'Display Order'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
