import 'package:flutter_test/flutter_test.dart';
import 'package:e_kabadi_setu/models.dart';
import 'package:e_kabadi_setu/localization_service.dart';
import 'package:e_kabadi_setu/sarvam_service.dart';
import 'package:e_kabadi_setu/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('E-Kabadi Setu Unit & Logic Tests', () {
    test('Localization Service supports 11 Indian Languages', () {
      expect(IndicLanguage.values.length, 11);
      final hindiAppName = LocalizationService.text(IndicLanguage.hindi, 'app_name');
      expect(hindiAppName, 'ई-कबाड़ी सेतु');
      final marathiAppName = LocalizationService.text(IndicLanguage.marathi, 'app_name');
      expect(marathiAppName, 'ई-कबाडी सेतू');
    });

    test('WasteLot JSON encoding and decoding maintains data integrity', () {
      final sampleLot = WasteLot(
        id: 'LOT-TEST-001',
        category: 'Copper Cables',
        description: 'Clean bright wire scrap',
        weight: 12.5,
        estimatedValue: 4125.0,
        quotedPrice: 4200.0,
        finalPrice: 4200.0,
        createdAt: DateTime(2026, 10, 13),
        location: 'Pune Central Yard',
        latitude: 18.5204,
        longitude: 73.8567,
        recyclerId: 'REC-001',
        recyclerName: 'Maha Eco Recycler',
        status: 'created',
        paymentStatus: 'pending',
        paymentMode: 'UPI_DIRECT',
        imageBase64: '',
        synced: true,
        compositionBreakdown: 'Copper 98%, Insulation 2%',
        hazardLevel: 'Low',
        greenCreditsEarned: 312,
      );

      final encoded = WasteLot.encodeList([sampleLot]);
      final decoded = WasteLot.decodeList(encoded);

      expect(decoded.length, 1);
      expect(decoded.first.id, 'LOT-TEST-001');
      expect(decoded.first.category, 'Copper Cables');
      expect(decoded.first.weight, 12.5);
      expect(decoded.first.greenCreditsEarned, 312);
    });

    test('Sarvam Saaras STT parser extracts material and weight correctly', () async {
      final sarvam = SarvamAiService();
      
      // Test Hindi phrase
      final hindiResult = await sarvam.parseVoiceInput(
        speechQuery: '10 किलो तांबे की तार अच्छी कंडीशन',
        language: IndicLanguage.hindi,
      );
      expect(hindiResult['category'], 'Copper Cables');
      expect(hindiResult['weight'], 10.0);

      // Test English phrase
      final engResult = await sarvam.parseVoiceInput(
        speechQuery: '5 kg circuit boards',
        language: IndicLanguage.english,
      );
      expect(engResult['category'], 'PCBs');
      expect(engResult['weight'], 5.0);
    });

    test('Supabase Service config has active endpoints', () {
      final supabase = SupabaseService();
      expect(supabase.url, contains('supabase.co'));
      expect(supabase.anonKey.isNotEmpty, true);
    });
  });
}
