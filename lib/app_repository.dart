import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'supabase_service.dart';

class AppRepository {
  static const _lotsKey = 'waste_lots_v2';
  static const _languageKey = 'user_preferred_language';
  static const _sarvamKey = 'sarvam_api_key_custom';
  static const _geminiKey = 'gemini_api_key_custom';
  static const _sessionTokenKey = 'auth_session_token';
  static const _sessionRoleKey = 'auth_session_role';
  static const _sessionNameKey = 'auth_session_name';

  final supabase = SupabaseService();

  List<MaterialPrice> prices = [
    const MaterialPrice(category: 'Copper Cables', icon: '🔌', hindi: 'तांबे की तार', marathi: 'तांब्याच्या तारा', rate: 330, low: 290, high: 360, unit: 'kg', trend: 2.4, co2OffsetPerKg: 3.2, esgPointsPerKg: 25),
    const MaterialPrice(category: 'PCBs', icon: '🟩', hindi: 'सर्किट बोर्ड', marathi: 'सर्किट बोर्ड', rate: 420, low: 260, high: 620, unit: 'kg', trend: 4.1, co2OffsetPerKg: 4.8, esgPointsPerKg: 40),
    const MaterialPrice(category: 'Li-ion Batteries', icon: '🔋', hindi: 'लिथियम बैटरी', marathi: 'लिथियम बॅटरी', rate: 105, low: 80, high: 135, unit: 'kg', trend: -1.2, co2OffsetPerKg: 2.5, esgPointsPerKg: 50),
    const MaterialPrice(category: 'Motors', icon: '⚙️', hindi: 'मोटर', marathi: 'मोटर', rate: 92, low: 75, high: 115, unit: 'kg', trend: 1.1, co2OffsetPerKg: 1.9, esgPointsPerKg: 15),
    const MaterialPrice(category: 'LCD Panels', icon: '🖥️', hindi: 'एलसीडी पैनल', marathi: 'एलसीडी पॅनेल', rate: 38, low: 20, high: 55, unit: 'piece', trend: 0.3, co2OffsetPerKg: 1.2, esgPointsPerKg: 10),
    const MaterialPrice(category: 'CRT Units', icon: '📺', hindi: 'सीआरटी टीवी', marathi: 'सीआरटी संच', rate: 18, low: 10, high: 25, unit: 'piece', trend: -2.8, co2OffsetPerKg: 0.8, esgPointsPerKg: 8),
    const MaterialPrice(category: 'Mixed Plastics', icon: '♻️', hindi: 'मिश्रित प्लास्टिक', marathi: 'मिश्र प्लास्टिक', rate: 22, low: 14, high: 28, unit: 'kg', trend: 0.7, co2OffsetPerKg: 1.1, esgPointsPerKg: 12),
    const MaterialPrice(category: 'Magnet Assemblies', icon: '🧲', hindi: 'चुंबक असेंबली', marathi: 'चुंबक जोडणी', rate: 145, low: 100, high: 190, unit: 'kg', trend: 3.2, co2OffsetPerKg: 2.8, esgPointsPerKg: 20),
  ];

  void updatePrices(List<MaterialPrice> newPrices) {
    if (newPrices.isNotEmpty) {
      prices = newPrices;
    }
  }

  final List<RecyclerInfo> recyclers = const [
    // Karnataka / South India
    RecyclerInfo(
      id: 'REC-KA-001',
      name: 'Bengaluru Eco-Recovery Facility',
      location: 'Peenya, Bengaluru, Karnataka',
      authorization: 'KSPCB/EW/2026/0921',
      categories: ['Copper Cables', 'PCBs', 'Li-ion Batteries', 'Motors'],
      distanceKm: 6.2,
      pickup: true,
      rateFactor: 1.05,
      phone: '+91 90000 20001',
      latLng: LatLng(12.9716, 77.5946),
    ),
    RecyclerInfo(
      id: 'REC-KA-002',
      name: 'Malnad CleanTech Aggregators',
      location: 'Shivamogga, Karnataka',
      authorization: 'KSPCB/AGG/2026/0412',
      categories: ['Copper Cables', 'Motors', 'Mixed Plastics', 'Li-ion Batteries'],
      distanceKm: 3.8,
      pickup: true,
      rateFactor: 1.02,
      phone: '+91 90000 20002',
      latLng: LatLng(13.9299, 75.5681),
    ),
    // Maharashtra / West India
    RecyclerInfo(
      id: 'REC-MH-001',
      name: 'Maha Eco Recycler',
      location: 'Pune, Maharashtra',
      authorization: 'MPCB/EW/2026/1042',
      categories: ['Copper Cables', 'PCBs', 'Li-ion Batteries', 'Motors'],
      distanceKm: 8.4,
      pickup: true,
      rateFactor: 1.04,
      phone: '+91 90000 10001',
      latLng: LatLng(18.5204, 73.8567),
    ),
    RecyclerInfo(
      id: 'REC-MH-002',
      name: 'Mumbai CleanTech Industrial Hub',
      location: 'Turbhe, Navi Mumbai, Maharashtra',
      authorization: 'MPCB/EW/2026/2201',
      categories: ['Copper Cables', 'PCBs', 'LCD Panels', 'Magnet Assemblies'],
      distanceKm: 14.1,
      pickup: true,
      rateFactor: 1.06,
      phone: '+91 90000 10005',
      latLng: LatLng(19.0760, 72.8777),
    ),
    // North India / Delhi NCR
    RecyclerInfo(
      id: 'REC-DL-001',
      name: 'Delhi NCR Apex Circular Processors',
      location: 'Okhla Industrial Area, New Delhi',
      authorization: 'CPCB/EW/2026/3012',
      categories: ['Copper Cables', 'PCBs', 'Li-ion Batteries', 'LCD Panels'],
      distanceKm: 5.1,
      pickup: true,
      rateFactor: 1.07,
      phone: '+91 90000 30001',
      latLng: LatLng(28.5355, 77.2732),
    ),
    // Tamil Nadu / South India
    RecyclerInfo(
      id: 'REC-TN-001',
      name: 'Chennai EcoMetals Recycler',
      location: 'Guindy, Chennai, Tamil Nadu',
      authorization: 'TNPCB/EW/2026/1183',
      categories: ['Copper Cables', 'PCBs', 'Motors', 'Mixed Plastics'],
      distanceKm: 9.3,
      pickup: true,
      rateFactor: 1.03,
      phone: '+91 90000 40001',
      latLng: LatLng(13.0827, 80.2707),
    ),
    // Telangana / South India
    RecyclerInfo(
      id: 'REC-TS-001',
      name: 'Hyderabad CyberScrap Processors',
      location: 'Cherlapally, Hyderabad, Telangana',
      authorization: 'TSPCB/EW/2026/0745',
      categories: ['PCBs', 'Li-ion Batteries', 'Copper Cables', 'LCD Panels'],
      distanceKm: 11.2,
      pickup: true,
      rateFactor: 1.04,
      phone: '+91 90000 50001',
      latLng: LatLng(17.3850, 78.4867),
    ),
    // Gujarat / West India
    RecyclerInfo(
      id: 'REC-GJ-001',
      name: 'Ahmedabad Circular Metals Hub',
      location: 'Vatva GIDC, Ahmedabad, Gujarat',
      authorization: 'GPCB/EW/2026/0631',
      categories: ['Copper Cables', 'Motors', 'Magnet Assemblies', 'Mixed Plastics'],
      distanceKm: 7.5,
      pickup: true,
      rateFactor: 1.02,
      phone: '+91 90000 60001',
      latLng: LatLng(23.0225, 72.5714),
    ),
    // West Bengal / East India
    RecyclerInfo(
      id: 'REC-WB-001',
      name: 'Kolkata Eastern Resource Recovery',
      location: 'Howrah, Kolkata, West Bengal',
      authorization: 'WBPCB/EW/2026/1344',
      categories: ['Copper Cables', 'PCBs', 'CRT Units', 'Mixed Plastics'],
      distanceKm: 8.9,
      pickup: true,
      rateFactor: 1.01,
      phone: '+91 90000 70001',
      latLng: LatLng(22.5726, 88.3639),
    ),
    // Rajasthan / North India
    RecyclerInfo(
      id: 'REC-RJ-001',
      name: 'Jaipur GreenCycle Facility',
      location: 'Sitapura Industrial Area, Jaipur, Rajasthan',
      authorization: 'RSPCB/EW/2026/0519',
      categories: ['Copper Cables', 'Motors', 'Li-ion Batteries'],
      distanceKm: 12.0,
      pickup: false,
      rateFactor: 0.99,
      phone: '+91 90000 80001',
      latLng: LatLng(26.9124, 75.7873),
    ),
  ];

  Future<List<WasteLot>> loadLots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lotsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return WasteLot.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLots(List<WasteLot> lots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep up to 25 lots and strip large base64 strings (>5KB) to prevent HTML5 localStorage QuotaExceededError (5MB limit)
      final lightweightLots = lots.take(25).map((l) {
        if (l.imageBase64.length > 5000) {
          return l.copyWith(imageBase64: '');
        }
        return l;
      }).toList();

      await prefs.setString(_lotsKey, WasteLot.encodeList(lightweightLots));
    } catch (e) {
      debugPrint('[AppRepository] LocalStorage quota handled: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        // If storage is completely full, keep the 5 most recent lots with empty images
        final minimalLots = lots.take(5).map((l) => l.copyWith(imageBase64: '')).toList();
        await prefs.setString(_lotsKey, WasteLot.encodeList(minimalLots));
      } catch (_) {}
    }

    // Resilient background sync to Supabase
    for (final lot in lots) {
      if (!lot.synced) {
        supabase.syncLot(lot).catchError((_) => false);
      }
    }
  }

  Future<String?> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
  }

  Future<String?> loadSarvamKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sarvamKey);
  }

  Future<void> saveSarvamKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sarvamKey, key.trim());
  }

  Future<String?> loadGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKey);
  }

  Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key.trim());
  }

  Future<void> saveSession({required String token, required String role, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
    await prefs.setString(_sessionRoleKey, role);
    await prefs.setString(_sessionNameKey, name);
  }

  Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionTokenKey);
    final role = prefs.getString(_sessionRoleKey);
    final name = prefs.getString(_sessionNameKey);
    if (token != null && token.isNotEmpty && role != null) {
      return {'token': token, 'role': role, 'name': name ?? 'User'};
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_sessionRoleKey);
    await prefs.remove(_sessionNameKey);
  }

  MaterialPrice priceFor(String category) => prices.firstWhere(
        (price) => price.category == category,
        orElse: () => prices.first,
      );

  List<RecyclerInfo> matchesFor(String category) {
    final matches = recyclers.where((r) => r.categories.contains(category)).toList();
    matches.sort((a, b) {
      final aScore = a.rateFactor * 50 + (a.pickup ? 20 : 0) - a.distanceKm;
      final bScore = b.rateFactor * 50 + (b.pickup ? 20 : 0) - b.distanceKm;
      return bScore.compareTo(aScore);
    });
    if (matches.isNotEmpty) return matches;
    return recyclers.take(3).toList();
  }
}
