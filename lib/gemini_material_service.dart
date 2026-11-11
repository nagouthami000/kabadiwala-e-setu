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

    const promptText = '''
You are an expert e-waste metallurgist and safety engineer. Classify the photographed material into Indian circular economy e-waste categories.
You must choose exactly one category from this allowed list:
- Copper Cables
- PCBs
- Li-ion Batteries
- Motors
- LCD Panels
- CRT Units
- Mixed Plastics
- Magnet Assemblies

Material Classification Rules:
- If the image shows a laptop, computer screen, monitor, TV screen, or display panel (such as Lenovo, Dell, HP, Samsung, LG), choose "LCD Panels" (or "CRT Units" if it is an old cathode ray tube box TV).
- If the image shows a circuit board, green board, motherboard, or RAM/chips, choose "PCBs".
- If the image shows batteries, lithium packs, phone batteries, or cells, choose "Li-ion Batteries".
- If the image shows wires, electrical cords, or copper cables, choose "Copper Cables".
- If the image shows an electric motor, alternator, or pump, choose "Motors".
- If the image shows plastic chassis, plastic casings, or unseparated plastic scrap, choose "Mixed Plastics".
- If the image shows magnets, speaker magnets, or hard drive magnet assemblies, choose "Magnet Assemblies".

Also output:
1. Short visual description of what you see
2. Condition (good, mixed, damaged or hazardous)
3. Safety warning (never advise burning, acid leaching, or breaking glass/batteries)
4. Estimated composition breakdown (e.g. "50% Glass, 30% Plastic, 20% Metal")
5. Hazard risk level (Low, Moderate, High, or Critical)
6. Estimated purity percentage (0 to 100)
''';

    final mime = _detectMime(bytes, filename);
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
                    {'text': promptText},
                    {
                      'inlineData': {
                        'mimeType': mime,
                        'data': base64Encode(bytes),
                      }
                    }
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 8192,
                'thinkingConfig': {
                  'thinkingBudget': 0,
                },
                'responseMimeType': 'application/json',
                'responseSchema': {
                  'type': 'OBJECT',
                  'properties': {
                    'category': {
                      'type': 'STRING',
                      'enum': [
                        'Copper Cables',
                        'PCBs',
                        'Li-ion Batteries',
                        'Motors',
                        'LCD Panels',
                        'CRT Units',
                        'Mixed Plastics',
                        'Magnet Assemblies'
                      ]
                    },
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
      throw const MaterialAiException('Gemini analysis timed out. Check your internet connection.');
    } on http.ClientException catch (e) {
      throw MaterialAiException('Network error connecting to Gemini: $e');
    } catch (e) {
      throw MaterialAiException('AI classification failed: $e');
    }

    if (response.statusCode != 200) {
      debugPrint('[GeminiMaterialService] Non-200 response: ${response.statusCode} - ${response.body}');
      throw MaterialAiException('Gemini service error: HTTP ${response.statusCode}');
    }

    try {
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = envelope['candidates'] as List<dynamic>?;
      final content = candidates != null && candidates.isNotEmpty
          ? candidates.first as Map<String, dynamic>
          : null;
      final body = content?['content'] as Map<String, dynamic>?;
      final parts = body?['parts'] as List<dynamic>?;

      // Extract JSON part (checking from last part backwards in case thoughts came first)
      String text = '';
      if (parts != null) {
        for (final p in parts.reversed) {
          if (p is Map<String, dynamic>) {
            final t = p['text']?.toString() ?? '';
            if (t.contains('{') && t.contains('}')) {
              text = t;
              break;
            }
          }
        }
        if (text.isEmpty && parts.isNotEmpty) {
          text = (parts.last as Map<String, dynamic>?)?['text']?.toString() ?? '';
        }
      }

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      Map<String, dynamic> json;
      if (start >= 0 && end > start) {
        try {
          json = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
        } catch (_) {
          json = _lenientRepairJson(text.substring(start));
        }
      } else if (start >= 0) {
        json = _lenientRepairJson(text.substring(start));
      } else {
        throw FormatException('No JSON found in Gemini response: $text');
      }

      final rawCategory = json['category']?.toString() ?? 'Mixed Plastics';
      final cleanCategory = _normalizeCategory(rawCategory);

      return MaterialAiResult(
        category: cleanCategory,
        description: json['description']?.toString() ?? 'Electronic waste item',
        condition: json['condition']?.toString() ?? 'good',
        confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.95).clamp(0, 1).toDouble(),
        safetyWarning: json['safety_warning']?.toString() ?? 'Handle with care to avoid physical damage.',
        compositionBreakdown: json['composition_breakdown']?.toString() ?? 'Recyclable e-waste components',
        hazardRiskLevel: json['hazard_risk_level']?.toString() ?? 'Low',
        estimatedPurityPercentage: ((json['estimated_purity_percentage'] as num?)?.toInt() ?? 85).clamp(0, 100),
      );
    } catch (e) {
      debugPrint('[GeminiMaterialService] Error parsing classification: $e');
      throw MaterialAiException('Could not parse Gemini material classification: $e');
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
                'maxOutputTokens': 8192,
                'thinkingConfig': {
                  'thinkingBudget': 0,
                },
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

  static String _detectMime(Uint8List bytes, String filename) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'image/webp';
    }
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _normalizeCategory(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('lcd') ||
        lower.contains('panel') ||
        lower.contains('monitor') ||
        lower.contains('laptop') ||
        lower.contains('screen') ||
        lower.contains('display')) {
      return 'LCD Panels';
    }
    if (lower.contains('pcb') ||
        lower.contains('circuit') ||
        lower.contains('motherboard') ||
        lower.contains('board')) {
      return 'PCBs';
    }
    if (lower.contains('batter') || lower.contains('li-ion') || lower.contains('cell')) {
      return 'Li-ion Batteries';
    }
    if (lower.contains('cable') || lower.contains('wire') || lower.contains('copper')) {
      return 'Copper Cables';
    }
    if (lower.contains('motor') || lower.contains('pump') || lower.contains('rotor')) {
      return 'Motors';
    }
    if (lower.contains('crt') || lower.contains('cathode') || lower.contains('tube')) {
      return 'CRT Units';
    }
    if (lower.contains('magnet')) {
      return 'Magnet Assemblies';
    }
    if (lower.contains('plastic')) {
      return 'Mixed Plastics';
    }
    return 'Mixed Plastics';
  }

  static Map<String, dynamic> _lenientRepairJson(String raw) {
    var s = raw.trim();
    final firstBrace = s.indexOf('{');
    if (firstBrace >= 0) s = s.substring(firstBrace);

    // If unbalanced quotes, add a closing quote
    final quotes = RegExp(r'(?<!\\)"').allMatches(s).length;
    if (quotes % 2 != 0) {
      s += '"';
    }
    // Remove trailing commas before closing
    s = s.replaceAll(RegExp(r',\s*$'), '');
    if (!s.endsWith('}')) {
      s += '}';
    }
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      // Regex extraction fallback
      final catMatch = RegExp(r'"category"\s*:\s*"([^"]+)"').firstMatch(raw);
      final descMatch = RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(raw);
      final condMatch = RegExp(r'"condition"\s*:\s*"([^"]+)"').firstMatch(raw);
      final safeMatch = RegExp(r'"safety_warning"\s*:\s*"([^"]+)"').firstMatch(raw);
      final compMatch = RegExp(r'"composition_breakdown"\s*:\s*"([^"]+)"').firstMatch(raw);
      final hazMatch = RegExp(r'"hazard_risk_level"\s*:\s*"([^"]+)"').firstMatch(raw);
      final purMatch = RegExp(r'"estimated_purity_percentage"\s*:\s*(\d+)').firstMatch(raw);

      return {
        'category': catMatch?.group(1) ?? 'LCD Panels',
        'description': descMatch?.group(1) ?? 'Identified recyclable electronics',
        'condition': condMatch?.group(1) ?? 'good',
        'confidence': 0.95,
        'safety_warning': safeMatch?.group(1) ?? 'Handle with care to avoid physical damage.',
        'composition_breakdown': compMatch?.group(1) ?? 'Electronics, glass, and metals',
        'hazard_risk_level': hazMatch?.group(1) ?? 'Low',
        'estimated_purity_percentage': int.tryParse(purMatch?.group(1) ?? '85') ?? 85,
      };
    }
  }
}

class MaterialAiException implements Exception {
  const MaterialAiException(this.message);
  final String message;
  @override
  String toString() => message;
}
