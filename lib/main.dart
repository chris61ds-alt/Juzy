import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/dashboard.dart';
import 'utils/translations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const JuzyApp());
}

class JuzyApp extends StatefulWidget {
  const JuzyApp({super.key});

  @override
  State<JuzyApp> createState() => _JuzyAppState();
}

class _JuzyAppState extends State<JuzyApp> {
  // 'system', 'retro', 'light', 'dark'
  String _currentThemeKey = 'system'; 
  
  void _changeTheme(String newTheme) {
    setState(() {
      _currentThemeKey = newTheme;
    });
    
    // Statusbar Farbe anpassen (nur nötig für Retro/Light/Dark Switch)
    if (newTheme == 'dark') {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  void _changeLanguage(String code) {
    setState(() {
      T.code = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Logik für ThemeMode
    ThemeMode mode;
    if (_currentThemeKey == 'system') {
      mode = ThemeMode.system;
    } else if (_currentThemeKey == 'dark') {
      mode = ThemeMode.dark;
    } else {
      mode = ThemeMode.light;
    }

    // Wenn 'retro' ausgewählt ist, überschreiben wir das Light Theme mit dem Retro-Look
    final bool isRetroMode = _currentThemeKey == 'retro';

    final ThemeData retroTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6BB8A7), 
        secondary: Color(0xFFD4522A), 
        surface: Color(0xFFF9F3E6), 
        onSurface: Color(0xFF3A2817), 
      ),
      scaffoldBackgroundColor: const Color(0xFFF9F3E6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF3A2817),
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF3A2817)),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A2817)),
      ),
    );

    final ThemeData modernLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF6BB8A7),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
    );

    final ThemeData modernDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF6BB8A7),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JUZY',
      
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      themeMode: mode,
      theme: isRetroMode ? retroTheme : modernLight,
      darkTheme: modernDark,

      home: DashboardPage(
        onThemeChanged: _changeTheme,
        currentTheme: _currentThemeKey,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}