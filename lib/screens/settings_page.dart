import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';
import '../models/demo_data.dart';
import '../models/item.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;
  final VoidCallback onLoadDemoData;
  final VoidCallback onDeleteAllData;

  const SettingsPage({
    super.key, 
    required this.onThemeChanged, 
    required this.currentTheme,
    required this.onLoadDemoData,
    required this.onDeleteAllData,
    required this.onLanguageChanged
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _devTapCount = 0;

  Future<void> _exportToClipboard() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('items') ?? "[]";
    final aliasJson = prefs.getString('cat_aliases') ?? "{}";
    
    Map<String, dynamic> backupData = {
      "items": json.decode(itemsJson),
      "aliases": json.decode(aliasJson),
      "version": 1
    };
    
    String backupString = json.encode(backupData);
    await Clipboard.setData(ClipboardData(text: backupString));
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup in Zwischenablage kopiert!")));
    }
  }

  Future<void> _importFromClipboard() async {
    ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);
    String? content = cdata?.text;
    
    if (content == null || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zwischenablage ist leer.")));
      return;
    }

    try {
      Map<String, dynamic> data = json.decode(content);
      if (data.containsKey('items')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('items', json.encode(data['items']));
        if (data.containsKey('aliases')) {
          await prefs.setString('cat_aliases', json.encode(data['aliases']));
        }
        widget.onLoadDemoData(); 
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daten importiert!")));
          Navigator.pop(context);
        }
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fehler beim Import.")));
    }
  }

  void _handleDevTap() {
    _devTapCount++;
    if (_devTapCount == 3) {
      HapticFeedback.heavyImpact();
      _loadInternalDemoData(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐣 EASTER EGG: Demo Daten geladen!")));
      _devTapCount = 0;
    }
  }

  void _loadInternalDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Item> demos = DemoData.getDemoItems();
    await prefs.setString('items', json.encode(demos.map((e) => e.toJson()).toList()));
    widget.onLoadDemoData(); 
  }

  @override
  Widget build(BuildContext context) {
    bool isHappy = widget.currentTheme == 'retro';
    Color textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(T.get('settings'))),
      body: ListView(
        children: [
          _sectionHeader(T.get('language')),
          ListTile(
            title: Text(T.get('lang_de')),
            leading: const Text("🇩🇪", style: TextStyle(fontSize: 24)),
            trailing: T.code == 'de' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () { widget.onLanguageChanged('de'); setState(() {}); },
          ),
          ListTile(
            title: Text(T.get('lang_en')),
            leading: const Text("🇬🇧", style: TextStyle(fontSize: 24)),
            trailing: T.code == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () { widget.onLanguageChanged('en'); setState(() {}); },
          ),
          
          _sectionHeader(T.get('design')),
          SwitchListTile(
            title: Text(T.get('dark_mode')),
            secondary: const Icon(Icons.dark_mode),
            value: widget.currentTheme == 'dark',
            onChanged: (val) => widget.onThemeChanged(val ? 'dark' : 'light'),
          ),
          SwitchListTile(
            title: Text(T.get('happy_mode') + " 🕹️"), 
            secondary: const Icon(Icons.videogame_asset),
            value: isHappy,
            activeColor: const Color(0xFFD4522A),
            onChanged: (val) => widget.onThemeChanged(val ? 'retro' : 'light'),
          ),

          _sectionHeader(T.get('backup_security')),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text("Backup kopieren"),
            subtitle: Text(T.get('backup_create_sub')),
            onTap: _exportToClipboard,
          ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text("Backup einfügen"),
            subtitle: Text(T.get('backup_import_sub')),
            onTap: _importFromClipboard,
          ),

          _sectionHeader(T.get('data')),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(T.get('delete_all'), style: const TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text(T.get('delete_all_confirm')),
                content: Text(T.get('delete_all_sub')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { widget.onDeleteAllData(); Navigator.pop(ctx); Navigator.pop(context); }, child: Text(T.get('delete')))
                ],
              ));
            },
          ),
          
          const SizedBox(height: 50),
          Center(
            child: GestureDetector(
              onTap: _handleDevTap,
              child: Text(
                T.get('dev_by'), 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12)
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 5), child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.5)));
  }
}