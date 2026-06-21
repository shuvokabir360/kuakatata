import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service base URL
  await ApiService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const KuakataApp(),
    ),
  );
}

// ─── Global Color Constants ─────────────────────────────────────────
// Light mode palette
const kPrimary        = Color(0xFF1E9CE1); // Sky blue
const kPrimaryDark    = Color(0xFF1278B8); // Deeper sky
const kAccent         = Color(0xFFFF6B35); // Warm sunset orange (CTA)
const kBgLight        = Color(0xFFF4F8FD); // Very soft blue-tinted white
const kCardLight      = Color(0xFFFFFFFF); // Pure white cards
const kTextDark       = Color(0xFF1A2B4A); // Deep navy text
const kTextSub        = Color(0xFF637A9F); // Muted blue-grey subtext
const kDividerLight   = Color(0xFFE2EAF5); // Soft border

// Dark mode palette
const kBgDark         = Color(0xFF0D1B2E); // Deep navy
const kCardDark       = Color(0xFF162336); // Dark card
const kCardDark2      = Color(0xFF1E2F42); // Slightly lighter card
const kDividerDark    = Color(0xFF243348); // Dark divider

class KuakataApp extends StatelessWidget {
  const KuakataApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kuakata Travel Guide',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      
      // ─── Light Mode ─────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBgLight,
        cardColor: kCardLight,
        dividerColor: kDividerLight,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          secondary: kAccent,
          background: kBgLight,
          surface: kCardLight,
          onPrimary: Colors.white,
          onBackground: kTextDark,
          onSurface: kTextDark,
          outline: kDividerLight,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kCardLight,
          foregroundColor: kTextDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: kTextDark),
          titleTextStyle: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: const IconThemeData(color: kTextDark),
        cardTheme: CardThemeData(
          color: kCardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F6FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDividerLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDividerLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          labelStyle: const TextStyle(color: kTextSub),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
          ),
        ),
        dividerTheme: const DividerThemeData(color: kDividerLight, thickness: 1),
      ),

      // ─── Dark Mode ──────────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBgDark,
        cardColor: kCardDark,
        dividerColor: kDividerDark,
        colorScheme: const ColorScheme.dark(
          primary: kPrimary,
          secondary: kAccent,
          background: kBgDark,
          surface: kCardDark,
          onPrimary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
          outline: kDividerDark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kCardDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        cardTheme: CardThemeData(
          color: kCardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCardDark2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDividerDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDividerDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
          ),
        ),
        dividerTheme: const DividerThemeData(color: kDividerDark, thickness: 1),
      ),
      
      home: langProvider.isFirstTime 
          ? const LanguageSelectionScreen() 
          : const HomeScreen(),
    );
  }
}
