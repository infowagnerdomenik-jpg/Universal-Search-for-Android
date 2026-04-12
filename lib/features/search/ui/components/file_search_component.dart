import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- NEUE DESIGN ENGINE IMPORTE ---
import 'package:design_engine/layer4_ui/design_engine_ui.dart';

import 'package:search/features/search/domain/models/cached_file.dart';
import 'package:search/features/search/logic/file_service.dart';
import 'package:search/features/search/logic/file_cache.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';
import 'package:search/features/search/logic/search_status_controller.dart';
import 'package:search/l10n/app_localizations.dart';

class FileSearchComponent extends StatefulWidget {
  final String query;

  const FileSearchComponent({super.key, required this.query});

  @override
  State<FileSearchComponent> createState() => _FileSearchComponentState();
}

class _FileSearchComponentState extends State<FileSearchComponent> with AutomaticKeepAliveClientMixin {
  static final Map<String, Uint8List?> _thumbCache = {};
  Timer? _debounce;
  List<CachedFile> _files = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(FileSearchComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = widget.query.toLowerCase().trim();
      if (q.length < 2) {
        if (mounted) setState(() => _files = []);
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      final results = await FileService.searchFiles(q);

      // KORREKTUR: Der Getter heißt fileWidgetLimit
      final limit = SearchSettingsController().fileWidgetLimit;

      if (mounted) {
        setState(() {
          _files = results.take(limit).toList();
          _isLoading = false;
        });
        SearchStatusController().reportResults('files', _files.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_files.isEmpty && !_isLoading) return const SizedBox.shrink();

    final Color esv = context.esurfacevariant;
    final Color eonbg = context.eonbackground;
    final l10n = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: esv,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('files_title'),
              style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
              else
                Column(
                  children: List.generate(_files.length, (index) {
                    final file = _files[index];
                    return Column(
                      children: [
                        _buildFileItem(file, eonbg),
                        if (index < _files.length - 1)
                          Divider(color: eonbg.withOpacity(0.05), height: 1, thickness: 1),
                      ],
                    );
                  }),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(CachedFile file, Color eonbg) {
    return InkWell(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await FileCache.addRecent(file);
        FileService.openFile(file.path);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            _buildThumbnail(file),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(color: eonbg, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.path,
                    style: TextStyle(color: eonbg.withOpacity(0.5), fontSize: 10),
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

  Widget _buildThumbnail(CachedFile file) {
    if (_thumbCache.containsKey(file.path)) {
      final data = _thumbCache[file.path];
      if (data != null) {
        return _wrapInContainer(file, file.isSvg ? Padding(padding: const EdgeInsets.all(8.0), child: SvgPicture.memory(data)) : Image.memory(data, fit: BoxFit.cover));
      }
      return _wrapInContainer(file, _buildDefaultIcon(file));
    }

    return FutureBuilder<Uint8List?>(
      future: FileService.getThumbnail(file.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _thumbCache[file.path] = snapshot.data;
          if (snapshot.hasData && snapshot.data != null) {
            return _wrapInContainer(file, file.isSvg ? Padding(padding: const EdgeInsets.all(8.0), child: SvgPicture.memory(snapshot.data!)) : Image.memory(snapshot.data!, fit: BoxFit.cover));
          }
        }
        return _wrapInContainer(file, _buildDefaultIcon(file));
      },
    );
  }

  Widget _wrapInContainer(CachedFile file, Widget child) {
    final Color svgBgColor = Colors.grey.withOpacity(0.2);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: file.isSvg ? svgBgColor : context.esurface,
        shape: BoxShape.circle
      ),
      clipBehavior: Clip.antiAlias,
      child: child
    );
  }

  Widget _buildDefaultIcon(CachedFile file) {
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
