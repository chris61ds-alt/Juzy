import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatelessWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;
  const SettingsPage({super.key, required this.onThemeChanged, required this.currentTheme, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(children: [
        ListTile(title: const Text("Dark Mode"), onTap: () => onThemeChanged('dark')),
        ListTile(title: const Text("Light Mode"), onTap: () => onThemeChanged('light')),
        ListTile(title: const Text("Retro Mode"), onTap: () => onThemeChanged('retro')),
        const Divider(),
        ListTile(title: const Text("English"), onTap: () => onLanguageChanged('en')),
        ListTile(title: const Text("Deutsch"), onTap: () => onLanguageChanged('de')),
        const Divider(),
        ListTile(title: const Text("Delete All Data", style: TextStyle(color: Colors.red)), onTap: () { StorageService().deleteAllItems(); Navigator.pop(context); }),
      ]),
    );
  }
}