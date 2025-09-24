// lib/services/geo_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Подсказки городов через Nominatim (OSM).
/// Возвращает "Город, Регион, Страна" (display_name).
class GeoApi {
  GeoApi._();
  static final instance = GeoApi._();

  static const _base = 'nominatim.openstreetmap.org';
  static const _ua = 'idoapp/1.0 (support@ido.example)';

  Future<List<String>> suggestCities(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final uri = Uri.https(_base, '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '10',
      'accept-language': 'ru',
      'featuretype': 'city', // нам интересны именно населённые пункты
    });

    try {
      final r = await http.get(
        uri,
        headers: {'User-Agent': _ua, 'Accept': 'application/json'},
      );
      if (r.statusCode != 200) return [];

      final arr = (json.decode(r.body) as List).cast<Map<String, dynamic>>();
      final out = <String>[];

      for (final m in arr) {
        final cls = m['class'];
        final type = m['type'];
        final isCityLike = (cls == 'place') &&
            (type == 'city' || type == 'town' || type == 'village' || type == 'hamlet' || type == 'municipality' || type == 'locality');
        if (!isCityLike) continue;

        final display = (m['display_name'] as String?)?.trim();
        if (display != null && display.isNotEmpty) out.add(display);
      }

      final seen = <String>{};
      return out.where(seen.add).toList();
    } catch (_) {
      return [];
    }
  }
}
