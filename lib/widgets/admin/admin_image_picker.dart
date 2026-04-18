import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../config/theme.dart';

import '../app_image.dart';

class AdminImagePicker extends StatefulWidget {
  final String? initialValue;
  final String folder;
  final Function(String?, Uint8List?, String?) onChanged;

  const AdminImagePicker({
    super.key,
    this.initialValue,
    required this.folder,
    required this.onChanged,
  });

  @override
  State<AdminImagePicker> createState() => _AdminImagePickerState();
}

class _AdminImagePickerState extends State<AdminImagePicker> {
  int _sourceIndex = 0; // 0: Upload, 1: URL
  final _urlController = TextEditingController();
  Uint8List? _uploadedBytes;
  String? _uploadedName;
  String? _currentPreview;

  @override
  void initState() {
    super.initState();
    _currentPreview = widget.initialValue;
    if (_currentPreview != null && 
        (_currentPreview!.startsWith('http') || _currentPreview!.contains('://'))) {
      _sourceIndex = 1;
      _urlController.text = _currentPreview!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _uploadedBytes = bytes;
          _uploadedName = file.name;
          _sourceIndex = 0;
        });
        widget.onChanged(null, bytes, file.name);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _onUrlChanged(String val) {
    if (_sourceIndex != 1) {
      setState(() => _sourceIndex = 1);
    }
    // We update parent immediately, but let build handle the local preview
    widget.onChanged(val.trim().isEmpty ? null : val.trim(), null, null);
    // Explicitly setState to show preview in URL tab if needed, 
    // but Note: _urlController already manages the text state.
    setState(() {}); 
  }

  void _onTabSwitch(int index) {
    if (_sourceIndex == index) return;
    setState(() {
      _sourceIndex = index;
    });
    // Notify parent of what's currently active in this tab
    if (index == 0) {
      widget.onChanged(null, _uploadedBytes, _uploadedName);
    } else {
      final url = _urlController.text.trim();
      widget.onChanged(url.isEmpty ? null : url, null, null);
    }
  }

  void _clear() {
    setState(() {
      _uploadedBytes = null;
      _uploadedName = null;
      _urlController.clear();
      _currentPreview = null;
    });
    widget.onChanged(null, null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector Header
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTab(0, 'Upload', Icons.upload_rounded),
                  _buildTab(1, 'External URL', Icons.link_rounded),
                ],
              ),
            ),
            const Spacer(),
            if (_uploadedBytes != null || _urlController.text.isNotEmpty || _currentPreview != null)
              IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 20),
                tooltip: 'Clear selection',
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview & Input Area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _sourceIndex == 0 ? _buildUploadArea() : _buildUrlArea(),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      key: const ValueKey('upload_area'),
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploadedBytes != null
            ? Image.memory(_uploadedBytes!, fit: BoxFit.cover)
            : (_currentPreview != null
                ? AppImage(path: _currentPreview, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, 
                            size: 40, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Tap to upload image', 
                            style: GoogleFonts.outfit(
                              fontSize: 13, 
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  )),
      ),
    );
  }

  Widget _buildUrlArea() {
    final url = _urlController.text.trim();
    return Column(
      key: const ValueKey('url_area'),
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'Pate image URL here...',
            labelText: 'Direct Link',
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.link_rounded),
          ),
          onChanged: _onUrlChanged,
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: url.isNotEmpty
              ? AppImage(path: url, fit: BoxFit.cover)
              : Center(
                  child: Text('Preview will appear here', 
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12, 
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
                      )),
                ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    bool selected = _sourceIndex == index;
    return GestureDetector(
      onTap: () => _onTabSwitch(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
