import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard.dart';
import 'utils/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String theme = prefs.getString('theme') ?? 'dark';
  String lang = prefs.getString('lang') ?? 'de';
  T.code = lang;
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(JuzyApp(initialTheme: theme, initialLang: lang));
}

class JuzyApp extends StatefulWidget {
  final String initialTheme;
  final String initialLang;
  const JuzyApp({super.key, required this.initialTheme, required this.initialLang});

  @override
  State<JuzyApp> createState() => _JuzyAppState();
}

class _JuzyAppState extends State<JuzyApp> {
  late String _currentTheme;
  
  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  void _changeTheme(String newTheme) async {
    setState(() => _currentTheme = newTheme);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', newTheme);
  }

  void _changeLanguage(String code) async {
    setState(() => T.code = code);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lang', code);
  }

  ThemeData _getTheme() {
    if (_currentTheme == 'retro') {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9F3E6), 
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFD4522A), 
          secondary: Color(0xFF6BB8A7), 
          surface: Color(0xFFF4D98D), 
          surfaceVariant: Color(0xFFE8D5B5),
          onSurface: Color(0xFF3A2817), 
        ),
        textTheme: GoogleFonts.courierPrimeTextTheme(),
      );
    } else if (_currentTheme == 'light') {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6BB8A7), brightness: Brightness.light),
        textTheme: GoogleFonts.dmSansTextTheme(),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6BB8A7), brightness: Brightness.dark),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUZY 🥭',
      debugShowCheckedModeBanner: false,
      theme: _getTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de'), Locale('en')],
      
      // FIXED: Scale changed from 1.15 to 1.10 as requested
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.10) 
          ),
          child: child!,
        );
      },

      home: DashboardPage(
        onThemeChanged: _changeTheme,
        currentTheme: _currentTheme,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}