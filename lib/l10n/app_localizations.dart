import 'package:flutter/material.dart';

import 'languages/lang_en.dart';
import 'languages/lang_de.dart';
import 'languages/lang_es_AI.dart';
import 'languages/lang_fr_AI.dart';
import 'languages/lang_it_AI.dart';
import 'languages/lang_pt_AI.dart';
import 'languages/lang_nl_AI.dart';
import 'languages/lang_pl_AI.dart';
import 'languages/lang_ru_AI.dart';
import 'languages/lang_ja_AI.dart';
import 'languages/lang_zh_AI.dart';
import 'languages/lang_ko_AI.dart';
import 'languages/lang_ar_AI.dart';
import 'languages/lang_tr_AI.dart';
import 'languages/lang_hi_AI.dart';
import 'languages/lang_sv_AI.dart';
import 'languages/lang_da_AI.dart';
import 'languages/lang_fi_AI.dart';
import 'languages/lang_cs_AI.dart';
import 'languages/lang_uk_AI.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': langEn,
    'de': langDe,
    'es': langEs,
    'fr': langFr,
    'it': langIt,
    'pt': langPt,
    'nl': langNl,
    'pl': langPl,
    'ru': langRu,
    'ja': langJa,
    'zh': langZh,
    'ko': langKo,
    'ar': langAr,
    'tr': langTr,
    'hi': langHi,
    'sv': langSv,
    'da': langDa,
    'fi': langFi,
    'cs': langCs,
    'uk': langUk,
  };

  /// Returns all supported language codes.
  static List<String> get supportedLanguageCodes =>
      _localizedValues.keys.toList();

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
