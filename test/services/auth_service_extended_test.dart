import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blissfruitz/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {}

// Use a Fake for the transform builder because mocking Future.then is tricky
class FakePostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T _value;
  FakePostgrestTransformBuilder(this._value);
  
  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future.value(onValue(_value));
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> mockFilterBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

    AuthService.mockClient = mockClient;
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  tearDown(() {
    AuthService.mockClient = null;
  });

  group('AuthService Extended Tests', () {
    test('getUserProfile returns profile when user exists', () async {
      final mockUser = User(
        id: 'user-uuid',
        appMetadata: {},
        userMetadata: {},
        aud: 'aud',
        createdAt: DateTime.now().toIso8601String(),
      );
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final mockData = {
        'id': 1,
        'supabaseId': 'user-uuid',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'customer',
        'isActive': true,
      };

      when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenAnswer((_) => mockFilterBuilder);
      
      // Use the Fake here
      when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) => FakePostgrestTransformBuilder<Map<String, dynamic>?>(mockData));

      final profile = await AuthService.getUserProfile();

      expect(profile, isNotNull);
      expect(profile!.supabaseId, 'user-uuid');
      expect(profile.fullName, 'Test User');
    });
  });
}
