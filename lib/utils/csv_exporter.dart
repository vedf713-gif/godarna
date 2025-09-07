import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CsvExporter {
  static String toCsv(List<Map<String, dynamic>> rows, {List<String>? columns, Map<String, String>? headers}) {
    if (rows.isEmpty) return '';
    final cols = columns ?? rows.first.keys.map((e) => e.toString()).toList();
    final headerRow = cols.map((c) => _escape(headers?[c] ?? c)).join(',');
    final dataRows = rows.map((r) => cols.map((c) => _escape(_stringify(r[c]))).join(',')).join('\n');
    return '$headerRow\n$dataRows';
  }

  static Uint8List toBytes(List<Map<String, dynamic>> rows, {List<String>? columns, Map<String, String>? headers}) {
    final csv = toCsv(rows, columns: columns, headers: headers);
    return Uint8List.fromList(const Utf8Encoder().convert(csv));
  }

  static String _escape(String value) {
    final needsQuotes = value.contains(',') || value.contains('"') || value.contains('\n');
    var v = value.replaceAll('"', '""');
    return needsQuotes ? '"$v"' : v;
  }

  static String _stringify(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return jsonEncode(v);
  }
}
