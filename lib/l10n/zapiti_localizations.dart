import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum ZapitiLanguage {
  es('es', 'Español'),
  pt('pt', 'Português'),
  en('en', 'English'),
  fr('fr', 'Français');

  final String code;
  final String nativeName;

  const ZapitiLanguage(this.code, this.nativeName);

  static ZapitiLanguage fromCode(String? code) {
    return ZapitiLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => ZapitiLanguage.es,
    );
  }
}

class ZapitiI18n {
  ZapitiI18n._();

  static Map<ZapitiLanguage, Map<String, String>> _values = const {};

  static Future<void> load() async {
    final loaded = <ZapitiLanguage, Map<String, String>>{};
    for (final language in ZapitiLanguage.values) {
      final raw = await rootBundle.loadString(
        'assets/i18n/${language.code}.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      loaded[language] = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }
    _values = loaded;
  }

  static String text(
    ZapitiLanguage language,
    String key, {
    Map<String, Object?> params = const {},
  }) {
    var value =
        _values[language]?[key] ?? _values[ZapitiLanguage.es]?[key] ?? key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return value;
  }
}

class ZapitiLocalizations extends InheritedWidget {
  final ZapitiLanguage language;

  const ZapitiLocalizations({
    super.key,
    required this.language,
    required super.child,
  });

  static ZapitiLocalizations? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ZapitiLocalizations>();
  }

  static ZapitiLocalizations of(BuildContext context) {
    return maybeOf(context) ??
        const ZapitiLocalizations(
          language: ZapitiLanguage.es,
          child: SizedBox.shrink(),
        );
  }

  String text(String key, {Map<String, Object?> params = const {}}) {
    return ZapitiI18n.text(language, key, params: params);
  }

  @override
  bool updateShouldNotify(ZapitiLocalizations oldWidget) {
    return oldWidget.language != language;
  }
}

extension ZapitiLocalizationContext on BuildContext {
  String tr(String key, {Map<String, Object?> params = const {}}) {
    return ZapitiLocalizations.of(this).text(key, params: params);
  }
}
