// lib/services/local_geocoder.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ido/services/keys.dart';               // <-- ключи
import 'package:ido/services/yandex_geocoder.dart';     // <-- новый файл

/// Геокодер: сначала Яндекс (если есть ключ), потом Nominatim (OSM).
class LocalGeocoder {
  LocalGeocoder._();
  static final instance = LocalGeocoder._();

  static const _base = 'nominatim.openstreetmap.org';
  static const _ua = 'idoapp/1.0 (support@ido.example)';

  // ---------- ПУБЛИЧНЫЕ МЕТОДЫ ----------

  Future<String?> reverse(double lat, double lon) async {
    // 1) Яндекс в приоритете
    if (hasMapkitKey) {
      try {
        final ya = await YandexGeocoder.instance.reversePretty(lat, lon);
        if (_has(ya)) return ya!.trim();
      } catch (e) {
        // молча падаем к OSM
        // print('YA reverse error: $e');
      }
    }

    // 2) OSM (fallback)
    final raw1 = await _nominatimReverseRaw(lat, lon);
    final addr1 = _composeCityStreetHouse(raw1?['address'] as Map<String, dynamic>?);
    if (_has(addr1)) return addr1!.trim();

    // Пробуем с zoom повыше
    final raw2 = await _nominatimReverseRaw(lat, lon, zoom: 18);
    final addr2 = _composeCityStreetHouse(raw2?['address'] as Map<String, dynamic>?);
    if (_has(addr2)) return addr2!.trim();

    // Последний шанс — display_name
    final dn = (raw2?['display_name'] ?? raw1?['display_name']) as String?;
    return _has(dn) ? dn!.trim() : null;
  }

  Future<List<Map<String, dynamic>>> search(String query, {int limit = 12}) async {
    // пока оставим поиск через OSM; при желании можно так же прикрутить YandexSearch.searchByText
    final q = query.trim();
    if (q.length < 2) return [];

    final uri = Uri.https(_base, '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      'accept-language': 'ru',
    });

    try {
      final r = await http.get(uri, headers: {'User-Agent': _ua, 'Accept': 'application/json'});
      if (r.statusCode != 200) return [];

      final arr = (json.decode(r.body) as List).cast<Map<String, dynamic>>();
      final out = <Map<String, dynamic>>[];

      for (final m in arr) {
        final lat = double.tryParse('${m['lat']}');
        final lon = double.tryParse('${m['lon']}');
        if (lat == null || lon == null) continue;

        final address = m['address'] as Map<String, dynamic>?;
        final pretty = _composeCityStreetHouse(address) ?? (m['display_name'] as String?);

        final title = (m['name'] as String?) ??
            address?['road'] ??
            address?['suburb'] ??
            address?['city'] ??
            pretty ??
            '';

        out.add({
          'title': '$title',
          'address': (pretty ?? '').trim(),
          'lat': lat,
          'lon': lon,
        });
      }

      final seen = <String>{};
      return out.where((e) => seen.add(e['address'] as String)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------- OSM helpers ----------

  String? _composeCityStreetHouse(Map<String, dynamic>? address) {
    if (address == null) return null;

    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'];

    final street = address['road'] ??
        address['pedestrian'] ??
        address['footway'] ??
        address['residential'];

    final house = address['house_number'];

    final parts = <String>[];
    if (_has(city)) parts.add(city.toString().trim());
    if (_has(street)) parts.add(street.toString().trim());
    if (_has(house)) parts.add(house.toString().trim());

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  Future<Map<String, dynamic>?> _nominatimReverseRaw(
    double lat,
    double lon, {
    int? zoom,
  }) async {
    final params = <String, String>{
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lon',
      'addressdetails': '1',
      'accept-language': 'ru',
    };
    if (zoom != null) params['zoom'] = '$zoom';

    final uri = Uri.https(_base, '/reverse', params);
    final r = await http.get(uri, headers: {'User-Agent': _ua, 'Accept': 'application/json'});
    if (r.statusCode != 200) return null;

    return json.decode(r.body) as Map<String, dynamic>;
  }

  bool _has(Object? s) => s is String && s.trim().isNotEmpty;
}
