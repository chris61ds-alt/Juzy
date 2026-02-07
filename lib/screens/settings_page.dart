import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import '../utils/translations.dart';

class SettingsPage extends StatelessWidget {
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final VoidCallback onDeleteAllData;
  final VoidCallback onLoadDemoData; 
  final String currentTheme;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.onDeleteAllData,
    required this.onLanguageChanged,
    required this.onLoadDemoData, 
  });

  // Links
  final String _privacyUrl = "https://chris61ds-alt.github.io/Juzy-Legal/";
  final String _supportEmail = "Chris61ds@gmail.com";

  Future<void> _launchPrivacy() async {
    final Uri url = Uri.parse(_privacyUrl);
    if (!await launchUrl(url)) {
      debugPrint("Could not launch $_privacyUrl");
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent(T.get('contact_subject'))}',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch email';
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email App not found: $_supportEmail")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRetro = currentTheme == 'retro';
    final colorScheme = Theme.of(context).colorScheme;
    
    final retroBg = const Color(0xFFF9F3E6);
    final retroText = const Color(0xFF3A2817);
    final retroAccent = const Color(0xFF6BB8A7);
    final retroCardBg = Colors.white;

    final bgColor = isRetro ? retroBg : colorScheme.surface;
    final textColor = isRetro ? retroText : colorScheme.onSurface;
    final cardColor = isRetro ? retroCardBg : colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          T.get('settings_title'), 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: textColor,
            letterSpacing: isRetro ? 1.5 : 0
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(T.get('appearance'), textColor),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: isRetro ? Border.all(color: retroAccent, width: 2) : null,
              boxShadow: isRetro ? [const BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4))] : null,
            ),
            child: Column(
              children: [
                _buildThemeOption(context, 'system', T.get('theme_system'), Icons.smartphone), 
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                _buildThemeOption(context, 'retro', T.get('theme_retro'), Icons.history_edu),
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                _buildThemeOption(context, 'light', T.get('theme_light'), Icons.wb_sunny_outlined),
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                _buildThemeOption(context, 'dark', T.get('theme_dark'), Icons.nightlight_round),
              ],
            ),
          ),

          const SizedBox(height: 30),

          _buildSectionHeader(T.get('language'), textColor),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: isRetro ? Border.all(color: retroAccent, width: 2) : null,
              boxShadow: isRetro ? [const BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4))] : null,
            ),
            child: Column(
              children: [
                _buildLangOption(context, 'en', 'English 🇺🇸'),
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                _buildLangOption(context, 'de', 'Deutsch 🇩🇪'),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          _buildSectionHeader(T.get('legal'), textColor), 
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: isRetro ? Border.all(color: retroAccent, width: 2) : null,
              boxShadow: isRetro ? [const BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4))] : null,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.policy, color: textColor),
                  title: Text(T.get('privacy_policy'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  onTap: _launchPrivacy,
                  trailing: Icon(Icons.open_in_new, size: 16, color: textColor.withOpacity(0.5)),
                ),
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                ListTile(
                  leading: Icon(Icons.mail, color: textColor),
                  title: Text(T.get('send_feedback'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  onTap: () => _launchEmail(context),
                  trailing: Icon(Icons.open_in_new, size: 16, color: textColor.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          _buildSectionHeader(T.get('data_management'), textColor),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: isRetro ? Border.all(color: retroAccent, width: 2) : null,
              boxShadow: isRetro ? [const BoxShadow(color: Color(0xFFD4522A), offset: Offset(4, 4))] : null,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.download_rounded, color: Colors.blue),
                  ),
                  title: Text(T.get('load_demo'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onLoadDemoData(); 
                    // KEINE SNACKBAR MEHR
                    Navigator.pop(context); 
                  },
                ),
                
                Divider(height: 1, color: textColor.withOpacity(0.1)),
                
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  title: Text(T.get('delete_all_data'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 50),
          Center(
            child: Text(
              "JUZY v1.0.0+6\nDesigned by Vasco da Soda",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String key, String label, IconData icon) {
    final isSelected = currentTheme == key;
    final isRetro = currentTheme == 'retro'; 
    
    final textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    final activeColor = isRetro ? const Color(0xFFD4522A) : Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onThemeChanged(key);
      },
      leading: Icon(icon, color: isSelected ? activeColor : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      trailing: isSelected ? Icon(Icons.check_circle, color: activeColor) : null,
    );
  }

  Widget _buildLangOption(BuildContext context, String code, String label) {
    final isSelected = T.code == code;
    final isRetro = currentTheme == 'retro';
    final textColor = isRetro ? const Color(0xFF3A2817) : Theme.of(context).colorScheme.onSurface;
    final activeColor = isRetro ? const Color(0xFFD4522A) : Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onLanguageChanged(code);
      },
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      trailing: isSelected ? Icon(Icons.check_circle, color: activeColor) : null,
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(T.get('delete_confirm_title')),
        content: Text(T.get('delete_confirm_msg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(T.get('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              onDeleteAllData();
              Navigator.pop(ctx);
            },
            child: Text(T.get('delete')),
          )
        ],
      ),
    );
  }
}