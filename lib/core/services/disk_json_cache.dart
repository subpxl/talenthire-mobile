import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Reads/writes a single JSON object under the app documents directory.
class DiskJsonCache {
  const DiskJsonCache(this.fileName);

  final String fileName;

  Future<File?> _file() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File(p.join(dir.path, fileName));
    } catch (error) {
      debugPrint('Disk cache path unavailable ($fileName): $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> readPayload() async {
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      debugPrint('Disk cache read failed ($fileName): $error');
      return null;
    }
  }

  Future<void> writePayload(Map<String, dynamic> payload) async {
    try {
      final file = await _file();
      if (file == null) return;
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (error) {
      debugPrint('Disk cache write failed ($fileName): $error');
    }
  }

  Future<void> delete() async {
    try {
      final file = await _file();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Disk cache delete failed ($fileName): $error');
    }
  }
}
