import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class SupabaseService {
  static const String defaultUrl = 'https://kgbifbyyoyulkpzsbuke.supabase.co';
  static const String defaultAnonKey = 'sb_publishable_lcVcpT5elrctUVpzXPkH2g_SLlTfswT';

  final String url;
  final String anonKey;

  SupabaseService({
    String? url,
    String? anonKey,
  })  : url = (url != null && url.isNotEmpty) ? url : defaultUrl,
        anonKey = (anonKey != null && anonKey.isNotEmpty) ? anonKey : defaultAnonKey;

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation,resolution=merge-duplicates',
      };

  /// Verify connection to Supabase instance
  Future<bool> checkHealth() async {
    try {
      final res = await http.get(
        Uri.parse('$url/auth/v1/health'),
        headers: {'apikey': anonKey},
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sync or upload a WasteLot to Supabase
  Future<bool> syncLot(WasteLot lot) async {
    try {
      final payload = {
        'id': lot.id,
        'category': lot.category,
        'description': lot.description,
        'weight': lot.weight,
        'estimated_value': lot.estimatedValue,
        'quoted_price': lot.quotedPrice,
        'final_price': lot.finalPrice,
        'created_at': lot.createdAt.toIso8601String(),
        'location': lot.location,
        'latitude': lot.latitude,
        'longitude': lot.longitude,
        'recycler_id': lot.recyclerId,
        'recycler_name': lot.recyclerName,
        'status': lot.status,
        'payment_status': lot.paymentStatus,
        'payment_mode': lot.paymentMode,
        'composition_breakdown': lot.compositionBreakdown,
        'hazard_level': lot.hazardLevel,
        'green_credits_earned': lot.greenCreditsEarned,
      };

      final res = await http.post(
        Uri.parse('$url/rest/v1/waste_lots'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all synced lots from Supabase
  Future<List<WasteLot>> fetchRemoteLots() async {
    try {
      final res = await http.get(
        Uri.parse('$url/rest/v1/waste_lots?order=created_at.desc'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          return WasteLot(
            id: item['id']?.toString() ?? '',
            category: item['category']?.toString() ?? 'E-Waste',
            description: item['description']?.toString() ?? '',
            weight: (item['weight'] as num?)?.toDouble() ?? 0.0,
            estimatedValue: (item['estimated_value'] as num?)?.toDouble() ?? 0.0,
            quotedPrice: (item['quoted_price'] as num?)?.toDouble() ?? 0.0,
            finalPrice: (item['final_price'] as num?)?.toDouble() ?? 0.0,
            createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
            location: item['location']?.toString() ?? '',
            latitude: (item['latitude'] as num?)?.toDouble(),
            longitude: (item['longitude'] as num?)?.toDouble(),
            recyclerId: item['recycler_id']?.toString() ?? '',
            recyclerName: item['recycler_name']?.toString() ?? '',
            status: item['status']?.toString() ?? 'created',
            paymentStatus: item['payment_status']?.toString() ?? 'pending',
            paymentMode: item['payment_mode']?.toString() ?? 'UPI_DIRECT',
            imageBase64: '',
            synced: true,
            compositionBreakdown: item['composition_breakdown']?.toString() ?? '',
            hazardLevel: item['hazard_level']?.toString() ?? 'Low',
            greenCreditsEarned: (item['green_credits_earned'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Prototype Sign In with email / password
  Future<Map<String, dynamic>> signIn({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('$url/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      } else {
        dynamic decoded;
        if (res.body.isNotEmpty) {
          try {
            decoded = jsonDecode(res.body);
          } catch (_) {}
        }
        final err = decoded?['msg'] ??
            decoded?['error_description'] ??
            decoded?['message'] ??
            decoded?['error'] ??
            'Invalid login credentials';
        return {'success': false, 'error': err.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign Up with email / password and user metadata
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (data != null && data.isNotEmpty) {
        payload['data'] = data;
      }

      final res = await http.post(
        Uri.parse('$url/auth/v1/signup'),
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(res.body)};
      } else {
        final decoded = jsonDecode(res.body);
        final errorMsg = decoded['msg'] ?? decoded['error_description'] ?? decoded['message'] ?? 'Sign up failed';
        return {'success': false, 'error': errorMsg.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
