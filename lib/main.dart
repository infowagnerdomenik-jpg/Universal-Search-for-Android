import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/app_cache.dart';
import 'package:search/features/search/logic/contact_cache.dart';
import 'package:search/features/search/logic/file_cache.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/features/search/logic/quick_search_controller.dart';
import 'package:search/features/settings/logic/home_layout_controller.dart';
import 'package:search/features/settings/logic/update_controller.dart';
import 'package:search/features/home/home_screen.dart';
import 'package:design_engine/layer3_logic/design_engine_controller.dart';
import 'package:search/l10n/app_localizations.dart';
import 'package:search/l10n/language_controller.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));

  final designEngineController = DesignEngineController();

  await Future.wait<void>([
    designEngineController.init(),
    SearchSettingsController().init(),
    HomeLayoutController().init(),
    QuickSearchController().init(),
    LanguageController().init(),
  ]);

  AppCache.init();
  ContactCache.init();
  CalendarCache.init();
  FileCache.init();

  UpdateController().checkUpdates();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: designEngineController),
        ChangeNotifierProvider.value(value: QuickSearchController()),
        ChangeNotifierProvider.value(value: LanguageController()),
        ChangeNotifierProvider.value(value: UpdateController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final designEngine = context.watch<DesignEngineController>();
    final langController = context.watch<LanguageController>();

    final Locale? locale = langController.language == 'auto'
        ? null
        : Locale(langController.language);

    return MaterialApp(
      title: 'Search',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLanguageCodes
          .map((code) => Locale(code))
          .toList(),
      locale: locale,
      themeMode: designEngine.themeMode,
      theme: designEngine.lightTheme,
      darkTheme: designEngine.darkTheme,
      home: const HomeScreen(),
    );
  }
}
