import 'dart:convert';
import 'package:http/http.dart' as http;

class TwoGisCity {
  final String name;
  final String? region;
  final String? country;
  final double? lat;
  final double? lon;

  TwoGisCity({
    required this.name,
    this.region,
    this.country,
    this.lat,
    this.lon,
  });
}

class TwoGisSuggestApi {
  TwoGisSuggestApi(this.apiKey, {this.locale = 'ru_RU'});
  final String apiKey;
  final String locale;

  /// Подсказки по городам (adm_div: city/settlement/place)
  Future<List<TwoGisCity>> suggestCities(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse('https://catalog.api.2gis.com/3.0/suggests').replace(
      queryParameters: {
        'q': query,
        'suggest_type': 'address',
        'locale': locale,
        'key': apiKey,
      },
    );

    final res = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'ido-app/1.0',
    });

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['result']?['items'] as List?) ?? [];

    final out = <TwoGisCity>[];
    for (final it in items) {
      final type = (it['type'] ?? '').toString();     // "adm_div"
      final subtype = (it['subtype'] ?? '').toString(); // "city"/"settlement"/"place"
      if (type == 'adm_div' && (subtype == 'city' || subtype == 'settlement' || subtype == 'place')) {
        final name = (it['name'] ?? '').toString();
        if (name.isEmpty) continue;

        final adm = (it['adm_div'] as Map?) ?? {};
        final address = (it['address'] as Map?) ?? {};
        final region = (adm['district'] ?? adm['region'] ?? address['region'])?.toString();
        final country = (address['country']?.toString().isNotEmpty ?? false) ? address['country'].toString() : null;

        final point = it['point'] as Map?; // может отсутствовать
        final lon = (point?['lon'] as num?)?.toDouble();
        final lat = (point?['lat'] as num?)?.toDouble();

        out.add(TwoGisCity(name: name, region: region, country: country, lat: lat, lon: lon));
      }
    }

    // Убираем дубли по имени+региону+стране
    final seen = <String>{};
    return out.where((c) {
      final key = '${c.name}|${c.region}|${c.country}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
