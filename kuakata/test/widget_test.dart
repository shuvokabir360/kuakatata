import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuakata/providers/language_provider.dart';
import 'package:kuakata/providers/theme_provider.dart';
import 'package:kuakata/providers/user_provider.dart';
import 'package:kuakata/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders LanguageSelectionScreen on first run', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const KuakataApp(),
      ),
    );
    
    // Wait for the async SharedPreferences loading in provider constructors to complete
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify that LanguageSelectionScreen is shown and contains the welcome text.
    expect(find.text('Welcome to Kuakata'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
  });
}
