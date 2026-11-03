import 'dart:convert';

import 'package:flutter/foundation.dart';

class ZapitiLogger {
  static const bool enabled = true;
  static const _tag = '[zapiti_app]';
  static const _sensitiveKeys = {
    'password',
    'sessionToken',
    'token',
    'authorization',
  };

  static void debug(
    String scope,
    String event, {
    Map<String, Object?>? fields,
  }) {
    _emit('DEBUG', scope, event, fields: fields);
  }

  static void info(
    String scope,
    String event, {
    Map<String, Object?>? fields,
  }) {
    _emit('INFO', scope, event, fields: fields);
  }

  static void warn(
    String scope,
    String event, {
    Map<String, Object?>? fields,
  }) {
    _emit('WARN', scope, event, fields: fields);
  }

  static void error(
    String scope,
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    _emit(
      'ERROR',
      scope,
      event,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    );
  }

  static void _emit(
    String level,
    String scope,
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) {
    if (!enabled) return;
    final sanitizedFields = _sanitizeMap(fields ?? const {});
    final buffer = StringBuffer()
      ..write(_tag)
      ..write(' ')
      ..write(level)
      ..write(' ')
      ..write(scope)
      ..write(' ')
      ..write(event);
    if (sanitizedFields.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(jsonEncode(sanitizedFields));
    }
    if (error != null) {
      buffer
        ..write(' error=')
        ..write(error);
    }
    if (stackTrace != null) {
      buffer
        ..write('\n')
        ..write(stackTrace);
    }
    debugPrint(buffer.toString());
  }

  static Map<String, Object?> _sanitizeMap(Map<Object?, Object?> input) {
    final sanitized = <String, Object?>{};
    for (final entry in input.entries) {
      final key = entry.key?.toString() ?? 'null';
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return sanitized;
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (_sensitiveKeys.contains(key)) {
      return _redact(value);
    }
    if (value is Map) {
      return _sanitizeMap(Map<Object?, Object?>.from(value));
    }
    if (value is Iterable) {
      return value
          .map((item) => _sanitizeValue(key, item))
          .toList(growable: false);
    }
    return value;
  }

  static String _redact(Object? value) {
    if (value == null) return '<redacted:null>';
    final text = value.toString();
    if (text.isEmpty) return '<redacted:empty>';
    return '<redacted:${text.length}>';
  }
}
