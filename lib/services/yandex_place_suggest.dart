// lib/services/yandex_place_suggest.dart
import 'dart:math' as math;
import 'package:yandex_mapkit/yandex_mapkit.dart' as ymk;

class CityPick { final String name; final ymk.Point point; CityPick(this.name, this.point); }
class StreetPick { final String name; final ymk.Point point; StreetPick(this.name, this.point); }
class HousePick { final String display; final ymk.Point point; HousePick(this.display, this.point); }

class YandexPlaceSuggest {
  /// Границы вокруг точки (км) — для ограничения поиска улиц/домов городом.
  static ymk.BoundingBox _boxAround(ymk.Point p, {double km = 12}) {
    const mPerDegLat = 111320.0;
    final dLat = (km * 1000) / mPerDegLat;
    final mPerDegLon = mPerDegLat * math.cos(p.latitude * math.pi / 180);
    final dLon = (km * 1000) / mPerDegLon;
    return ymk.BoundingBox(
      southWest: ymk.Point(latitude: p.latitude - dLat, longitude: p.longitude - dLon),
      northEast: ymk.Point(latitude: p.latitude + dLat, longitude: p.longitude + dLon),
    );
  }

  static Future<List<CityPick>> suggestCities(String q) async {
    if (q.trim().length < 2) return [];
    final geom = ymk.Geometry.fromBoundingBox(
      const ymk.BoundingBox(
        southWest: ymk.Point(latitude: -85, longitude: -180),
        northEast: ymk.Point(latitude: 85, longitude: 180),
      ),
    );

    final (_, future) = await ymk.YandexSearch.searchByText(
      searchText: q,
      geometry: geom,
      searchOptions: const ymk.SearchOptions(
        searchType: ymk.SearchType.geo,
        geometry: false,
        resultPageSize: 20,
        disableSpellingCorrection: false,
      ),
    );
    final res = await future;
    final items = res.items ?? const <ymk.SearchItem>[];

    final seen = <String>{};
    final out = <CityPick>[];

    for (final it in items) {
      final meta = it.toponymMetadata;
      final comps = meta?.address?.addressComponents ?? {};
      final city = comps[ymk.SearchComponentKind.locality];
      if (city == null || city.trim().isEmpty) continue;
      if (seen.add(city)) {
        final pt = meta?.balloonPoint; // <-- center удалён
        if (pt != null) out.add(CityPick(city, pt));
      }
    }
    return out;
  }

  static Future<List<StreetPick>> suggestStreets(String q, CityPick city) async {
    if (q.trim().length < 2) return [];
    final geom = ymk.Geometry.fromBoundingBox(_boxAround(city.point, km: 18));

    final (_, future) = await ymk.YandexSearch.searchByText(
      searchText: q,
      geometry: geom,
      searchOptions: ymk.SearchOptions(
        searchType: ymk.SearchType.geo,
        geometry: false,
        resultPageSize: 20,
        userPosition: city.point,
      ),
    );
    final res = await future;
    final items = res.items ?? const <ymk.SearchItem>[];

    final seen = <String>{};
    final out = <StreetPick>[];

    for (final it in items) {
      final meta = it.toponymMetadata;
      final comps = meta?.address?.addressComponents ?? {};
      final street = comps[ymk.SearchComponentKind.street];
      if (street == null || street.trim().isEmpty) continue;

      final locality = comps[ymk.SearchComponentKind.locality];
      if (locality != null && locality != city.name) continue;

      if (seen.add(street)) {
        final pt = meta?.balloonPoint; // <-- center удалён
        if (pt != null) out.add(StreetPick(street, pt));
      }
    }
    return out;
  }

  static Future<List<HousePick>> suggestHouses({
    required CityPick city,
    required StreetPick street,
    required String housePrefix,
  }) async {
    final query = '${street.name} $housePrefix';
    final geom = ymk.Geometry.fromBoundingBox(_boxAround(city.point, km: 18));

    final (_, future) = await ymk.YandexSearch.searchByText(
      searchText: query,
      geometry: geom,
      searchOptions: ymk.SearchOptions(
        searchType: ymk.SearchType.geo,
        geometry: false,
        resultPageSize: 30,
        userPosition: city.point,
        disableSpellingCorrection: true,
      ),
    );
    final res = await future;
    final items = res.items ?? const <ymk.SearchItem>[];

    final out = <HousePick>[];
    for (final it in items) {
      final meta = it.toponymMetadata;
      final comps = meta?.address?.addressComponents ?? {};
      final streetName = comps[ymk.SearchComponentKind.street];
      final locality = comps[ymk.SearchComponentKind.locality];
      final house = comps[ymk.SearchComponentKind.house];

      if (house == null || streetName != street.name || (locality != null && locality != city.name)) {
        continue;
      }
      if (!house.toLowerCase().startsWith(housePrefix.toLowerCase())) continue;

      final pt = meta?.balloonPoint; // <-- center удалён
      if (pt != null) {
        final display = '${city.name}, ${street.name}, $house';
        out.add(HousePick(display, pt));
      }
    }

    final seen = <String>{};
    return out.where((e) => seen.add(e.display)).toList();
  }
}
