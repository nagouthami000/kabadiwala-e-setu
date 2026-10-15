import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'app_repository.dart';
import 'auth_screen.dart';
import 'compliance_report_service.dart';
import 'gemini_material_service.dart';
import 'handover_page.dart';
import 'localization_service.dart';
import 'models.dart';
import 'recycler_map_screen.dart';
import 'recycler_portal_page.dart';
import 'sarvam_service.dart';
import 'voice_assistant_sheet.dart';

void main() => runApp(const KabadiSetuApp());

const primaryDark = Color(0xFF0F382A);
const accentLime = Color(0xFFC6F24D);
const mintGlow = Color(0xFF4DF2C6);
const cardBorder = Color(0x334DF2C6);
const inkDark = Color(0xFF081510);
const surfaceEmerald = Color(0xFF0F261E);

class KabadiSetuApp extends StatefulWidget {
  const KabadiSetuApp({super.key});

  @override
  State<KabadiSetuApp> createState() => _KabadiSetuAppState();
}

class _KabadiSetuAppState extends State<KabadiSetuApp> {
  final _repository = AppRepository();
  bool _isAuthenticated = false;
  String _userRole = 'collector';
  String _userName = 'Collector';
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final session = await _repository.loadSession();
    if (session != null && mounted) {
      setState(() {
        _isAuthenticated = true;
        _userRole = session['role'] ?? 'collector';
        _userName = session['name'] ?? 'Collector';
        _checkingSession = false;
      });
    } else {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: inkDark,
          body: Center(
            child: CircularProgressIndicator(color: accentLime),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Kabadi Setu',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: inkDark,
        colorScheme: const ColorScheme.dark(
          primary: accentLime,
          onPrimary: inkDark,
          secondary: mintGlow,
          onSecondary: inkDark,
          surface: surfaceEmerald,
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: surfaceEmerald,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: cardBorder, width: 1.2),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: inkDark,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceEmerald,
          indicatorColor: accentLime,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: inkDark);
            }
            return const IconThemeData(color: Colors.white70);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: accentLime, fontWeight: FontWeight.bold, fontSize: 12);
            }
            return const TextStyle(color: Colors.white60, fontSize: 12);
          }),
        ),
      ),
      home: _isAuthenticated
          ? MainShell(
              role: _userRole,
              userName: _userName,
              onLogout: () async {
                await _repository.clearSession();
                if (mounted) setState(() => _isAuthenticated = false);
              },
            )
          : AuthScreen(
              onLoginSuccess: (role, name) {
                setState(() {
                  _userRole = role;
                  _userName = name;
                  _isAuthenticated = true;
                });
              },
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  final String role;
  final String userName;
  final VoidCallback? onLogout;

  const MainShell({
    super.key,
    this.role = 'collector',
    this.userName = 'Demo Collector',
    this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final repository = AppRepository();
  final sarvam = SarvamAiService();
  List<WasteLot> lots = [];
  IndicLanguage language = IndicLanguage.english;
  int pageIndex = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final savedLang = await repository.loadSavedLanguage();
    if (savedLang != null) {
      final match = IndicLanguage.values.firstWhere(
        (l) => l.code == savedLang,
        orElse: () => IndicLanguage.english,
      );
      language = match;
    }
    final savedSarvamKey = await repository.loadSarvamKey();
    if (savedSarvamKey != null && savedSarvamKey.isNotEmpty) {
      SarvamAiService.runtimeApiKey = savedSarvamKey;
    }
    final savedGeminiKey = await repository.loadGeminiKey();
    if (savedGeminiKey != null && savedGeminiKey.isNotEmpty) {
      GeminiMaterialService.runtimeApiKey = savedGeminiKey;
    }
    lots = await repository.loadLots();
    if (mounted) setState(() => loading = false);
  }

  // API keys are loaded silently from SharedPreferences on startup.
  // No UI dialog is provided — keys should be set via:
  //   flutter run --dart-define=SARVAM_API_KEY=your_key --dart-define=GEMINI_API_KEY=your_key

  Future<void> saveLot(WasteLot lot) async {
    final index = lots.indexWhere((item) => item.id == lot.id);
    setState(() {
      if (index == -1) {
        lots.insert(0, lot);
      } else {
        lots[index] = lot;
      }
    });
    await repository.saveLots(lots);
  }

  void _changeLanguage(IndicLanguage lang) async {
    setState(() => language = lang);
    await repository.saveLanguage(lang.code);
    final welcome = lang == IndicLanguage.hindi
        ? 'ई-कबाड़ी सेतु में आपका स्वागत है।'
        : lang == IndicLanguage.marathi
            ? 'ई-कबाडी सेतू मध्ये आपले स्वागत आहे.'
            : 'Welcome to E-Kabadi Setu.';
    sarvam.speakText(text: welcome, language: lang);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        language: language,
        lots: lots,
        onNavigate: (index) => setState(() => pageIndex = index),
        sarvam: sarvam,
        repository: repository,
      ),
      widget.role == 'recycler'
          ? RecyclerPortalPage(
              language: language,
              lots: lots,
              onSaveLot: saveLot,
              sarvam: sarvam,
              recyclerName: widget.userName,
            )
          : SellPage(
              language: language,
              repository: repository,
              onSave: saveLot,
              sarvam: sarvam,
            ),
      PriceBoardPage(
        language: language,
        repository: repository,
        sarvam: sarvam,
      ),
      RecyclersPage(
        language: language,
        repository: repository,
      ),
      LedgerPage(
        language: language,
        lots: lots,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: accentLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.recycling_rounded, color: inkDark, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.text(language, 'app_name', fallback: 'E-Kabadi Setu'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  LocalizationService.text(language, 'tagline', fallback: 'Fair Value • Sovereign AI'),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.role == 'recycler'
                  ? const Color(0xFF4DF2C6).withAlpha(40)
                  : accentLime.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.role == 'recycler' ? const Color(0xFF4DF2C6) : accentLime,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.role == 'recycler' ? Icons.factory_rounded : Icons.person_rounded,
                  size: 14,
                  color: widget.role == 'recycler' ? const Color(0xFF4DF2C6) : accentLime,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.role == 'recycler' ? const Color(0xFF4DF2C6) : accentLime,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<IndicLanguage>(
            tooltip: 'All Indian Languages',
            icon: const Icon(Icons.translate_rounded),
            onSelected: _changeLanguage,
            itemBuilder: (_) => IndicLanguage.values.map((lang) {
              return PopupMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.nativeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('(${lang.englishLabel})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Sign Out / Switch Persona',
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: pageIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pageIndex,
        onDestinationSelected: (val) => setState(() => pageIndex = val),
        indicatorColor: accentLime,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: LocalizationService.text(language, 'home', fallback: 'Home'),
          ),
          NavigationDestination(
            icon: Icon(widget.role == 'recycler' ? Icons.fact_check_rounded : Icons.add_a_photo_rounded),
            label: widget.role == 'recycler'
                ? 'Verify Lots'
                : LocalizationService.text(language, 'sell', fallback: 'Sell'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.currency_rupee_rounded),
            label: LocalizationService.text(language, 'prices', fallback: 'Prices'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.factory_rounded),
            label: LocalizationService.text(language, 'recyclers', fallback: 'Recyclers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.eco_rounded),
            label: LocalizationService.text(language, 'ledger', fallback: 'Credits'),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.language,
    required this.lots,
    required this.onNavigate,
    required this.sarvam,
    required this.repository,
  });

  final IndicLanguage language;
  final List<WasteLot> lots;
  final ValueChanged<int> onNavigate;
  final SarvamAiService sarvam;
  final AppRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static bool _notifiedOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (_notifiedOffline) return;
    try {
      final res = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 204 && mounted) {
        _popOfflineAlert();
      }
    } catch (_) {
      if (mounted) {
        _popOfflineAlert();
      }
    }
  }

  void _popOfflineAlert() {
    _notifiedOffline = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: accentLime, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No Internet Connection. Offline Mode is active — lots are saved locally and will auto-sync when online.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF0F261E),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lots = widget.lots;
    final language = widget.language;
    final onNavigate = widget.onNavigate;
    final repository = widget.repository;
    final sarvam = widget.sarvam;

    final paidEarnings = lots.where((l) => l.paymentStatus == 'Paid').fold<double>(0, (sum, l) => sum + l.finalPrice);
    final totalGreenCredits = lots.fold<int>(0, (sum, l) => sum + l.greenCreditsEarned);
    final co2OffsetKg = lots.fold<double>(0, (sum, l) => sum + (l.weight * 2.2));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizationService.text(language, 'greeting', fallback: 'Namaste, Colleague 👋'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                Text(
                  LocalizationService.text(language, 'hero_subtitle', fallback: 'Fair rates powered by Sovereign AI'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: accentLime),
              onPressed: () {
                final text = LocalizationService.text(language, 'hero_subtitle', fallback: 'Fair rates powered by Sovereign AI');
                sarvam.speakText(text: text, language: language);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ESG Circular Green Credits Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryDark, Color(0xFF1E5C47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentLime,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.energy_savings_leaf_rounded, size: 14, color: inkDark),
                        SizedBox(width: 4),
                        Text(
                          'MISSION LiFE & ESG',
                          style: TextStyle(color: inkDark, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${lots.length} Verified Handovers',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalGreenCredits',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 8),
                    child: Text('Green Credits', style: TextStyle(color: accentLime, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'CO₂ Offset: ${co2OffsetKg.toStringAsFixed(1)} kg | Toxic Lead & Mercury Diverted',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onNavigate(1),
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: Text(
                        LocalizationService.text(language, 'sell', fallback: 'Sell Material'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentLime,
                        foregroundColor: inkDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecyclerMapScreen(
                            recyclers: repository.recyclers,
                            language: language,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_rounded, color: Colors.white),
                    label: const Text('Map', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Cash Received',
                value: '₹${paidEarnings.toStringAsFixed(0)}',
                color: const Color(0xFFE5F5EC),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Active Lots',
                value: '${lots.where((l) => l.paymentStatus != 'Paid').length}',
                color: const Color(0xFFFFF2D6),
                icon: Icons.hourglass_top_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text('Quick Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _QuickActionTile(
              icon: Icons.price_check_rounded,
              title: LocalizationService.text(language, 'prices', fallback: 'Live Rates'),
              subtitle: 'Today\'s scrap board',
              color: const Color(0xFFEAF5D8),
              onTap: () => onNavigate(2),
            ),
            _QuickActionTile(
              icon: Icons.map_outlined,
              title: LocalizationService.text(language, 'recyclers', fallback: 'Map & Recyclers'),
              subtitle: 'Verified centers',
              color: const Color(0xFFE0EEF8),
              onTap: () => onNavigate(3),
            ),
            _QuickActionTile(
              icon: Icons.health_and_safety_rounded,
              title: 'Safety Protocol',
              subtitle: 'Zero toxic exposure',
              color: const Color(0xFFFFE5E0),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SafetyPage(language: language, sarvam: sarvam))),
            ),
            _QuickActionTile(
              icon: Icons.account_balance_wallet_rounded,
              title: LocalizationService.text(language, 'ledger', fallback: 'Ledger'),
              subtitle: 'Handover passes',
              color: const Color(0xFFFFEFCE),
              onTap: () => onNavigate(4),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class SellPage extends StatefulWidget {
  const SellPage({
    super.key,
    required this.language,
    required this.repository,
    required this.onSave,
    required this.sarvam,
  });

  final IndicLanguage language;
  final AppRepository repository;
  final LotSaver onSave;
  final SarvamAiService sarvam;

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final picker = ImagePicker();
  final ai = GeminiMaterialService();
  final weightCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final voiceQueryCtrl = TextEditingController();

  Uint8List? imageBytes;
  String imageName = 'material.jpg';
  String category = 'Copper Cables';
  String location = 'India (Pan-India Geo-Tag • Tap to set)';
  double? latitude;
  double? longitude;
  bool busy = false;
  String? message;
  WasteLot? currentLot;

  // AI Elevated properties
  String composition = 'Standard recyclable scrap';
  String hazardRisk = 'Low';
  int purityScore = 85;

  @override
  void initState() {
    super.initState();
    captureGps();
  }

  Future<void> pickImage(ImageSource source) async {
    final file = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1400, maxHeight: 1400);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      imageBytes = bytes;
      imageName = file.name;
      message = null;
      currentLot = null;
    });
  }

  Future<void> captureGps() async {
    setState(() => busy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 3),
        ),
      );
      if (!mounted) return;
      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
        location = '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
        message = 'GPS tagged ($location). Resolving city...';
        busy = false;
      });
      // Resolve readable name asynchronously in background
      _resolveReadableLocation(pos.latitude, pos.longitude);
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          latitude ??= 20.5937;
          longitude ??= 78.9629;
          location = 'India (Pan-India Active • Tap to set)';
          message = 'Device GPS offline or timed out. Tap location card to pick your city.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _resolveReadableLocation(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10');
      final res = await http.get(uri, headers: {'User-Agent': 'EKabadiSetuApp/1.0'}).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        final city = addr?['city'] ?? addr?['town'] ?? addr?['county'] ?? addr?['state_district'] ?? addr?['suburb'] ?? '';
        final state = addr?['state'] ?? '';
        if (city.isNotEmpty && state.isNotEmpty) {
          if (mounted) {
            setState(() {
              location = '$city, $state';
              message = 'Location verified: $location (CPCB & State PCB Compliant)';
            });
            return;
          }
        } else if (data['display_name'] != null) {
          final parts = (data['display_name'] as String).split(',');
          final shortName = parts.take(2).map((s) => s.trim()).join(', ');
          if (mounted) {
            setState(() {
              location = shortName;
              message = 'Location verified: $location (CPCB & State PCB Compliant)';
            });
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _showCityPickerDialog() {
    final cities = [
      {'name': 'Pune, Maharashtra', 'lat': 18.5204, 'lon': 73.8567},
      {'name': 'Mumbai, Maharashtra', 'lat': 19.0760, 'lon': 72.8777},
      {'name': 'Delhi-NCR', 'lat': 28.6139, 'lon': 77.2090},
      {'name': 'Bengaluru, Karnataka', 'lat': 12.9716, 'lon': 77.5946},
      {'name': 'Hyderabad, Telangana', 'lat': 17.3850, 'lon': 78.4867},
      {'name': 'Chennai, Tamil Nadu', 'lat': 13.0827, 'lon': 80.2707},
      {'name': 'Kolkata, West Bengal', 'lat': 22.5726, 'lon': 88.3639},
      {'name': 'Ahmedabad, Gujarat', 'lat': 23.0225, 'lon': 72.5714},
      {'name': 'Jaipur, Rajasthan', 'lat': 26.9124, 'lon': 75.7873},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceEmerald,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_city_rounded, color: accentLime),
                    SizedBox(width: 8),
                    Text(
                      'Select Lot Location / City',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quick-pick your hub for instant CPCB & State PCB compliance',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cities.map((c) {
                    final isSelected = location.contains((c['name'] as String).split(',').first);
                    return ActionChip(
                      backgroundColor: isSelected ? accentLime : inkDark,
                      side: BorderSide(color: isSelected ? accentLime : cardBorder),
                      label: Text(
                        c['name'] as String,
                        style: TextStyle(
                          color: isSelected ? inkDark : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          location = c['name'] as String;
                          latitude = c['lat'] as double;
                          longitude = c['lon'] as double;
                          message = 'Location set to $location (Traceability Active)';
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    captureGps();
                  },
                  icon: const Icon(Icons.my_location_rounded, color: mintGlow),
                  label: const Text('Auto-Detect via Device GPS', style: TextStyle(color: mintGlow)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: mintGlow),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> classifyWithGemini() async {
    if (imageBytes == null) {
      setState(() => message = 'Please capture a photo first.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final res = await ai.classify(imageBytes!, imageName);
      if (!mounted) return;
      setState(() {
        category = res.category;
        descCtrl.text = res.description;
        composition = res.compositionBreakdown;
        hazardRisk = res.hazardRiskLevel;
        purityScore = res.estimatedPurityPercentage;
        message = 'Gemini Vision: ${(res.confidence * 100).round()}% Confidence | Purity: $purityScore%';
      });

      // Announce safety in user's chosen language via Sarvam
      widget.sarvam.speakText(
        text: '${res.category}. ${res.safetyWarning}',
        language: widget.language,
      );
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _triggerVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F261E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return VoiceAssistantSheet(
          language: widget.language,
          sarvam: widget.sarvam,
          onExtracted: ({
            required String category,
            required double weight,
            required String condition,
            required String transcript,
          }) {
            setState(() {
              this.category = category;
              if (weight > 0) {
                weightCtrl.text = weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1);
              }
              descCtrl.text = condition.isNotEmpty ? condition : transcript;
              message = 'Voice AI Extracted: $category • ${descCtrl.text}';
            });
          },
        );
      },
    );
  }

  Future<void> createAndSaveLot() async {
    final weight = double.tryParse(weightCtrl.text.trim());
    if (weight == null || weight <= 0) {
      setState(() => message = 'Please enter a valid weight.');
      return;
    }
    final p = widget.repository.priceFor(category);
    final est = weight * p.rate;
    final newLot = WasteLot(
      id: 'LOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      category: category,
      description: descCtrl.text.trim().isEmpty ? 'E-waste lot' : descCtrl.text.trim(),
      weight: weight,
      estimatedValue: est,
      quotedPrice: 0,
      finalPrice: 0,
      createdAt: DateTime.now(),
      location: location,
      latitude: latitude ?? 20.5937,
      longitude: longitude ?? 78.9629,
      recyclerId: '',
      recyclerName: '',
      status: 'Open',
      paymentStatus: 'Pending',
      paymentMode: 'Cash',
      imageBase64: imageBytes != null ? base64Encode(imageBytes!) : '',
      synced: false,
      compositionBreakdown: composition,
      hazardLevel: hazardRisk,
      greenCreditsEarned: (weight * p.esgPointsPerKg).toInt(),
    );

    await widget.onSave(newLot);
    setState(() {
      currentLot = newLot;
      message = 'Lot created! Match verified recycler offers below.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocalizationService.text(lang, 'sell', fallback: 'Create Material Lot'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            IconButton(
              icon: const Icon(Icons.mic_none_rounded, color: primaryDark),
              onPressed: _triggerVoiceAssistant,
              tooltip: 'Sarvam Voice Assistant',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Photo / Scan Container with HUD
        Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceEmerald,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder, width: 1.2),
              ),
              child: imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 55, color: mintGlow),
                        const SizedBox(height: 8),
                        Text(
                          LocalizationService.text(lang, 'camera_action', fallback: 'Photograph or Scan Scrap'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
            if (imageBytes != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: inkDark.withAlpha(220),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_rounded, size: 14, color: accentLime),
                      const SizedBox(width: 6),
                      Text(
                        'Purity: $purityScore% | Hazard: $hazardRisk',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => pickImage(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cardBorder),
                  foregroundColor: mintGlow,
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => pickImage(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cardBorder),
                  foregroundColor: mintGlow,
                ),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : classifyWithGemini,
          style: FilledButton.styleFrom(
            backgroundColor: accentLime,
            foregroundColor: inkDark,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Analyze with Gemini Multimodal Vision', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),

        // Voice Assistant Direct Trigger Banner
        InkWell(
          onTap: _triggerVoiceAssistant,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceEmerald,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic_rounded, color: accentLime),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocalizationService.text(lang, 'voice_action', fallback: 'Tap to speak lot details in your language'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: mintGlow, size: 14),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey(category),
          initialValue: category,
          dropdownColor: surfaceEmerald,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Material Category',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: inkDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentLime, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.category_rounded, color: accentLime),
          ),
          items: widget.repository.prices.map((p) {
            return DropdownMenuItem(
              value: p.category,
              child: Text('${p.icon}  ${p.category} (₹${p.rate.toStringAsFixed(0)}/${p.unit})'),
            );
          }).toList(),
          onChanged: (v) => setState(() => category = v ?? category),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Weight or Quantity',
            labelStyle: const TextStyle(color: Colors.white70),
            suffixText: 'kg / units',
            suffixStyle: const TextStyle(color: mintGlow),
            filled: true,
            fillColor: inkDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentLime, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.scale_rounded, color: accentLime),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descCtrl,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Condition / Description',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: inkDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentLime, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.notes_rounded, color: accentLime),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.my_location_rounded, color: accentLime),
            title: Text(location, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('GPS recorded for traceability • Tap to change', style: TextStyle(color: Colors.white60)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Choose city manually',
                  icon: const Icon(Icons.edit_location_alt_rounded, color: mintGlow),
                  onPressed: _showCityPickerDialog,
                ),
                IconButton(
                  tooltip: 'Redetect GPS',
                  onPressed: busy ? null : captureGps,
                  icon: const Icon(Icons.refresh_rounded, color: accentLime),
                ),
              ],
            ),
            onTap: _showCityPickerDialog,
          ),
        ),

        if (message != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceEmerald,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mintGlow),
            ),
            child: Text(message!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],

        if (busy) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator(color: accentLime)),

        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : createAndSaveLot,
          icon: const Icon(Icons.calculate_rounded),
          label: const Text('Save Lot & Evaluate Recycler Offers', style: TextStyle(fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            backgroundColor: accentLime,
            foregroundColor: inkDark,
            minimumSize: const Size.fromHeight(54),
          ),
        ),

        if (currentLot != null) ...[
          const SizedBox(height: 20),
          _LotEstimateDisplay(
            lot: currentLot!,
            price: widget.repository.priceFor(currentLot!.category),
            sarvam: widget.sarvam,
            language: lang,
          ),
          const SizedBox(height: 16),
          const Text('Verified Recycler Quotes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...widget.repository.matchesFor(currentLot!.category).map((rec) {
            final quote = currentLot!.estimatedValue * rec.rateFactor;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rec.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        Text(
                          '₹${quote.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${rec.distanceKm} km away • ${rec.pickup ? 'Pickup available' : 'Drop-off required'}'),
                    Text('MPCB: ${rec.authorization}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        final updated = currentLot!.copyWith(
                          recyclerId: rec.id,
                          recyclerName: rec.name,
                          quotedPrice: quote,
                          status: 'Offer Accepted',
                        );
                        await widget.onSave(updated);
                        if (!context.mounted) return;
                        setState(() => currentLot = updated);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HandoverPage(
                              lot: updated,
                              recycler: rec,
                              onSave: widget.onSave,
                              language: lang,
                              sarvam: widget.sarvam,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: primaryDark),
                      child: const Text('Accept Offer & Create Handover Pass'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _LotEstimateDisplay extends StatelessWidget {
  const _LotEstimateDisplay({
    required this.lot,
    required this.price,
    required this.sarvam,
    required this.language,
  });

  final WasteLot lot;
  final MaterialPrice price;
  final SarvamAiService sarvam;
  final IndicLanguage language;

  @override
  Widget build(BuildContext context) {
    final speech = '${lot.category}. Estimated value ${lot.estimatedValue.toStringAsFixed(0)} rupees.';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: inkDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(price.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lot.category,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: accentLime),
                onPressed: () => sarvam.speakText(text: speech, language: language),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('ESTIMATED MARKET VALUE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(
            '₹${lot.estimatedValue.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          Text(
            'Fair Range: ₹${(lot.weight * price.low).toStringAsFixed(0)} - ₹${(lot.weight * price.high).toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Composition: ${lot.compositionBreakdown}',
            style: const TextStyle(color: accentLime, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class PriceBoardPage extends StatefulWidget {
  const PriceBoardPage({
    super.key,
    required this.language,
    required this.repository,
    required this.sarvam,
  });

  final IndicLanguage language;
  final AppRepository repository;
  final SarvamAiService sarvam;

  @override
  State<PriceBoardPage> createState() => _PriceBoardPageState();
}

class _PriceBoardPageState extends State<PriceBoardPage> {
  final GeminiMaterialService _gemini = GeminiMaterialService();
  bool _isRefreshing = false;
  String _lastUpdatedText = 'All-India Market Benchmark (Real-Time)';

  Future<void> _refreshWithGemini() async {
    setState(() => _isRefreshing = true);
    try {
      final livePrices = await _gemini.fetchDailyMarketPrices();
      if (!mounted) return;

      // Real mathematical calculation of price difference:
      // Compare each new price with the current baseline in repository
      final List<MaterialPrice> updatedWithRealTrends = [];
      for (final live in livePrices) {
        final existingMatch = widget.repository.prices.where(
          (p) => p.category.toLowerCase().trim() == live.category.toLowerCase().trim(),
        );

        if (existingMatch.isNotEmpty) {
          final old = existingMatch.first;
          if (old.rate > 0) {
            // Real percentage difference: ((new - old) / old) * 100
            final realTrend = ((live.rate - old.rate) / old.rate) * 100.0;
            final roundedTrend = (realTrend * 10).round() / 10.0;
            updatedWithRealTrends.add(live.copyWith(trend: roundedTrend));
            continue;
          }
        }
        updatedWithRealTrends.add(live);
      }

      setState(() {
        widget.repository.updatePrices(updatedWithRealTrends);
        final now = DateTime.now();
        _lastUpdatedText = 'Updated via Gemini AI • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.auto_awesome, color: accentLime, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Live rates updated via Gemini AI with real trend differences!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF0F261E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not refresh live rates: $e'),
          backgroundColor: const Color(0xFF8B1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.text(widget.language, 'prices', fallback: 'Today\'s Price Board'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lastUpdatedText,
                    style: const TextStyle(color: mintGlow, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _isRefreshing ? null : _refreshWithGemini,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: inkDark),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _isRefreshing ? 'Updating...' : 'Gemini AI',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accentLime,
                foregroundColor: inkDark,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.repository.prices.map((p) {
          final speech = '${p.category}. ${p.rate.toStringAsFixed(0)} rupees per ${p.unit}.';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceEmerald,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(p.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.category,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                            ),
                          ),
                          if (p.trend != 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.trend >= 0 ? const Color(0x2E4DF2C6) : const Color(0x2EFF5252),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: p.trend >= 0 ? const Color(0xFF4DF2C6) : const Color(0xFFFF5252),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${p.trend >= 0 ? "▲ +" : "▼ "}${p.trend.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: p.trend >= 0 ? const Color(0xFF4DF2C6) : const Color(0xFFFF8A80),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Band: ₹${p.low.toStringAsFixed(0)} - ₹${p.high.toStringAsFixed(0)} / ${p.unit}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'CO₂: ${p.co2OffsetPerKg} kg/kg • ${p.esgPointsPerKg} ESG pts',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${p.rate.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accentLime),
                    ),
                    Text(
                      '/${p.unit}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => widget.sarvam.speakText(text: speech, language: widget.language),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: inkDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Icon(Icons.volume_up_rounded, color: mintGlow, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class RecyclersPage extends StatelessWidget {
  const RecyclersPage({
    super.key,
    required this.language,
    required this.repository,
  });

  final IndicLanguage language;
  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Authorized Recyclers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('CPCB & State PCB Authorized Facilities (Pan-India)', style: TextStyle(color: mintGlow, fontSize: 12)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecyclerMapScreen(
                      recyclers: repository.recyclers,
                      language: language,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('Open Map'),
              style: FilledButton.styleFrom(
                backgroundColor: accentLime,
                foregroundColor: inkDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...repository.recyclers.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surfaceEmerald,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: accentLime),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(rec.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${rec.location} • ${rec.distanceKm} km away', style: const TextStyle(color: mintGlow)),
                  const SizedBox(height: 3),
                  Text(rec.pickup ? '🚚 Free Pickup Available' : '📍 Drop-off center', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text('Accepts: ${rec.categories.join(', ')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Divider(height: 18, color: cardBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Govt Auth: ${rec.authorization}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70)),
                      Text(rec.phone, style: const TextStyle(fontWeight: FontWeight.bold, color: accentLime)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class LedgerPage extends StatelessWidget {
  const LedgerPage({
    super.key,
    required this.language,
    required this.lots,
  });

  final IndicLanguage language;
  final List<WasteLot> lots;

  @override
  Widget build(BuildContext context) {
    final paid = lots.where((l) => l.paymentStatus == 'Paid').fold<double>(0, (sum, l) => sum + l.finalPrice);
    final totalCredits = lots.fold<int>(0, (sum, l) => sum + l.greenCreditsEarned);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Earnings & Green Credits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            FilledButton.icon(
              onPressed: () {
                ComplianceReportService.generateAndPrintReport(
                  lots: lots,
                  collectorName: 'Raju (Verified Lead Collector)',
                  collectorLocation: 'Pune Sector 4 Center',
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
              label: const Text('Export Audit Pass'),
              style: FilledButton.styleFrom(backgroundColor: primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryDark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SETTLED INCOME', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Text('₹${paid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.energy_savings_leaf_rounded, color: accentLime, size: 16),
                  const SizedBox(width: 4),
                  Text('$totalCredits ESG Green Credits Earned', style: const TextStyle(color: accentLime, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (lots.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No transactions recorded yet.')),
            ),
          )
        else
          ...lots.map((lot) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: lot.paymentStatus == 'Paid' ? const Color(0xFFDCEFE4) : const Color(0xFFFFE8B9),
                  child: Icon(lot.paymentStatus == 'Paid' ? Icons.check_rounded : Icons.schedule_rounded, color: primaryDark),
                ),
                title: Text(lot.category, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${lot.id}\n${lot.status} • ${lot.paymentMode} • +${lot.greenCreditsEarned} Credits'),
                trailing: Text(
                  '₹${(lot.finalPrice > 0 ? lot.finalPrice : lot.estimatedValue).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({
    super.key,
    required this.language,
    required this.sarvam,
  });

  final IndicLanguage language;
  final SarvamAiService sarvam;

  @override
  Widget build(BuildContext context) {
    final safetyItems = [
      ('🔥', 'Never burn cable insulation', 'केबल को कभी न जलाएं'),
      ('🔋', 'Do not open swollen or damaged batteries', 'फूली हुई बैटरी न खोलें'),
      ('📺', 'Do not break CRT glass or tubes', 'सीआरटी कांच न तोड़ें'),
      ('🧪', 'Never use acid leaching in open areas', 'धातु निकालने के लिए तेजाब का उपयोग न करें'),
      ('🥽', 'Wear eye protection, gloves and boots', 'दस्ताने, जूते और आंखों की सुरक्षा पहनें'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Hazard Protocol'),
        backgroundColor: inkDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Handling Protocols', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...safetyItems.map((item) {
            final text = language == IndicLanguage.hindi ? item.$3 : item.$2;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Text(item.$1, style: const TextStyle(fontSize: 30)),
                title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: primaryDark),
                  onPressed: () => sarvam.speakText(text: text, language: language),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceEmerald,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accentLime),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceEmerald,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: accentLime),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: mintGlow)),
          ],
        ),
      ),
    );
  }
}
