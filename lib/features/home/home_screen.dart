import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

// --- FEATURE IMPORTE ---
import 'package:search/main.dart'; // Für routeObserver
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/suggestion_service.dart';
import 'package:search/features/search/logic/app_cache.dart';
import 'package:search/features/search/logic/contact_cache.dart';
import 'package:search/features/calendar/logic/calendar_cache.dart';
import 'package:search/features/search/logic/file_cache.dart';
import 'package:search/features/search/ui/components/suggestion_list.dart';
import 'package:search/features/search/ui/components/app_search_component.dart';
import 'package:search/features/search/ui/components/contact_search_component.dart';
import 'package:search/features/search/ui/components/file_search_component.dart';
import 'package:search/features/calendar/ui/components/calendar_search_component.dart';
import 'package:search/features/search/ui/components/shortcut_search_component.dart';
import 'package:search/features/search/ui/search_bar_visual.dart';
import 'package:search/features/home/components/frequent_apps_widget.dart';
import 'package:search/features/home/components/frequent_contacts_widget.dart';
import 'package:search/features/home/components/frequent_files_widget.dart';
import 'package:search/features/calendar/ui/components/frequent_calendar_widget.dart';
import 'package:search/features/settings/ui/settings_screen.dart';
import 'package:search/features/home/components/floating_keyboard_button.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/settings/logic/home_layout_controller.dart';
import 'package:search/features/settings/logic/update_controller.dart';
import 'package:search/features/search/logic/quick_search_controller.dart';
import 'package:search/features/search/domain/models/quick_search_provider.dart';
import 'package:search/l10n/app_localizations.dart';

import 'package:search/features/search/logic/search_status_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, RouteAware {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  Timer? _debounce;

  final ValueNotifier<List<String>> _suggestionsNotifier = ValueNotifier([]);
  bool _isTopRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _textController = TextEditingController();
    _focusNode = FocusNode();

    _textController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Beim ersten Start registrieren
      routeObserver.subscribe(this, ModalRoute.of(context)!);
      _isTopRoute = true;
      _forceKeyboard(isAppStart: true);
      CalendarCache.refresh();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _suggestionsNotifier.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- ROUTE AWARE LOGIK ---
  @override
  void didPushNext() {
    _isTopRoute = false;
    _focusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void didPopNext() {
    _isTopRoute = true;
    _forceKeyboard(isAppStart: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTopRoute) {
      _forceKeyboard(isAppStart: false);
    }
  }

  void _forceKeyboard({required bool isAppStart}) {
    final layout = HomeLayoutController();
    
    if (isAppStart) {
      if (!layout.keyboardOnStart) return;
    } else {
      if (!layout.keyboardAuto) return;
    }

    final delays = [100, 300, 600];
    
    for (final ms in delays) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted && _isTopRoute) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final text = _textController.text;
      if (text.isEmpty) {
        if (_suggestionsNotifier.value.isNotEmpty) {
          _suggestionsNotifier.value = [];
        }
        return;
      }

      SearchStatusController().startNewSearch();

      final searchSettings = SearchSettingsController();
      if (!searchSettings.isVisible('text_results')) {
        if (_suggestionsNotifier.value.isNotEmpty) {
          _suggestionsNotifier.value = [];
        }
        SearchStatusController().reportResults('text_results', 0);
        Future.delayed(const Duration(milliseconds: 200), () {
          SearchStatusController().finishSearch();
        });
        return;
      }

      final engine = searchSettings.activeEngine;
      final results = await SuggestionService.fetchSuggestions(text, engine.type);
      if (mounted) {
        final limitedResults = results.take(5).toList();
        _suggestionsNotifier.value = limitedResults;
        SearchStatusController().reportResults('text_results', limitedResults.length);

        Future.delayed(const Duration(milliseconds: 200), () {
          SearchStatusController().finishSearch();
        });
      }
    });
  }

  void _onSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;
    _suggestionsNotifier.value = [];
    _focusNode.unfocus();
    final engine = SearchSettingsController().activeEngine;
    final encodedQuery = Uri.encodeComponent(query);
    final urlString = engine.searchUrl.replaceAll('{q}', encodedQuery);
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Fehler beim Öffnen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- DESIGN ENGINE FARBEN ---
    final Color ebg = context.ebackground;     // ehemals cf1
    final Color esv = context.esurfacevariant; // ehemals cf2
    final Color eonbg = context.eonbackground; // ehemals txt1

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ebg,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingKeyboardButton(
        onPressed: () {
          if (_focusNode.hasFocus) {
            SystemChannels.textInput.invokeMethod('TextInput.show');
          } else {
            _focusNode.requestFocus();
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final double dragVelocity = notification.scrollDelta ?? 0;
              if (dragVelocity > 5 && _focusNode.hasFocus) {
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              }
            }

            if (notification is OverscrollNotification) {
              if (notification.metrics.pixels <= 0 && notification.overscroll < -5) {
                if (HomeLayoutController().keyboardAuto && _isTopRoute) {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  }
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                }
              }

              if (notification.overscroll > 5 && _focusNode.hasFocus) {
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              }
            }
            return true;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 110),
            children: [
              SearchBarVisual(
                controller: _textController,
                focusNode: _focusNode,
                onSearch: _performSearch,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  children: [
                    // EBENE 1: SCROLL-BEREICH (Schnellsuchen)
                    ListenableBuilder(
                      listenable: QuickSearchController(),
                      builder: (context, child) {
                        final quickController = QuickSearchController();
                        final searchSettings = SearchSettingsController();
                        final activeEngine = searchSettings.activeEngine;

                        // Filter & Order
                        final filteredProviders = quickController.providerOrder.map((id) {
                          return QuickSearchProvider.all.firstWhere((p) => p.id == id);
                        }).where((p) {
                          return quickController.isEnabled(p.id) && p.id != activeEngine.id;
                        }).toList();

                        return Container(
                          height: 60,
                          alignment: Alignment.centerLeft,
                          child: ClipRect(
                            clipper: _EdgeClipper(
                              rightClip: 76.0,
                              leftExtend: MediaQuery.of(context).size.width <= 600 ? 16.0 : 0.0,
                            ),
                            child: SingleChildScrollView(
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(0, 6, 110, 6), 
                              child: Row(
                                children: filteredProviders.map((provider) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () async {
                                        HapticFeedback.lightImpact();
                                        final query = _textController.text.trim();

                                        String urlString;
                                        if (query.isEmpty) {
                                          urlString = provider.homeUrl;
                                        } else {
                                          final encodedQuery = Uri.encodeComponent(query);
                                          urlString = provider.searchUrl.replaceAll('{q}', encodedQuery);
                                        }
                                        
                                        final uri = Uri.parse(urlString);

                                        try {
                                          await launchUrl(
                                            uri,
                                            mode: quickController.openInApp 
                                                ? LaunchMode.externalApplication 
                                                : LaunchMode.platformDefault,
                                          );
                                        } catch (e) {
                                          debugPrint("Fehler beim Öffnen der Schnellsuchen: $e");
                                        }
                                      },
                                      child: provider.id == 'chatgpt'
                                          ? Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(color: eonbg, shape: BoxShape.circle),
                                              padding: const EdgeInsets.all(3.5),
                                              child: SvgPicture.asset(
                                                provider.assetIcon,
                                                colorFilter: ColorFilter.mode(ebg, BlendMode.srcIn), // ebg Inverse Contrast
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: provider.id == 'amazon' ? Colors.white : esv,
                                                shape: BoxShape.circle,
                                                boxShadow: isDark ? [] : [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.08),
                                                    blurRadius: 8,
                                                    spreadRadius: -3,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(
                                                provider.id == 'youtube' ? 8 : 
                                                (provider.id == 'maps' || provider.id == 'osm') ? 9 : 7
                                              ),
                                              child: SvgPicture.asset(
                                                provider.assetIcon,
                                                colorFilter: provider.id == 'spotify' 
                                                    ? const ColorFilter.mode(Color(0xFF1ED760), BlendMode.srcIn)
                                                    : null,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // EBENE 2: DER TUNNEL
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: const Alignment(0.6, 0),
                            colors: [
                              ebg.withOpacity(0),
                              ebg,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                final input = _textController.text.trim();
                                if (input.isNotEmpty) {
                                  String urlString = input;
                                  if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                    urlString = 'https://$urlString';
                                  }
                                  try {
                                    await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    debugPrint("Fehler beim direkten Öffnen des Links: $e");
                                  }
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: esv,
                                  shape: BoxShape.circle,
                                  boxShadow: isDark ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      spreadRadius: -3,
                                      offset: const Offset(-3, 0),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                  'assets/icons/dynamic/link_2_48dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg',
                                  colorFilter: ColorFilter.mode(eonbg, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                              },
                              child: ListenableBuilder(
                                listenable: UpdateController(),
                                builder: (context, child) {
                                  final isUpdate = UpdateController().isUpdateAvailable;
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: esv,
                                      shape: BoxShape.circle,
                                      boxShadow: isDark ? [] : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          spreadRadius: -3,
                                          offset: const Offset(-3, 0),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(Icons.settings_outlined, color: eonbg, size: 24),
                                        if (isUpdate)
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: context.eprimary,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: esv, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ListenableBuilder(
                listenable: Listenable.merge([SearchSettingsController(), _textController, _suggestionsNotifier]),
                builder: (context, child) {
                  final searchSettings = SearchSettingsController();
                  final query = _textController.text;
                  final suggestions = _suggestionsNotifier.value;
                  return Column(
                    children: searchSettings.searchOrder.map((id) {
                      if (!searchSettings.isVisible(id)) return const SizedBox.shrink();

                      if (id == 'calendar' && query.trim().isNotEmpty) {
                        return CalendarSearchComponent(key: const ValueKey('search_calendar'), query: query);
                      }
                      if (id == 'shortcuts' && query.trim().isNotEmpty) {
                        return ShortcutSearchComponent(key: const ValueKey('search_shortcuts'), query: query);
                      }
                      if (id == 'apps' && query.trim().isNotEmpty) {
                        return AppSearchComponent(key: const ValueKey('search_apps'), query: query);
                      }
                      if (id == 'contacts' && query.trim().isNotEmpty) {
                        return ContactSearchComponent(key: const ValueKey('search_contacts'), query: query);
                      }
                      if (id == 'files' && query.trim().isNotEmpty) {
                        return FileSearchComponent(key: const ValueKey('search_files'), query: query);
                      }
                      if (id == 'text_results' && suggestions.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SuggestionList(
                            suggestions: suggestions,
                            onSelected: _onSuggestionSelected,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  );
                },
              ),

              ListenableBuilder(
                listenable: Listenable.merge([SearchStatusController(), _textController]),
                builder: (context, child) {
                  final status = SearchStatusController();
                  if (_textController.text.trim().isNotEmpty &&
                      !status.isSearching &&
                      status.totalResults == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: esv,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          AppLocalizations.of(context).get('nothing_found'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              ListenableBuilder(
                listenable: _textController,
                builder: (context, child) {
                  if (_textController.text.trim().isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
                    height: 4,
                    decoration: BoxDecoration(
                      color: esv,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),

              ListenableBuilder(
                listenable: HomeLayoutController(),
                builder: (context, child) {
                  final controller = HomeLayoutController();
                  return Column(
                    children: controller.widgetOrder.map((id) {
                      if (!controller.isVisible(id)) return const SizedBox.shrink();
                      
                      if (id == 'calendar') return const FrequentCalendarWidget();
                      if (id == 'apps') return const FrequentAppsWidget();
                      if (id == 'contacts') return const FrequentContactsWidget();
                      if (id == 'files') return const FrequentFilesWidget();
                      return const SizedBox.shrink();
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgeClipper extends CustomClipper<Rect> {
  final double rightClip;
  final double leftExtend;
  _EdgeClipper({this.leftExtend = 0, required this.rightClip});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(-leftExtend, 0, size.width + leftExtend - rightClip, size.height);
  }

  @override
  bool shouldReclip(_EdgeClipper old) =>
      old.rightClip != rightClip || old.leftExtend != leftExtend;
}
