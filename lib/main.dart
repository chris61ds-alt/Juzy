import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/item.dart';
import 'screens/dashboard.dart';
import 'utils/translations.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ItemAdapter());
  await Hive.openBox<Item>('items');
  await Hive.openBox('settings');
  
  await T.init(); // Lädt gespeicherte Sprache
  
  runApp(const JuzyApp());
}

class JuzyApp extends StatefulWidget {
  const JuzyApp({super.key});
  @override
  State<JuzyApp> createState() => _JuzyAppState();
}

class _JuzyAppState extends State<JuzyApp> {
  final StorageService _storage = StorageService();
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _storage.getTheme();
  }

  void _changeTheme(String newMode) {
    setState(() {
      _themeMode = newMode;
      _storage.saveTheme(newMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: T.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          key: ValueKey(locale), // Erzwingt Rebuild bei Sprachwechsel
          title: 'Juzy',
          debugShowCheckedModeBanner: false,
          theme: _themeMode == 'dark' ? ThemeData.dark() : (_themeMode == 'retro' ? ThemeData(scaffoldBackgroundColor: const Color(0xFFF9F3E6)) : ThemeData.light()),
          home: DashboardPage(
            onThemeChanged: _changeTheme,
            onLanguageChanged: (l) => T.setLanguage(l),
            currentTheme: _themeMode,
          ),
        );
      },
    );
  }
}