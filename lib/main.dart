import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/dashboard.dart';
import 'utils/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await StorageService().init();
  await NotificationService().init();
  
  var box = await Hive.openBox('settings');
  T.code = box.get('language', defaultValue: 'en');
  
  runApp(const JuzyApp());
}

class JuzyApp extends StatefulWidget {
  const JuzyApp({super.key});
  @override
  State<JuzyApp> createState() => _JuzyAppState();
}

class _JuzyAppState extends State<JuzyApp> {
  String _currentTheme = 'system';
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox('settings');
    setState(() {
      _currentTheme = _settingsBox.get('theme', defaultValue: 'system');
      T.code = _settingsBox.get('language', defaultValue: 'en');
    });
  }

  void _changeTheme(String theme) {
    setState(() => _currentTheme = theme);
    _settingsBox.put('theme', theme);
  }

  void _changeLanguage(String lang) {
    setState(() => T.code = lang);
    _settingsBox.put('language', lang);
  }

  @override
  Widget build(BuildContext context) {
    final retroTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD4522A), 
        secondary: Color(0xFF6BB8A7), 
        surface: Color(0xFFF9F3E6), 
        onSurface: Color(0xFF3A2817), 
        primaryContainer: Color(0xFFF2B84B),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9F3E6),
      fontFamily: 'Courier', 
      cardColor: Colors.white,
    );

    ThemeData themeData;
    if (_currentTheme == 'retro') themeData = retroTheme;
    else if (_currentTheme == 'dark') themeData = ThemeData.dark(useMaterial3: true);
    else themeData = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JUZY',
      theme: themeData,
      home: DashboardPage(
        onThemeChanged: _changeTheme,
        currentTheme: _currentTheme,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}