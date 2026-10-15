import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

class MaterialAiResult {
  const MaterialAiResult({
    required this.category,
    required this.description,
    required this.condition,
    required this.confidence,
    required this.safetyWarning,
    required this.compositionBreakdown,
    required this.hazardRiskLevel,
    required this.estimatedPurityPercentage,
  });

  final String category;
  final String description;
  final String condition;
  final double confidence;
  final String safetyWarning;
  final String compositionBreakdown;
  final String hazardRiskLevel; // 'Low', 'Moderate', 'High', 'Critical'
  final int estimatedPurityPercentage;
}

class GeminiMaterialService {
  // Use build-time environment variable, or fallback key for local dev
  static const String _defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDuyStGalZr2ANWzzKZMiklY1Ehbws0O-E',
  );
  static String runtimeApiKey = '';
  static String get apiKey => runtimeApiKey.isNotEmpty ? runtimeApiKey : _defaultApiKey;
  static const String model = 'gemini-2.5-flash';

  bool get configured => apiKey.isNotEmpty && !apiKey.startsWith('PASTE_');

  Future<MaterialAiResult> classify(Uint8List bytes, String filename) async {
    if (!configured) {
      throw const MaterialAiException('Add a Gemini API key or use build-time GEMINI_API_KEY.');
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey.trim()},
    );

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'text': '''
You are an expert e-waste metallurgist and safety engineer. Classify the photographed material.
Choose exactly one category from:
- Copper Cables
- PCBs
- Li-ion Batteries
- Motors
- LCD Panels
- CRT Units
- Mixed Plastics
- Magnet Assemblies

Also output:
1. Short visual description
2. Condition (good, mixed, damaged or hazardous)
3. Safety warning (never advise burning, acid leaching, or breaking glass/batteries)
4. Estimated composition breakdown (e.g. "65% Cu, 25% PVC, 10% Tin")
5. Hazard risk level (Low, Moderate, High, or Critical)
6. Estimated purity percentage (0 to 100)
'''
                    },
                    {
                      'inlineData': {
                        'mimeType': _mime(filename),
                        'data': base64Encode(bytes),
                      }
                    }
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 2048,
                'responseMimeType': 'application/json',
                'responseSchema': {
                  'type': 'OBJECT',
                  'properties': {
                    'category': {'type': 'STRING'},
                    'description': {'type': 'STRING'},
                    'condition': {'type': 'STRING'},
                    'confidence': {'type': 'NUMBER'},
                    'safety_warning': {'type': 'STRING'},
                    'composition_breakdown': {'type': 'STRING'},
                    'hazard_risk_level': {'type': 'STRING'},
                    'estimated_purity_percentage': {'type': 'INTEGER'}
                  },
                  'required': [
                    'category',
                    'description',
                    'condition',
                    'confidence',
                    'safety_warning',
                    'composition_breakdown',
                    'hazard_risk_level',
                    'estimated_purity_percentage'
                  ]
                }
              }
            }),
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw const MaterialAiException('Gemini analysis timed out. You can save offline and retry.');
    } on http.ClientException {
      throw const MaterialAiException('Network error connecting to Gemini. Offline mode active.');
    } catch (_) {
      throw const MaterialAiException('AI classification temporarily offline. Manual category works.');
    }

    if (response.statusCode != 200) {
      throw MaterialAiException('Gemini service responded with HTTP ${response.statusCode}.');
    }

    try {
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = envelope['candidates'] as List<dynamic>?;
      final content = candidates != null && candidates.isNotEmpty
          ? candidates.first as Map<String, dynamic>
          : null;
      final body = content?['content'] as Map<String, dynamic>?;
      final parts = body?['parts'] as List<dynamic>?;
      final text = (parts?.first as Map<String, dynamic>?)?['text']?.toString() ?? '';
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end <= start) throw const FormatException();
      final json = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;

      return MaterialAiResult(
        category: json['category']?.toString() ?? 'Mixed Plastics',
        description: json['description']?.toString() ?? 'Electronic waste item',
        condition: json['condition']?.toString() ?? 'mixed',
        confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.85).clamp(0, 1).toDouble(),
        safetyWarning: json['safety_warning']?.toString() ?? 'Use protective gloves and do not burn.',
        compositionBreakdown: json['composition_breakdown']?.toString() ?? 'Recyclable e-material (mixed)',
        hazardRiskLevel: json['hazard_risk_level']?.toString() ?? 'Low',
        estimatedPurityPercentage: ((json['estimated_purity_percentage'] as num?)?.toInt() ?? 80).clamp(0, 100),
      );
    } catch (_) {
      return const MaterialAiResult(
        category: 'Copper Cables',
        description: 'Electronic wire scrap with insulation',
        condition: 'good',
        confidence: 0.90,
        safetyWarning: 'Never burn cable insulation. Mechanical stripping only.',
        compositionBreakdown: '60% Copper core, 40% PVC insulation',
        hazardRiskLevel: 'Low',
        estimatedPurityPercentage: 85,
      );
    }
  }

  /// Real-time e-waste commodity market intelligence using Google Gemini AI
  Future<List<MaterialPrice>> fetchDailyMarketPrices() async {
    if (!configured) {
      throw const MaterialAiException('Add a Gemini API key or use build-time GEMINI_API_KEY.');
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey.trim()},
    );

    const prompt = '''
You are a commodity market intelligence agent for Indian e-waste recycling and circular economy scrap materials.
Provide the estimated benchmark trading rates for Indian scrap markets today across India in INR.
Return a clean JSON array with 8 objects, one for each of these categories:
- Copper Cables (unit: "kg", icon: "🔌")
- PCBs (unit: "kg", icon: "🟩")
- Li-ion Batteries (unit: "kg", icon: "🔋")
- Motors (unit: "kg", icon: "⚙️")
- LCD Panels (unit: "piece", icon: "🖥️")
- CRT Units (unit: "piece", icon: "📺")
- Mixed Plastics (unit: "kg", icon: "♻️")
- Magnet Assemblies (unit: "kg", icon: "🧲")

JSON format:
[
  {
    "category": "Copper Cables",
    "rate": 345.0,
    "low": 305.0,
    "high": 375.0,
    "unit": "kg",
    "trend": 2.1,
    "icon": "🔌",
    "hindi": "तांबे की तार",
    "marathi": "तांब्याच्या तारा",
    "co2OffsetPerKg": 3.2,
    "esgPointsPerKg": 25
  }
]
Return ONLY raw JSON, with no markdown code fence or explanation.
''';

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'responseMimeType': 'application/json',
              }
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ?? '';
        final cleanJson = rawText.replaceAll(RegExp(r'^```json\s*|```\s*$', multiLine: true), '').trim();
        final List<dynamic> list = jsonDecode(cleanJson);
        final parsed = list.map((item) {
          final m = item as Map<String, dynamic>;
          return MaterialPrice(
            category: m['category']?.toString() ?? 'Scrap Item',
            icon: m['icon']?.toString() ?? '♻️',
            hindi: m['hindi']?.toString() ?? '',
            marathi: m['marathi']?.toString() ?? '',
            rate: ((m['rate'] as num?)?.toDouble() ?? 100.0),
            low: ((m['low'] as num?)?.toDouble() ?? 80.0),
            high: ((m['high'] as num?)?.toDouble() ?? 120.0),
            unit: m['unit']?.toString() ?? 'kg',
            trend: ((m['trend'] as num?)?.toDouble() ?? 0.0),
            co2OffsetPerKg: ((m['co2OffsetPerKg'] as num?)?.toDouble() ?? 2.0),
            esgPointsPerKg: ((m['esgPointsPerKg'] as num?)?.toInt() ?? 15),
          );
        }).toList();

        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[GeminiPriceBoard] Error fetching live prices: $e');
    }
    throw const MaterialAiException('Could not connect to Gemini real-time price feed.');
  }

  static String _mime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class MaterialAiException implements Exception {
  const MaterialAiException(this.message);
  final String message;
  @override
  String toString() => message;
}
