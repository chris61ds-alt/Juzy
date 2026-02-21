import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/translations.dart';

class SettingsPage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentTheme;
  final VoidCallback onDeleteAllData;
  final VoidCallback onLoadDemoData;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.onDeleteAllData,
    required this.onLanguageChanged,
    required this.onLoadDemoData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final bool isRetro = widget.currentTheme == 'retro';
    final Color bgColor = isRetro ? const Color(0xFFF9F3E6) : Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = isRetro ? Colors.white : Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(T.get('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: bgColor, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, T.get('appearance'), cardColor, [
                _buildTile(Icons.palette_outlined, T.get('theme_retro'), widget.currentTheme == 'retro', () => widget.onThemeChanged('retro')),
                _buildTile(Icons.dark_mode_outlined, T.get('theme_dark'), widget.currentTheme == 'dark', () => widget.onThemeChanged('dark')),
                _buildTile(Icons.light_mode_outlined, T.get('theme_light'), widget.currentTheme == 'light', () => widget.onThemeChanged('light')),
                _buildTile(Icons.settings_system_daydream_outlined, T.get('theme_system'), widget.currentTheme == 'system', () => widget.onThemeChanged('system')),
              ]),
              _buildSection(context, T.get('language'), cardColor, [
                _buildTile(Icons.language, "Deutsch", T.code == 'de', () => widget.onLanguageChanged('de')),
                _buildTile(Icons.language, "English", T.code == 'en', () => widget.onLanguageChanged('en')),
              ]),
              _buildSection(context, T.get('data_management'), cardColor, [
                ListTile(leading: const Icon(Icons.playlist_add, color: Colors.orange), title: Text(T.get('load_demo')), onTap: () { widget.onLoadDemoData(); Navigator.pop(context); }),
                const Divider(),
                ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: Text(T.get('delete_all_data'), style: const TextStyle(color: Colors.red)), onTap: () => _confirmDelete(context)),
              ]),
              _buildSection(context, T.get('legal'), cardColor, [
                _buildTile(Icons.star_rate_rounded, T.get('rate_app'), false, () {}, iconColor: Colors.amber),
                _buildTile(Icons.privacy_tip_outlined, T.get('privacy_policy'), false, () async { final Uri url = Uri.parse("https://chris61ds-alt.github.io/Juzy-Legal/"); if (!await launchUrl(url)) debugPrint('Could not launch privacy'); }),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Color cardColor, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 12, bottom: 8, top: 10), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0))),
      Container(decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(children: children)),
      const SizedBox(height: 15),
    ]);
  }

  Widget _buildTile(IconData icon, String title, bool isSelected, VoidCallback onTap, {Color? iconColor}) {
    return ListTile(leading: Icon(icon, color: iconColor), title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF6BB8A7)) : null, onTap: onTap);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(T.get('delete_confirm_title')),
      content: Text(T.get('delete_confirm_msg')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () { widget.onDeleteAllData(); Navigator.pop(ctx); Navigator.pop(context); }, child: Text(T.get('delete')))
      ],
    ));
  }
}