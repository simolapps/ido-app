import 'dart:convert';
import 'package:http/http.dart' as http;

/// Прямоугольник ограничений (bbox) для запроса улиц в пределах НП
class BBox {
  final double minLon, minLat, maxLon, maxLat;
  const BBox(this.minLon, this.minLat, this.maxLon, this.maxLat);
}

class Settlement {
  final String name;
  final String? state;
  final String? country;
  final double lat;
  final double lon;
  final BBox? bbox; // если пришёл из Nominatim

  const Settlement({
    required this.name,
    required this.lat,
    required this.lon,
    this.state,
    this.country,
    this.bbox,
  });
}

class Street {
  final String name;
  const Street(this.name);
}

class NominatimSuggest {
  NominatimSuggest({this.base = 'https://nominatim.openstreetmap.org', this.locale = 'ru'});
  final String base;
  final String locale;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'User-Agent': 'ido-app/1.0 (+suggest)',
  };

  /// Населённые пункты (city/town/village/hamlet/locality)
  Future<List<Settlement>> suggestSettlements(String query, {int limit = 10}) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse('$base/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'accept-language': locale,
      'addressdetails': '1',
      'limit': '$limit',
      'featureType': 'settlement', // неофициально; основной фильтр ниже
      'namedetails': '0',
      'extratags': '0',
      'polygon_geojson': '0',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();

    final out = <Settlement>[];
    for (final e in list) {
      final cls = (e['class'] ?? '').toString();         // place
      final typ = (e['type'] ?? '').toString();          // city|town|village|hamlet|locality
      if (cls != 'place' ||
          !['city','town','village','hamlet','locality','municipality'].contains(typ)) {
        continue;
      }
      final displayName = (e['display_name'] ?? '').toString();
      final name = (e['name'] ?? '').toString().isNotEmpty
          ? e['name'].toString()
          : displayName.split(',').first.trim();

      final lat = double.tryParse((e['lat'] ?? '').toString());
      final lon = double.tryParse((e['lon'] ?? '').toString());
      if (lat == null || lon == null || name.isEmpty) continue;

      final addr = (e['address'] as Map?) ?? {};
      final state = addr['state']?.toString();
      final country = addr['country']?.toString();

      BBox? bbox;
      final bb = (e['boundingbox'] as List?)?.map((v) => double.tryParse(v.toString())).toList();
      if (bb != null && bb.length == 4 && bb.every((v) => v != null)) {
        // boundingbox = [minLat, maxLat, minLon, maxLon]
        bbox = BBox(bb[2]!, bb[0]!, bb[3]!, bb[1]!);
      }

      out.add(Settlement(
        name: name,
        lat: lat,
        lon: lon,
        state: state,
        country: country,
        bbox: bbox,
      ));
    }

    // убрать дубли имя+state+country
    final seen = <String>{};
    return out.where((s) {
      final k = '${s.name}|${s.state}|${s.country}';
      if (seen.contains(k)) return false;
      seen.add(k);
      return true;
    }).toList();
  }

  /// Улицы в пределах bbox города (если bbox нет — можно задать aroundLon/Lat+viewbox)
  Future<List<Street>> suggestStreets(String query, {BBox? bbox, int limit = 10}) async {
    if (query.trim().length < 2) return [];
    final qp = <String, String>{
      'q': query,
      'format': 'jsonv2',
      'accept-language': locale,
      'addressdetails': '0',
      'limit': '$limit',
    };

    // Ограничим область поиска улиц выбранным городом
    if (bbox != null) {
      qp['viewbox'] = '${bbox.minLon},${bbox.maxLat},${bbox.maxLon},${bbox.minLat}';
      qp['bounded'] = '1';
    }

    final uri = Uri.parse('$base/search').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();

    final out = <Street>[];
    for (final e in list) {
      final cls = (e['class'] ?? '').toString(); // highway, place, etc.
      final typ = (e['type'] ?? '').toString();  // residential, primary, footway...
      final name = (e['name'] ?? '').toString();
      if (cls == 'highway' && name.isNotEmpty) {
        out.add(Street(name));
      }
    }

    // уникальные
    final seen = <String>{};
    return out.where((s) {
      if (seen.contains(s.name)) return false;
      seen.add(s.name);
      return true;
    }).toList();
  }

  /// (необязательно) номера домов — работает ограниченно; для РФ лучше Dadata
  Future<List<String>> suggestHouses(String streetFullQuery, {BBox? bbox, int limit = 10}) async {
    if (streetFullQuery.trim().length < 2) return [];
    final qp = <String, String>{
      'q': streetFullQuery,
      'format': 'jsonv2',
      'accept-language': locale,
      'addressdetails': '1',
      'limit': '$limit',
    };
    if (bbox != null) {
      qp['viewbox'] = '${bbox.minLon},${bbox.maxLat},${bbox.maxLon},${bbox.minLat}';
      qp['bounded'] = '1';
    }

    final uri = Uri.parse('$base/search').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    final set = <String>{};
    for (final e in list) {
      final addr = (e['address'] as Map?) ?? {};
      final house = addr['house_number']?.toString();
      if (house != null && house.isNotEmpty) set.add(house);
    }
    return set.toList();
  }
}
