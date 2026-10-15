import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_kabadi_setu/app_repository.dart';
import 'package:e_kabadi_setu/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test renders KabadiSetuApp', (WidgetTester tester) async {
    await tester.pumpWidget(const KabadiSetuApp());
    await tester.pumpAndSettle();
    expect(find.byType(KabadiSetuApp), findsOneWidget);
  });

  testWidgets('AuthScreen does NOT contain Quick Demo Bypass button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const KabadiSetuApp(),
    );
    await tester.pumpAndSettle();

    // Verify Quick Demo Bypass is completely removed
    expect(find.text('Quick Demo Bypass (Collector Pass)'), findsNothing);
    expect(find.text('Quick Demo Bypass'), findsNothing);

    // Verify legitimate login controls remain present
    expect(find.text('Kabadiwala'), findsOneWidget);
    expect(find.text('Recycler'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Mobile Number (+91)'), findsOneWidget);
    expect(find.text('Security PIN / Passcode'), findsOneWidget);
    expect(find.text('Enter Dashboard'), findsOneWidget);
  });

  test('AppRepository session persistence saves and clears correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = AppRepository();

    // Initial state: no session
    final initialSession = await repo.loadSession();
    expect(initialSession, isNull);

    // Save session
    await repo.saveSession(token: 'jwt_test_token_123', role: 'collector', name: 'Raju Kabadi');
    final activeSession = await repo.loadSession();
    expect(activeSession, isNotNull);
    expect(activeSession?['token'], equals('jwt_test_token_123'));
    expect(activeSession?['role'], equals('collector'));
    expect(activeSession?['name'], equals('Raju Kabadi'));

    // Clear session on logout
    await repo.clearSession();
    final clearedSession = await repo.loadSession();
    expect(clearedSession, isNull);
  });
}
