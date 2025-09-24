// lib/services/yandex_geocoder.dart
import 'package:yandex_mapkit/yandex_mapkit.dart' as ymk;
import 'dart:math' as math;

class YandexGeocoder {
  YandexGeocoder._();
  static final instance = YandexGeocoder._();

  /// Возвращает "Город, Улица, Дом" (если дом найден), иначе formattedAddress.
  Future<String?> reversePretty(double lat, double lon) async {
    final meta = await _reverseToponymHouseAware(lat, lon);
    final addr = meta?.address;
    if (addr == null) return null;

    final comps = addr.addressComponents;
    String? city = comps[ymk.SearchComponentKind.locality] ??
        comps[ymk.SearchComponentKind.province] ??
        comps[ymk.SearchComponentKind.region] ??
        comps[ymk.SearchComponentKind.area];

    String? street = comps[ymk.SearchComponentKind.street];
    String? house  = comps[ymk.SearchComponentKind.house];

    // Диагностический лог
    // ignore: avoid_print
    print('YA comps: {city=$city, street=$street, house=$house}');

    final parts = <String>[];
    if (_has(city)) parts.add(city!.trim());
    if (_has(street)) parts.add(street!.trim());
    if (_has(house)) parts.add(house!.trim());

    return parts.isNotEmpty ? parts.join(', ') : addr.formattedAddress;
  }

  /// Ищем сначала по точке, затем микро-сэмплом вокруг, чтобы попасть в полигон дома.
  Future<ymk.SearchItemToponymMetadata?> _reverseToponymHouseAware(double lat, double lon) async {
    // 1) Прямая попытка по точке
    final meta0 = await _firstWithHouse(
      await _searchByPoint(lat, lon, zoom: 19, pageSize: 20),
    );
    if (meta0 != null) return meta0;

    // 2) Микро-сэмплинг вокруг точки (радиус ~6–8 м)
    final samples = _around(lat, lon, meters: 7);
    for (final p in samples) {
      final meta = await _firstWithHouse(
        await _searchByPoint(p.$1, p.$2, zoom: 19, pageSize: 20),
      );
      if (meta != null) return meta;
    }

    // 3) Лёгкий ослабленный fallback – берём ближайший toponym (улица/город)
    final items = await _searchByPoint(lat, lon, zoom: 18, pageSize: 20);
    return items.isNotEmpty ? items.first.toponymMetadata : null;
  }

  Future<List<ymk.SearchItem>> _searchByPoint(
    double lat,
    double lon, {
    required int zoom,
    required int pageSize,
  }) async {
    final point = ymk.Point(latitude: lat, longitude: lon);
    final (_, future) = await ymk.YandexSearch.searchByPoint(
      point: point,
      zoom: zoom,
      searchOptions: ymk.SearchOptions(
        searchType: ymk.SearchType.geo,
        geometry: false,
        resultPageSize: pageSize,
        userPosition: point, // подскажем «контекст» точки
        disableSpellingCorrection: true,
      ),
    );
    final res = await future;
    return res.items ?? const <ymk.SearchItem>[];
  }

  ymk.SearchItemToponymMetadata? _firstWithHouse(List<ymk.SearchItem> items) {
    for (final it in items) {
      final meta = it.toponymMetadata;
      final comps = meta?.address?.addressComponents;
      final house = comps?[ymk.SearchComponentKind.house];
      if (_has(house)) return meta;
    }
    return null;
  }

  bool _has(String? s) => s != null && s.trim().isNotEmpty;

  /// Возвращает 8 соседних точек на расстоянии 'meters' вокруг (lat,lon).
  List<(double,double)> _around(double lat, double lon, {double meters = 7}) {
    // 1 градус широты ≈ 111_320 м
    const double mPerDegLat = 111320.0;
    final double latDeg = meters / mPerDegLat;

    // 1 градус долготы ≈ 111_320 * cos(lat)
    final double mPerDegLon = mPerDegLat * math.cos(lat * math.pi / 180.0);
    final double lonDeg = meters / mPerDegLon;

    return <(double,double)>[
      (lat + latDeg, lon),        // N
      (lat - latDeg, lon),        // S
      (lat, lon + lonDeg),        // E
      (lat, lon - lonDeg),        // W
      (lat + latDeg, lon + lonDeg),  // NE
      (lat + latDeg, lon - lonDeg),  // NW
      (lat - latDeg, lon + lonDeg),  // SE
      (lat - latDeg, lon - lonDeg),  // SW
    ];
  }
}
