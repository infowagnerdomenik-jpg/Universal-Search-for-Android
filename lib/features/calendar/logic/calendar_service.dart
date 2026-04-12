import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:search/features/search/logic/search_settings_controller.dart';

class NativeEvent {
  final String id;
  final String? title;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final String? location;
  final bool allDay;
  final String calendarId;
  final int? color;

  NativeEvent({
    required this.id,
    this.title,
    this.description,
    this.start,
    this.end,
    this.location,
    required this.allDay,
    required this.calendarId,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          start == other.start &&
          end == other.end &&
          location == other.location &&
          allDay == other.allDay &&
          calendarId == other.calendarId &&
          color == other.color;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      start.hashCode ^
      end.hashCode ^
      location.hashCode ^
      allDay.hashCode ^
      calendarId.hashCode ^
      color.hashCode;

  factory NativeEvent.fromMap(Map<dynamic, dynamic> map) {
    return NativeEvent(
      id: map['id']?.toString() ?? '',
      title: map['title'],
      description: map['description'],
      start: map['start'] != null ? DateTime.fromMillisecondsSinceEpoch(map['start']) : null,
      end: map['end'] != null ? DateTime.fromMillisecondsSinceEpoch(map['end']) : null,
      location: map['location'],
      allDay: map['allDay'] ?? false,
      calendarId: map['calendarId']?.toString() ?? '',
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start': start?.millisecondsSinceEpoch,
      'end': end?.millisecondsSinceEpoch,
      'location': location,
      'allDay': allDay,
      'calendarId': calendarId,
      'color': color,
    };
  }
}

class NativeCalendar {
  final String id;
  final String name;
  final String account;

  NativeCalendar({required this.id, required this.name, required this.account});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeCalendar &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          account == other.account;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ account.hashCode;

  factory NativeCalendar.fromMap(Map<dynamic, dynamic> map) {
    return NativeCalendar(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Unbenannt',
      account: map['account'] ?? '',
    );
  }
}

class CalendarService {
  static const _channel = MethodChannel('de.search.dw.search/calendar');

  static Future<bool> requestPermissions() async {
    try {
      final bool? isGranted = await _channel.invokeMethod('requestPermission');
      return isGranted ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      final bool? isGranted = await _channel.invokeMethod('checkPermission');
      return isGranted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Holt alle Daten auf einmal (Nativ)
  static Future<Map<String, dynamic>> getRawData() async {
    if (!await checkPermission()) return {'calendars': [], 'events': []};
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getFullCalendarData');
      return result?.cast<String, dynamic>() ?? {'calendars': [], 'events': []};
    } catch (e) {
      debugPrint("Nativer Kalenderfehler (getRawData): $e");
      return {'calendars': [], 'events': []};
    }
  }

  static Future<void> openEvent(String eventId, {DateTime? start, DateTime? end}) async {
    try {
      await _channel.invokeMethod('openEvent', {
        'eventId': eventId,
        'start': start?.millisecondsSinceEpoch,
        'end': end?.millisecondsSinceEpoch,
      });
    } catch (e) {}
  }
}
