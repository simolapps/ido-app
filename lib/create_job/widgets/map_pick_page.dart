// lib/pages/create_job/widgets/map_pick_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as ymk;

import 'package:ido/services/local_geocoder.dart' as geo;

// ---------- единый контракт ----------
class LatLngPick {
  final double lat;
  final double lng;
  final String? address;
  const LatLngPick(this.lat, this.lng, {this.address});
}

/// Только Яндекс MapKit (без geolocator)
class MapPickPage extends StatefulWidget {
  const MapPickPage({super.key});

  @override
  State<MapPickPage> createState() => _MapPickPageState();
}

class _MapPickPageState extends State<MapPickPage> {
  late ymk.YandexMapController _map;
  bool _mapReady = false;

 
  double _lat = 42.983100;
  double _lng = 47.504745; // Москва центр
  double _zoom = 14;

  Timer? _revDebounce;
  bool _revBusy = false;
  String? _pickedAddress;

  List<ymk.MapObject> _mapObjects = [];

  @override
  void initState() {
    super.initState();
    _updateMarker(updateCamera: false);
    _reverseUpdate(immediate: true);
  }

  @override
  void dispose() {
    _revDebounce?.cancel();
    super.dispose();
  }

  void _updateMarker({bool updateCamera = true}) {
    _mapObjects = [
      ymk.CircleMapObject(
        mapId: const ymk.MapObjectId('pick_point'),
        circle: ymk.Circle(
          center: ymk.Point(latitude: _lat, longitude: _lng),
          radius: 10, // м
        ),
        strokeWidth: 3,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.25),
      ),
    ];

    if (_mapReady && updateCamera) {
      _map.moveCamera(
        ymk.CameraUpdate.newCameraPosition(
          ymk.CameraPosition(
            target: ymk.Point(latitude: _lat, longitude: _lng),
            zoom: _zoom,
          ),
        ),
        animation: const ymk.MapAnimation(
          type: ymk.MapAnimationType.smooth,
          duration: 0.25,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void _reverseUpdate({bool immediate = false}) {
    _revDebounce?.cancel();

    Future<void> doWork() async {
      if (!mounted) return;
      setState(() => _revBusy = true);

      final addr = await geo.LocalGeocoder.instance.reverse(_lat, _lng);
      // ignore: avoid_print
      print('🗺️ Yandex reverse lat=$_lat lon=$_lng → $addr');

      if (!mounted) return;
      setState(() {
        _pickedAddress = addr;
        _revBusy = false;
      });
    }

    if (immediate) {
      doWork();
    } else {
      _revDebounce = Timer(const Duration(milliseconds: 250), doWork);
    }
  }

  /// Центр на текущее местоположение без geolocator:
  /// включаем слой пользователя и читаем позицию через getUserCameraPosition()
  Future<void> _centerToMyLocation() async {
    if (!_mapReady) return;

    // Включаем слой пользователя (один раз достаточно; можно держать включенным)
    await _map.toggleUserLayer(
      visible: true,
      headingEnabled: false,
      autoZoomEnabled: false,
    );

    // Пытаемся получить позицию пользователя с ретраем — слой может прогружаться доли секунды
    ymk.CameraPosition? userPos;
    for (int i = 0; i < 8; i++) {
      userPos = await _map.getUserCameraPosition();
      if (userPos != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (userPos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить местоположение')),
      );
      return;
    }

    _lat = userPos.target.latitude;
    _lng = userPos.target.longitude;
    _zoom = 16;
    _updateMarker(updateCamera: true);
    _reverseUpdate();
  }

  void _onMapTap(ymk.Point p) {
    _lat = p.latitude;
    _lng = p.longitude;
    _updateMarker(updateCamera: true);
    _reverseUpdate();
  }

  void _onCameraChanged(ymk.CameraPosition pos, ymk.CameraUpdateReason reason, bool finished) {
    _lat = pos.target.latitude;
    _lng = pos.target.longitude;
    _zoom = pos.zoom;
    _updateMarker(updateCamera: false);
    if (finished) _reverseUpdate();
  }

  Future<void> _confirm() async {
    // ignore: avoid_print
    print('✅ CONFIRM Yandex lat=$_lat lon=$_lng addr=$_pickedAddress');
    Navigator.pop(context, LatLngPick(_lat, _lng, address: _pickedAddress));
  }

  @override
  Widget build(BuildContext context) {
    final addrChip = (_revBusy || (_pickedAddress != null && _pickedAddress!.isNotEmpty))
        ? Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _revBusy ? 'Определяем адрес…' : (_pickedAddress ?? 'Адрес не найден'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
appBar: AppBar(
  title: const Text('Поиск и карта'),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerToMyLocation,
            tooltip: 'Моё местоположение',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ymk.YandexMap(
              onMapCreated: (c) async {
                _map = c;
                _mapReady = true;
                _updateMarker(updateCamera: true);
              },
              onMapTap: _onMapTap,
              onCameraPositionChanged: _onCameraChanged,
              mapObjects: _mapObjects,
              nightModeEnabled: false,
              mode2DEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
          ),
          addrChip,
        ],
      ),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
floatingActionButton: SafeArea(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      FloatingActionButton(
        heroTag: 'fab-my',            // разные heroTag обязательны
        onPressed: _centerToMyLocation,
        child: const Icon(Icons.my_location),
        tooltip: 'Моё местоположение',
      ),
      const SizedBox(height: 12),
      FloatingActionButton.extended(
        heroTag: 'fab-ok',
        onPressed: _confirm,
        icon: const Icon(Icons.check),
        label: const Text('Выбрать'),
      ),
    ],
  ),
),
    );
  }
}
