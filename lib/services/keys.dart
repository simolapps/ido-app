// lib/services/keys.dart

/// SDK-ключ Яндекс MapKit (мобильный SDK).
/// Можно задать через --dart-define=YANDEX_MAPKIT_KEY=...,
/// либо оставить defaultValue для локальной разработки.
const String yandexMapkitKey = String.fromEnvironment(
  'YANDEX_MAPKIT_KEY',
  defaultValue: '56f05f88-3e29-4cc1-9533-9f1daf4b099e',
);

bool get hasMapkitKey => yandexMapkitKey.isNotEmpty;
