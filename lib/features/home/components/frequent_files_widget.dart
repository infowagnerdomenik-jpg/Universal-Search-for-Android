import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/search/domain/models/cached_file.dart';
import 'package:search/features/search/logic/file_cache.dart';
import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/l10n/app_localizations.dart';

class FrequentFilesWidget extends StatefulWidget {
  const FrequentFilesWidget({super.key});

  @override
  State<FrequentFilesWidget> createState() => _FrequentFilesWidgetState();
}

class _FrequentFilesWidgetState extends State<FrequentFilesWidget> {
  late Future<List<bool>> _enabledFuture;
  final Map<String, Future<Uint8List?>> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _enabledFuture = Future.wait([FileService.isEnabled(), FileService.hasPermission()]);
  }

  @override
  Widget build(BuildContext context) {
    // --- DESIGN ENGINE FARBEN ---
    final Color esv = context.esurfacevariant;
    final Color eonsv = context.eonsurfacevariant;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context);

    return FutureBuilder<List<bool>>(
      future: _enabledFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data![0] == false || snapshot.data![1] == false) {
          return const SizedBox.shrink();
        }

        return ListenableBuilder(
          listenable: SearchSettingsController(),
          builder: (context, child) {
            final int limit = SearchSettingsController().fileWidgetLimit;

            return ValueListenableBuilder<List<CachedFile>>(
              valueListenable: FileCache.recentFilesNotifier,
              builder: (context, recentFiles, child) {
                if (recentFiles.isEmpty) return const SizedBox.shrink();

                final filesToShow = recentFiles.take(limit).toList();

                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('frequent_files_title'),
                          style: TextStyle(
                            color: eonsv,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: List.generate(filesToShow.length, (index) {
                              final file = filesToShow[index];
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  key: ValueKey(file.path),
                                  children: [
                                    _buildFileItem(context, file, eonsv),
                                    if (index < filesToShow.length - 1)
                                      Divider(color: eonsv.withOpacity(0.05), height: 1, thickness: 1),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFileItem(BuildContext context, CachedFile file, Color eonsv) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pathColor = isDark ? eonsv.withOpacity(0.5) : eonsv.withOpacity(0.6);

    return InkWell(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await FileCache.addRecent(file);
        await FileService.openFile(file.path);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            _buildThumbnail(context, file),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(color: eonsv, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.path,
                    style: TextStyle(color: pathColor, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, CachedFile file) {
    final Color esurface = context.esurface;
    final Color svgBgColor = Colors.grey.withOpacity(0.2);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: file.isSvg ? svgBgColor : esurface,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List?>(
        future: _thumbnailCache.putIfAbsent(file.path, () => FileService.getThumbnail(file.path)),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            if (file.isSvg) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.memory(snapshot.data!),
              );
            }
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return _buildDefaultIcon(context, file);
        },
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context, CachedFile file) {
    final String ext = file.name.split('.').last.toLowerCase();
    IconData iconData;

    switch (ext) {
      case 'pdf': iconData = Icons.picture_as_pdf; break;
      case 'zip':
      case 'rar':
      case '7z': iconData = Icons.folder_zip; break;
      case 'apk': iconData = Icons.android; break;
      case 'doc':
      case 'docx':
      case 'txt': iconData = Icons.description; break;
      case 'xls':
      case 'xlsx':
      case 'csv': iconData = Icons.table_chart; break;
      case 'mp4':
      case 'webm':
      case 'mkv':
      case 'avi': iconData = Icons.play_circle_outline; break;
      default: iconData = Icons.insert_drive_file;
    }

    return AppFallbackIcon(icon: iconData, size: 44, iconSize: 22);
  }
}
