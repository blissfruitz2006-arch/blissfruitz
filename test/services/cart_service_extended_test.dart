import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blissfruitz/services/cart_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Use a Fake that specifically implements the expected typed FilterBuilder
class FakePostgrestBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic _value;
  FakePostgrestBuilder(this._value);
  
  @override
  Future<U> then<U>(FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {Function? onError}) {
    return Future.value(onValue(_value as List<Map<String, dynamic>>));
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) => this;
  
  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() => FakeTransformBuilder(_value);
}

class FakeTransformBuilder extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final dynamic _value;
  FakeTransformBuilder(this._value);

  @override
  Future<U> then<U>(FutureOr<U> Function(Map<String, dynamic>?) onValue, {Function? onError}) {
    return Future.value(onValue(_value as Map<String, dynamic>?));
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    CartService.mockClient = mockClient;
    
    when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
  });

  tearDown(() {
    CartService.mockClient = null;
  });

  group('CartService Extended Tests', () {
    test('loadCartFromDb returns empty list when no cart exists', () async {
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => FakePostgrestBuilder(null));

      final items = await CartService.loadCartFromDb('user-uuid');

      expect(items, isEmpty);
    });

    test('loadCartFromDb returns items when cart exists', () async {
      // 1. Mock Cart lookup
      when(() => mockQueryBuilder.select('id')).thenAnswer((_) => FakePostgrestBuilder({'id': 'cart-id'}));

      // 2. Mock CartLine lookup
      final mockLinesData = [
        {
          'quantity': 2,
          'Product': {
            'id': 1,
            'name': 'Apple',
            'slug': 'apple',
            'price': 50.0,
          }
        }
      ];
      when(() => mockQueryBuilder.select('*, Product(*)')).thenAnswer((_) => FakePostgrestBuilder(mockLinesData));

      final items = await CartService.loadCartFromDb('user-uuid');

      expect(items, isNotEmpty);
      expect(items.length, 1);
      expect(items[0].product.name, 'Apple');
    });
  });
}
