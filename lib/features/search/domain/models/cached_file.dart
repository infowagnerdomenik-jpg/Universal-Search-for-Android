class CachedFile {
  final String id;
  final String name;
  final String path;
  final String mimeType;
  final int size;
  final int dateModified;

  CachedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.dateModified,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          path == other.path &&
          mimeType == other.mimeType &&
          size == other.size &&
          dateModified == other.dateModified;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      path.hashCode ^
      mimeType.hashCode ^
      size.hashCode ^
      dateModified.hashCode;

  bool get isSvg => mimeType == 'image/svg+xml' || name.toLowerCase().endsWith('.svg');
  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');

  factory CachedFile.fromMap(Map<dynamic, dynamic> map) {
    return CachedFile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      mimeType: map['mimeType']?.toString() ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      dateModified: (map['dateModified'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'mimeType': mimeType,
      'size': size,
      'dateModified': dateModified,
    };
  }
}
