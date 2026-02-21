import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class T {
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('en');
  static String get code => localeNotifier.value;

  // NEU: Globale Verwaltung der Währung
  static final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('€');
  static String get currency => currencyNotifier.value;

  static Future<void> init() async {
    var box = await Hive.openBox('settings');
    String? savedLang = box.get('language');
    if (savedLang != null) localeNotifier.value = savedLang;
    
    String? savedCurr = box.get('currency');
    if (savedCurr != null) currencyNotifier.value = savedCurr;
  }

  static Future<void> setLanguage(String lang) async {
    localeNotifier.value = lang;
    var box = await Hive.openBox('settings');
    await box.put('language', lang);
  }

  static Future<void> setCurrency(String curr) async {
    currencyNotifier.value = curr;
    var box = await Hive.openBox('settings');
    await box.put('currency', curr);
  }

  static final Map<String, Map<String, String>> _values = {
    'en': {
      'app_name': 'JUZY',
      'search': 'Search...',
      'new_item': 'New Entry',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'items': 'Items',
      'subs': 'Subs',
      'stats': 'Stats',
      'history': 'HISTORY',
      'settings_title': 'Settings',
      'appearance': 'Appearance',
      'language': 'Language',
      'currency': 'Currency',
      'data_management': 'Data Management',
      'legal': 'Legal',
      'group_rename': 'Rename Group',
      'new_name': 'New Name',
      
      // Dashboard & Tiles
      'daily_cost': 'DAILY BURN',
      'daily_cost_items': 'DAILY BURN (ITEMS)',
      'daily_cost_subs': 'DAILY BURN (SUBS)',
      'cost_per_use': 'Cost / Use',
      'usages': 'Usages',
      'bought_on': 'Bought on',
      'item_archived': 'Archived on',
      'times_used': 'times used',
      'view_usage': 'View Usage',
      'view_daily': 'View Daily',
      'goal': 'Goal',
      'per_usage': 'per use',
      'per_month': 'per month',
      
      // Buttons & Actions
      'consume_button': 'Archive Item',
      'restore': 'Restore Item',
      'cancel_sub_button': 'Archive Sub',
      'new_category': 'New Category',
      'delete_category_confirm': 'Delete this category?',
      
      // Periods
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'per_day': 'day',
      'per_week': 'week',
      'per_month': 'month',
      'per_year': 'year',
      'days': 'Days',
      'months': 'Months',
      'years': 'Years',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'times_per': 'times per',
      
      // Stats
      'stats_inventory': 'Inventory Value',
      'stats_yearly_subs': 'Yearly Subs Cost',
      'cost_dist': 'COST DISTRIBUTION',
      'lifespan_race': 'LONGEVITY RACE',
      'stats_best': 'Best Value',
      'stats_worst': 'Worst Value',
      'empty_stats': 'Add items for stats.',
      'empty_items': 'No items yet.',
      'empty_subs': 'No subscriptions.',
      
      // Detail Page & Timeline
      'verdict_excellent': 'Goal Reached!',
      'verdict_fail': 'Goal Missed',
      'verdict_sub_success': 'The cost per use is below your target.',
      'verdict_sub_fail': 'The cost per use is above your target.',
      'verdict_item_success': 'This item lasted longer than expected.',
      'verdict_item_fail': 'This item was archived earlier than planned.',
      'bought': 'Bought',
      'archived': 'Archived',
      'expected': 'Expected',
      'chart_history': 'Usage History',
      'last_used': 'Last used:',
      'never_used': 'Never used',
      'just_now': 'Just now',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'days_ago': 'Days ago',
      
      // Edit Page
      'step_identity': 'Identity',
      'step_usage': 'Usage',
      'step_forecast': 'Forecast',
      'next': 'Next',
      'label_category': 'Category',
      'label_name': 'Item Name',
      'label_price': 'Price',
      'label_date': 'Purchase Date',
      'type_purchase': 'One-time',
      'type_sub': 'Subscription',
      'pay_interval': 'Payment Interval',
      'sub_calc_info': 'We calculate the daily cost of your subscription based on this interval.',
      'tracking_method': 'Tracking Method',
      'tracking_estimation': 'Estimation',
      'tracking_manual': 'Manual',
      'manual_info': 'You will log every use manually via the + button.',
      'label_manual_usages': 'Current Usages',
      'estimation_info': 'We estimate usages based on the interval below.',
      'usage_approx': 'I use this approx.',
      'sub_goal_hint': 'How often do you plan to use this subscription?',
      'wish_lifespan': 'Expected Lifespan',
      'lifespan_hint': 'How long do you intend to keep this item?',
      'calc_date': 'Calculated end date:',
      'target_value': 'Target Cost',
      
      // Settings / Danger Zone
      'theme_retro': 'Retro Mode',
      'theme_dark': 'Dark Mode',
      'theme_light': 'Light Mode',
      'theme_system': 'System Default',
      'delete_all_data': 'Delete All Data',
      'delete_confirm_title': 'Delete everything?',
      'delete_confirm_msg': 'This action cannot be undone.',
      'rate_app': 'Rate App',
      'privacy_policy': 'Privacy Policy',
      'load_demo': 'Load Demo Data',
      
      // Onboarding
      'onboarding_welcome': 'Welcome to JUZY 🥭',
      'onboarding_desc': 'The real value of your things, tracked simply.',
      'onboarding_start': 'Get Started',
      'onboarding_legal': 'Privacy Policy',
      'choose_lang': 'Language',
      
      // Categories
      'cat_living': 'Living', 'cat_tech': 'Tech', 'cat_clothes': 'Clothes',
      'cat_transport': 'Transport', 'cat_food': 'Food', 'cat_insurance': 'Insurance',
      'cat_entertainment': 'Entertainment', 'cat_business': 'Business', 'cat_health': 'Health', 'cat_misc': 'Misc',
    },
    'de': {
      'app_name': 'JUZY',
      'search': 'Suche...',
      'new_item': 'Neuer Eintrag',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'items': 'Sachen',
      'subs': 'Abos',
      'stats': 'Statistik',
      'history': 'ARCHIV',
      'settings_title': 'Einstellungen',
      'appearance': 'Design',
      'language': 'Sprache',
      'currency': 'Währung',
      'data_management': 'Daten-Verwaltung',
      'legal': 'Rechtliches',
      'group_rename': 'Gruppe umbenennen',
      'new_name': 'Neuer Name',
      
      // Dashboard & Tiles
      'daily_cost': 'TAGES-KOSTEN',
      'daily_cost_items': 'TAGES-KOSTEN (ITEMS)',
      'daily_cost_subs': 'TAGES-KOSTEN (ABOS)',
      'cost_per_use': 'Kosten / Nutzung',
      'usages': 'Nutzungen',
      'bought_on': 'Gekauft am',
      'item_archived': 'Archiviert am',
      'times_used': 'mal genutzt',
      'view_usage': 'Nach Nutzung',
      'view_daily': 'Pro Tag',
      'goal': 'Ziel',
      'per_usage': 'pro Nutzung',
      'per_month': 'pro Monat',
      
      // Buttons & Actions
      'consume_button': 'Archivieren',
      'restore': 'Wiederherstellen',
      'cancel_sub_button': 'Abo archivieren',
      'new_category': 'Neue Kategorie',
      'delete_category_confirm': 'Diese Kategorie löschen?',
      
      // Periods
      'day': 'Tag',
      'week': 'Woche',
      'month': 'Monat',
      'year': 'Jahr',
      'per_day': 'Tag',
      'per_week': 'Woche',
      'per_month': 'Monat',
      'per_year': 'Jahr',
      'days': 'Tage',
      'months': 'Monate',
      'years': 'Jahre',
      'monthly': 'Monatlich',
      'yearly': 'Jährlich',
      'times_per': 'mal pro',
      
      // Stats
      'stats_inventory': 'Inventarwert',
      'stats_yearly_subs': 'Jährliche Abokosten',
      'cost_dist': 'KOSTENVERTEILUNG',
      'lifespan_race': 'HALTBARKEITS-RENNEN',
      'stats_best': 'Bester Wert',
      'stats_worst': 'Schlechtester Wert',
      'empty_stats': 'Füge Dinge hinzu.',
      'empty_items': 'Noch keine Einträge.',
      'empty_subs': 'Keine Abos.',
      
      // Detail Page & Timeline
      'verdict_excellent': 'Ziel erreicht!',
      'verdict_fail': 'Ziel verfehlt',
      'verdict_sub_success': 'Kosten pro Nutzung sind unter deinem Ziel.',
      'verdict_sub_fail': 'Kosten pro Nutzung liegen über deinem Ziel.',
      'verdict_item_success': 'Das Item hat länger gehalten als erwartet.',
      'verdict_item_fail': 'Das Item wurde früher als geplant aussortiert.',
      'bought': 'Kauf',
      'archived': 'Archiviert',
      'expected': 'Erwartet',
      'chart_history': 'Verlauf',
      'last_used': 'Zuletzt genutzt:',
      'never_used': 'Noch nie genutzt',
      'just_now': 'Gerade eben',
      'today': 'Heute',
      'yesterday': 'Gestern',
      'days_ago': 'Vor',
      
      // Edit Page
      'step_identity': 'Identität',
      'step_usage': 'Nutzung',
      'step_forecast': 'Prognose',
      'next': 'Weiter',
      'label_category': 'Kategorie',
      'label_name': 'Name des Eintrags',
      'label_price': 'Preis',
      'label_date': 'Kaufdatum',
      'type_purchase': 'Einmalig',
      'type_sub': 'Abonnement',
      'pay_interval': 'Zahlungsintervall',
      'sub_calc_info': 'Basierend hierauf berechnen wir die täglichen Kosten deines Abos.',
      'tracking_method': 'Tracking-Methode',
      'tracking_estimation': 'Schätzung',
      'tracking_manual': 'Manuell',
      'manual_info': 'Du trägst jede Nutzung manuell über den + Button ein.',
      'label_manual_usages': 'Aktuelle Nutzungen',
      'estimation_info': 'Wir schätzen die Nutzung basierend auf deinem Intervall unten.',
      'usage_approx': 'Ich nutze das ca.',
      'sub_goal_hint': 'Wie oft planst du, dieses Abo zu nutzen?',
      'wish_lifespan': 'Wunsch-Haltbarkeit',
      'lifespan_hint': 'Wie lange möchtest du das Item behalten?',
      'calc_date': 'Berechnetes Enddatum:',
      'target_value': 'Ziel-Kosten',
      
      // Settings / Danger Zone
      'theme_retro': 'Retro-Modus',
      'theme_dark': 'Dunkel-Modus',
      'theme_light': 'Heller Modus',
      'theme_system': 'System-Standard',
      'delete_all_data': 'Alle Daten löschen',
      'delete_confirm_title': 'Alles löschen?',
      'delete_confirm_msg': 'Diese Aktion kann nicht rückgängig gemacht werden.',
      'rate_app': 'App bewerten',
      'privacy_policy': 'Datenschutz',
      'load_demo': 'Demo-Daten laden',
      
      // Onboarding
      'onboarding_welcome': 'Willkommen bei JUZY 🥭',
      'onboarding_desc': 'Der wahre Wert deiner Dinge, einfach getrackt.',
      'onboarding_start': 'Loslegen',
      'onboarding_legal': 'Datenschutz',
      'choose_lang': 'Sprache wählen',
      
      // Categories
      'cat_living': 'Wohnen', 'cat_tech': 'Technik', 'cat_clothes': 'Kleidung',
      'cat_transport': 'Transport', 'cat_food': 'Essen', 'cat_insurance': 'Versicherung',
      'cat_entertainment': 'Unterhaltung', 'cat_business': 'Business', 'cat_health': 'Gesundheit', 'cat_misc': 'Sonstiges',
    }
  };

  static String get(String key) => _values[code]?[key] ?? key;
}