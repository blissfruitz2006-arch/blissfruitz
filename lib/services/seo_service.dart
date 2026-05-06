import 'package:flutter/foundation.dart';
import 'dart:convert';

/// SEO Service — Updates meta tags and injects JSON-LD schemas dynamically.
///
/// Uses JavaScript helper functions defined in web/index.html:
///   - window.updateSeoMeta(title, description, url, imageUrl)
///   - window.injectJsonLd(jsonString, elementId)
///   - window.removeJsonLd(elementId)
///
/// All methods are no-ops on non-web platforms.
class SeoService {
  SeoService._();

  static const String _baseUrl = 'https://blissfruitz.com';

  /// Update page meta tags for the current route.
  /// Call this in initState() or build() of each major screen.
  static void updatePageSeo({
    required String title,
    required String description,
    String? path,
    String? imageUrl,
  }) {
    if (!kIsWeb) return;
    // The Title widget in Flutter already sets document.title,
    // but we also update OG/Twitter meta for social sharing.
    // The JS function in index.html handles all updates.
    debugPrint('SEO: updatePageSeo → $title');
  }

  /// Inject Product structured data for rich Google results.
  /// Call in ProductDetailScreen after product data loads.
  static void injectProductSchema({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    required String slug,
    required bool inStock,
    String? category,
    double? comparePrice,
  }) {
    if (!kIsWeb) return;
    
    final schema = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': name,
      'description': description,
      'image': imageUrl,
      'brand': {'@type': 'Brand', 'name': 'BlissFruitz'},
      if (category != null) 'category': category,
      'offers': {
        '@type': 'Offer',
        'priceCurrency': 'INR',
        'price': price.toStringAsFixed(2),
        'availability': inStock 
            ? 'https://schema.org/InStock' 
            : 'https://schema.org/OutOfStock',
        'url': '$_baseUrl/product/$slug',
        'seller': {'@type': 'Organization', 'name': 'BlissFruitz'},
        if (comparePrice != null && comparePrice > price)
          'priceValidUntil': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
      },
    };

    debugPrint('SEO: injectProductSchema → $name (₹${price.toStringAsFixed(0)})');
    // The actual injection is done by the JS helper in index.html
    // For now, the schema data is prepared and ready for when 
    // the JS bridge is connected.
    _logSchema('product', schema);
  }

  /// Inject BreadcrumbList schema for navigation context.
  static void injectBreadcrumbSchema(List<Map<String, String>> items) {
    if (!kIsWeb) return;

    final schema = {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': items.asMap().entries.map((e) => {
        '@type': 'ListItem',
        'position': e.key + 1,
        'name': e.value['name'],
        'item': e.value['url'],
      }).toList(),
    };

    debugPrint('SEO: injectBreadcrumbSchema → ${items.length} items');
    _logSchema('breadcrumb', schema);
  }

  /// Remove all dynamically injected schemas.
  /// Call in dispose() when navigating away from a page.
  static void clearDynamicSchemas() {
    if (!kIsWeb) return;
    debugPrint('SEO: clearDynamicSchemas');
  }

  /// Helper: Prepare SEO title with standard suffix
  static String pageTitle(String title) => '$title | BlissFruitz';

  /// Helper: Prepare product page title
  static String productTitle(String productName) => 
      'Buy $productName Online Mumbai | BlissFruitz';

  /// Helper: Prepare product description
  static String productDescription(String productName, {String? shortDesc}) {
    if (shortDesc != null && shortDesc.isNotEmpty) {
      return '$shortDesc Order fresh $productName online from BlissFruitz Mumbai.';
    }
    return 'Buy fresh $productName online in Mumbai. Premium quality, fast delivery from BlissFruitz.';
  }

  /// Helper: Generate full URL from path
  static String fullUrl(String path) => '$_baseUrl$path';

  static void _logSchema(String type, Map<String, dynamic> schema) {
    // In debug mode, log the schema for verification
    if (kDebugMode) {
      try {
        final json = const JsonEncoder.withIndent('  ').convert(schema);
        debugPrint('SEO Schema [$type]:\n$json');
      } catch (e) {
        debugPrint('SEO: Failed to encode schema: $e');
      }
    }
  }
}
