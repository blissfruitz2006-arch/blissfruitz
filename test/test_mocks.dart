import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseQueryBuilder, // Use SupabaseQueryBuilder instead of PostgrestQueryBuilder
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
  SupabaseStorageClient,
  StorageFileApi,
  http.Client,
])
void main() {}
