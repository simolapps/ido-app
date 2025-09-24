import 'dart:convert';
import 'package:http/http.dart' as http;

class DadataAddress {
  final String value;
  final Map<String, dynamic> data;
  DadataAddress(this.value, this.data);

  String get fiasId => data['fias_id'] ?? '';

  String? get regionFias     => data['region_fias_id'];
  String? get areaFias       => data['area_fias_id'];
  String? get cityFias       => data['city_fias_id'];
  String? get settlementFias => data['settlement_fias_id'];
  String? get streetFias     => data['street_fias_id'];
  String? get house          => data['house'];

  String? get displayCityOrSettlement =>
      data['city_with_type'] ?? data['settlement_with_type'];

  String? get regionWithType => data['region_with_type'];
  String? get streetWithType => data['street_with_type'];
}

class DadataSuggest {
  final Uri proxyUri; // пример: Uri.parse('https://idoapi.tw1.ru/dadata_proxy.php');
  DadataSuggest(String proxyUrl) : proxyUri = Uri.parse(proxyUrl);

  Future<List<DadataAddress>> _suggest({
    required String query,
    required String fromBound,
    required String toBound,
    Map<String, String?> locations = const {},
    int count = 10,
    bool restrictValue = true,
  }) async {
    // Собираем locations (только непустые)
    final Map<String, String> locFlat = {};
    for (final e in locations.entries) {
      final v = e.value;
      if (v != null && v.isNotEmpty) {
        locFlat[e.key] = v;
      }
    }

    final body = <String, dynamic>{
      'query': query,
      'count': count,
      'from_bound': { 'value': fromBound },
      'to_bound':   { 'value': toBound },
      'restrict_value': restrictValue,
      if (locFlat.isNotEmpty) 'locations': [ locFlat ],
    };

    final r = await http.post(
      proxyUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) return <DadataAddress>[];

    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final arr = (json['suggestions'] as List? ?? []);
    return arr.map((s) {
      final m = (s['data'] as Map).cast<String, dynamic>();
      return DadataAddress(s['value'] as String, m);
    }).toList();
  }

  /// Регионы
  Future<List<DadataAddress>> suggestRegions(String q) =>
      _suggest(query: q, fromBound: 'region', toBound: 'region');

  /// Населённые пункты: и ГОРОДА, и СЁЛА/посёлки (city..settlement)
  /// Можно (опционально) ограничить регионом через regionFiasId.
  Future<List<DadataAddress>> suggestSettlements(
    String q, {
    String? regionFiasId,
  }) =>
      _suggest(
        query: q,
        fromBound: 'city',
        toBound: 'settlement',
        locations: {
          if (regionFiasId != null) 'region_fias_id': regionFiasId,
        },
        restrictValue: false, // чтобы не резать варианты
      );

  /// Улицы (по городу ИЛИ по НП). Можно передать любой из fias: city или settlement.
  Future<List<DadataAddress>> suggestStreets(
    String q, {
    String? cityFiasId,
    String? settlementFiasId,
  }) {
    // Если оба null — вернём сразу пусто
    if ((cityFiasId == null || cityFiasId.isEmpty) &&
        (settlementFiasId == null || settlementFiasId.isEmpty)) {
      return Future.value(<DadataAddress>[]);
    }
    return _suggest(
      query: q,
      fromBound: 'street',
      toBound: 'street',
      locations: {
        if (cityFiasId != null && cityFiasId.isNotEmpty)
          'city_fias_id': cityFiasId,
        if (settlementFiasId != null && settlementFiasId.isNotEmpty)
          'settlement_fias_id': settlementFiasId,
      },
    );
  }

  /// Дома (по улице; если street_fias_id нет — можно по городу/НП).
  Future<List<DadataAddress>> suggestHouses(
    String q, {
    String? cityFiasId,
    String? settlementFiasId,
    String? streetFiasId,
  }) {
    if ((streetFiasId == null || streetFiasId.isEmpty) &&
        (cityFiasId == null || cityFiasId.isEmpty) &&
        (settlementFiasId == null || settlementFiasId.isEmpty)) {
      return Future.value(<DadataAddress>[]);
    }
    return _suggest(
      query: q,
      fromBound: 'house',
      toBound: 'house',
      locations: {
        if (streetFiasId != null && streetFiasId.isNotEmpty)
          'street_fias_id': streetFiasId
        else ...{
          if (cityFiasId != null && cityFiasId.isNotEmpty)
            'city_fias_id': cityFiasId,
          if (settlementFiasId != null && settlementFiasId.isNotEmpty)
            'settlement_fias_id': settlementFiasId,
        }
      },
    );
  }
}
