import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';

class SettingsPage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;
  final VoidCallback onDeleteAllData; 

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.onLanguageChanged,
    required this.onDeleteAllData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color _juzyColor = const Color(0xFF6BB8A7);

  void _handleDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(T.get('delete_confirm_title')),
        content: Text(T.get('delete_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(T.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              widget.onDeleteAllData();
              Navigator.pop(ctx);
              Navigator.pop(context); 
            },
            child: Text(T.get('delete')),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRetro = widget.currentTheme == 'retro';
    final Color groupBg = Theme.of(context).colorScheme.surface;
    final Color textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).textTheme.bodyMedium!.color!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(T.get('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- APPEARANCE ---
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Text(T.get('appearance'), style: TextStyle(color: _juzyColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(15),
              border: isRetro ? Border.all(color: Colors.black12, width: 1.5) : null,
            ),
            child: Column(
              children: [
                _buildRadioTile('retro', T.get('theme_retro')),
                const Divider(height: 1, indent: 15, endIndent: 15),
                _buildRadioTile('dark', T.get('theme_dark')),
                const Divider(height: 1, indent: 15, endIndent: 15),
                _buildRadioTile('light', T.get('theme_light')),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- LANGUAGE ---
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Text(T.get('language'), style: TextStyle(color: _juzyColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(15),
              border: isRetro ? Border.all(color: Colors.black12, width: 1.5) : null,
            ),
            child: Column(
              children: [
                _buildLangTile('de', 'Deutsch'),
                const Divider(height: 1, indent: 15, endIndent: 15),
                _buildLangTile('en', 'English'),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- DATA ---
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Text(T.get('data_management'), style: TextStyle(color: _juzyColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(15),
              border: isRetro ? Border.all(color: Colors.black12, width: 1.5) : null,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(T.get('delete_all_data'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _handleDeleteAll();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 50),
          
          // --- FOOTER / CREDITS ---
          Center(
            child: Column(
              children: [
                Text(
                  "Vasco da Soda", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: textColor.withOpacity(0.7),
                    letterSpacing: 1.0
                  )
                ),
                const SizedBox(height: 4),
                const Text(
                  "Version 1.0.0+1", 
                  style: TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRadioTile(String themeKey, String label) {
    bool isSelected = widget.currentTheme == themeKey;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: _juzyColor) : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onThemeChanged(themeKey);
      },
    );
  }

  Widget _buildLangTile(String langCode, String label) {
    bool isSelected = T.code == langCode;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: _juzyColor) : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onLanguageChanged(langCode);
        setState(() {}); 
      },
    );
  }
}