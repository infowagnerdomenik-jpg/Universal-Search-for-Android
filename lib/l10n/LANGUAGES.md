# Language Registry

This file documents the status of all translations in this project.

## Status Legend

| Badge | Meaning |
|-------|---------|
| ✅ Human | Reviewed and validated by a native speaker |
| 🤖 AI | Machine-translated (Claude AI). May contain errors. Native speaker contributions welcome! |

## Supported Languages

| Code | Language | File | Status |
|------|----------|------|--------|
| `en` | English | `lang_en.dart` | ✅ Human |
| `de` | Deutsch (German) | `lang_de.dart` | ✅ Human |
| `es` | Español (Spanish) | `lang_es_AI.dart` | 🤖 AI |
| `fr` | Français (French) | `lang_fr_AI.dart` | 🤖 AI |
| `it` | Italiano (Italian) | `lang_it_AI.dart` | 🤖 AI |
| `pt` | Português (Portuguese) | `lang_pt_AI.dart` | 🤖 AI |
| `nl` | Nederlands (Dutch) | `lang_nl_AI.dart` | 🤖 AI |
| `pl` | Polski (Polish) | `lang_pl_AI.dart` | 🤖 AI |
| `ru` | Русский (Russian) | `lang_ru_AI.dart` | 🤖 AI |
| `ja` | 日本語 (Japanese) | `lang_ja_AI.dart` | 🤖 AI |
| `zh` | 中文 (Chinese) | `lang_zh_AI.dart` | 🤖 AI |
| `ko` | 한국어 (Korean) | `lang_ko_AI.dart` | 🤖 AI |
| `ar` | العربية (Arabic) | `lang_ar_AI.dart` | 🤖 AI |
| `tr` | Türkçe (Turkish) | `lang_tr_AI.dart` | 🤖 AI |
| `hi` | हिन्दी (Hindi) | `lang_hi_AI.dart` | 🤖 AI |
| `sv` | Svenska (Swedish) | `lang_sv_AI.dart` | 🤖 AI |
| `da` | Dansk (Danish) | `lang_da_AI.dart` | 🤖 AI |
| `fi` | Suomi (Finnish) | `lang_fi_AI.dart` | 🤖 AI |
| `cs` | Čeština (Czech) | `lang_cs_AI.dart` | 🤖 AI |
| `uk` | Українська (Ukrainian) | `lang_uk_AI.dart` | 🤖 AI |

## Contributing a Translation

If you are a native speaker and would like to review or improve an AI translation:

1. Open the relevant `lang_XX_AI.dart` file
2. Fix any errors or unnatural phrasing
3. Submit a pull request
4. Once reviewed, the file will be renamed to `lang_XX.dart` (without the `_AI` suffix) and marked as ✅ Human in this registry

## Adding a New Language

1. Create `lib/l10n/languages/lang_XX_AI.dart` using `lang_en.dart` as a template
2. Add the import and map entry to `lib/l10n/app_localizations.dart`
3. Add the language's native name to `_languageNames` in `lib/features/settings/ui/language_settings_screen.dart`
4. Add an entry to this registry
