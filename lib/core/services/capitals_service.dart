import 'dart:convert';
import 'package:flutter/services.dart';

class CapitalsService {
  static Map<String, (double, double)>? _cache;

  static Future<Map<String, (double, double)>> loadCoordinates() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/capitals.json');
    final List<dynamic> list = json.decode(raw);

    _cache = {};

    for (final item in list) {
      final capitalList = item['capital'] as List<dynamic>?;
      if (capitalList == null || capitalList.isEmpty) continue;
      final capitalName = (capitalList.first as String).toLowerCase();

      final latlag = item['latlng'] as List<dynamic>?;
      if (latlag == null || latlag.length < 2) continue;

      final lat = (latlag[0] as num).toDouble();
      final lng = (latlag[1] as num).toDouble();

      _cache![capitalName] = (lat, lng);
    }

    return _cache!;
  }
}
