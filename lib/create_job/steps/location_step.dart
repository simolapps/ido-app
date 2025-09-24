// lib/pages/create_job/steps/location_step.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:ido/models/step_config.dart';
import '../../../models/job_draft.dart';

// Геокодер (форматирование/фолбэк)
import '../../../services/local_geocoder.dart' as geo;
// Яндекс-подсказки (город/улица/дом)
import '../../../services/yandex_place_suggest.dart' as yps;
// Карта (Яндекс)
import '../widgets/map_pick_page.dart' as pick;

/// Итоговый вариант выбора:
///  - Можно выполнить удалённо        → адрес не нужен
///  - Нужно присутствие по адресу     → адрес из 3 строк (Город/Улица/Дом)
///  - У меня                          → адрес из 3 строк
///  - У исполнителя                   → адрес не нужен (адрес исполнителя будет позже)
///  - Не важно                        → адрес не нужен
enum PlaceVariant { remote, onsite, atCustomer, atPerformer, any }

class LocationStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  final AddressConfig? config;

  const LocationStep({
    super.key,
    required this.draft,
    required this.onNext,
    this.config,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  // --- Контроллеры для 3-х полей ---
  final _cityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();

  // Выбранные сущности из подсказок
  yps.CityPick? _cityPick;
  yps.StreetPick? _streetPick;
  yps.HousePick? _housePick;

  // Для маршрута из нескольких точек (если cfg.multiPoints)
  final _routeCtrls = <TextEditingController>[TextEditingController()];

  // Выбранный вариант верхнего уровня
  PlaceVariant? _variant; // null -> «пустые» радиокнопки видны
  bool _busy = false;

  AddressConfig get cfg => widget.config ?? AddressConfig.fromJson(null);

  bool get _isMulti => cfg.multiPoints;
  bool get _allowRemote => cfg.allowRemote;

  String label(String key, String fallback) =>
      (cfg.labels[key] ?? fallback).toString();
  String ph(String key, String fallback) =>
      (cfg.placeholders[key] ?? fallback).toString();

  @override
  void initState() {
    super.initState();

    // Восстановление из черновика
    if (_isMulti) {
      _routeCtrls
        ..clear()
        ..addAll(
          (widget.draft.addressPoints.isNotEmpty
                  ? widget.draft.addressPoints
                  : <String>[''])
              .map((s) => TextEditingController(text: s)),
        );
      // Минимум видимых строк = min_points
      while (_routeCtrls.length < cfg.minPoints) {
        _routeCtrls.add(TextEditingController());
      }
      _variant =
          PlaceVariant.onsite; // маршрут всегда предполагает адреса точек
    } else {
      // Три строки адреса (всегда для очных вариантов)
      if (widget.draft.address.isNotEmpty) {
        final parts =
            widget.draft.address.split(',').map((e) => e.trim()).toList();
        if (parts.isNotEmpty) _cityCtrl.text = parts[0];
        if (parts.length >= 2) _streetCtrl.text = parts[1];
        if (parts.length >= 3) _houseCtrl.text = parts.sublist(2).join(', ');
      }
      // Вариант из черновика
      if (widget.draft.isRemote == true) {
        _variant = PlaceVariant.remote;
      } else if (widget.draft.placeMode == 'atCustomer') {
        _variant = PlaceVariant.atCustomer;
      } else if (widget.draft.placeMode == 'atPerformer') {
        _variant = PlaceVariant.atPerformer;
      } else if (widget.draft.placeMode == 'any') {
        _variant = PlaceVariant.any;
      } else if (widget.draft.placeMode == 'onsite') {
        _variant = PlaceVariant.onsite;
      }
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _houseCtrl.dispose();
    for (final c in _routeCtrls) c.dispose();
    super.dispose();
  }

  // ---------- helpers ----------

  /// Нужен ли ввод адреса (3 строки) для выбранного варианта
  bool get _needAddress3 {
    if (_isMulti) return true;
    if (_variant == null) return false;
    return _variant == PlaceVariant.onsite ||
        _variant == PlaceVariant.atCustomer;
  }

  /// Достаточно ли заполненности адреса (для кнопки Далее)
  bool get _hasAddressOk {
    if (_isMulti) {
      final filled = _routeCtrls.where((c) => c.text.trim().isNotEmpty).length;
      return filled >= cfg.minPoints;
    }
    // каскад 3-х: достаточно города + улицы
    final hasCity = _cityCtrl.text.trim().isNotEmpty || _cityPick != null;
    final hasStreet = _streetCtrl.text.trim().isNotEmpty || _streetPick != null;
    return hasCity && hasStreet;
  }

  /// Сбор строки адреса из 3-х полей
  String _composeAddress() {
    if (_housePick != null) return _housePick!.display;
    final parts = <String>[];
    final city = (_cityPick?.name ?? _cityCtrl.text).trim();
    final street = (_streetPick?.name ?? _streetCtrl.text).trim();
    final house = _houseCtrl.text.trim();
    if (city.isNotEmpty) parts.add(city);
    if (street.isNotEmpty) parts.add(street);
    if (house.isNotEmpty) parts.add(house);
    return parts.join(', ');
  }

  Future<void> _openMapAndFill3() async {
    final point = await Navigator.push<pick.LatLngPick>(
      context,
      MaterialPageRoute(builder: (_) => const pick.MapPickPage()),
    );
    if (!mounted || point == null) return;

    setState(() => _busy = true);
    try {
      final addr = point.address ??
          await geo.LocalGeocoder.instance.reverse(point.lat, point.lng);
      if (addr == null || addr.trim().isEmpty) return;

      final parts = addr.split(',').map((e) => e.trim()).toList();
      _cityCtrl.text = parts.isNotEmpty ? parts[0] : '';
      _streetCtrl.text = parts.length >= 2 ? parts[1] : '';
      _houseCtrl.text = parts.length >= 3 ? parts.sublist(2).join(', ') : '';

      _cityPick = null;
      _streetPick = null;
      _housePick = null;
      setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- UI блоки ----------

  Widget _radioTopOptions() {
    final title = label('title', 'Место оказания услуги');
    final remoteTitle = label('remote_switch', 'Можно выполнить удалённо');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        const SizedBox(height: 8),

        if (_allowRemote)
          RadioListTile<PlaceVariant>(
            value: PlaceVariant.remote,
            groupValue: _variant,
            onChanged: (v) => setState(() => _variant = v),
            title: Text(remoteTitle),
          ),

        // Отдельные варианты, как просил:
        RadioListTile<PlaceVariant>(
          value: PlaceVariant.onsite,
          groupValue: _variant,
          onChanged: (v) => setState(() => _variant = v),
          title: const Text('Нужно присутствие по адресу'),
        ),
        RadioListTile<PlaceVariant>(
          value: PlaceVariant.atCustomer,
          groupValue: _variant,
          onChanged: (v) => setState(() => _variant = v),
          title: const Text('У меня'),
        ),
        RadioListTile<PlaceVariant>(
          value: PlaceVariant.atPerformer,
          groupValue: _variant,
          onChanged: (v) => setState(() => _variant = v),
          title: const Text('У исполнителя'),
        ),
        RadioListTile<PlaceVariant>(
          value: PlaceVariant.any,
          groupValue: _variant,
          onChanged: (v) => setState(() => _variant = v),
          title: const Text('Не важно'),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _cascadeFields3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Город ----
        TypeAheadField<yps.CityPick>(
          suggestionsCallback: (q) => yps.YandexPlaceSuggest.suggestCities(q),
          debounceDuration: const Duration(milliseconds: 280),
          hideOnEmpty: true,
          builder: (ctx, ctrl, focus) => TextField(
            controller: _cityCtrl,
            focusNode: focus,
            style: const TextStyle(color: Colors.black87),
            cursorColor: Colors.black87,
            decoration: InputDecoration(
              labelText: label('city', 'Город'),
              hintText: ph('city', 'Например: Махачкала'),
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black45),
            ),
            onChanged: (_) {
              _cityPick = null;
              _streetPick = null;
              _housePick = null;
              _streetCtrl.clear();
              _houseCtrl.clear();
              setState(() {});
            },
          ),
          itemBuilder: (_, s) => ListTile(
            dense: true,
            title: Text(s.name, style: const TextStyle(color: Colors.black87)),
          ),
          onSelected: (s) {
            _cityPick = s;
            _cityCtrl.text = s.name;
            _streetPick = null;
            _housePick = null;
            _streetCtrl.clear();
            _houseCtrl.clear();
            setState(() {});
          },
          emptyBuilder: (_) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Ничего не найдено'),
          ),
        ),
        const SizedBox(height: 12),

        // ---- Улица ----
        TypeAheadField<yps.StreetPick>(
          suggestionsCallback: (q) {
            if (q.trim().length < 2) return Future.value(<yps.StreetPick>[]);
            if (_cityPick == null) return Future.value(<yps.StreetPick>[]);
            return yps.YandexPlaceSuggest.suggestStreets(q, _cityPick!);
          },
          debounceDuration: const Duration(milliseconds: 280),
          hideOnEmpty: true,
          builder: (ctx, ctrl, focus) => TextField(
            controller: _streetCtrl,
            focusNode: focus,
            enabled: _cityCtrl.text.trim().isNotEmpty,
            style: const TextStyle(color: Colors.black87),
            cursorColor: Colors.black87,
            decoration: InputDecoration(
              labelText: label('street', 'Улица'),
              hintText: ph('street', 'Например: проспект Акушинского'),
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black45),
            ),
            onChanged: (_) {
              _streetPick = null;
              _housePick = null;
              _houseCtrl.clear();
              setState(() {});
            },
          ),
          itemBuilder: (_, s) => ListTile(
            dense: true,
            title: Text(s.name, style: const TextStyle(color: Colors.black87)),
          ),
          onSelected: (s) {
            _streetPick = s;
            _streetCtrl.text = s.name;
            _housePick = null;
            _houseCtrl.clear();
            setState(() {});
          },
          emptyBuilder: (_) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Ничего не найдено'),
          ),
        ),
        const SizedBox(height: 12),

        // ---- Дом ----
        TypeAheadField<yps.HousePick>(
          suggestionsCallback: (q) {
            if (_cityPick == null || _streetPick == null)
              return Future.value(<yps.HousePick>[]);
            return yps.YandexPlaceSuggest.suggestHouses(
              city: _cityPick!,
              street: _streetPick!,
              housePrefix: q,
            );
          },
          debounceDuration: const Duration(milliseconds: 220),
          hideOnEmpty: true,
          builder: (ctx, ctrl, focus) => TextField(
            controller: _houseCtrl,
            focusNode: focus,
            enabled: _streetCtrl.text.trim().isNotEmpty,
            style: const TextStyle(color: Colors.black87),
            cursorColor: Colors.black87,
            decoration: InputDecoration(
              labelText: label('house', 'Дом, корпус, строение'),
              hintText: ph('house', 'Например: 19к1'),
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black45),
              suffixIcon: const Icon(Icons.home_outlined),
            ),
            onChanged: (_) {
              _housePick = null; // ручной ввод допускаем
              setState(() {});
            },
          ),
          itemBuilder: (_, s) => ListTile(
            dense: true,
            title:
                Text(s.display, style: const TextStyle(color: Colors.black87)),
          ),
          onSelected: (s) {
            _housePick = s;
            final onlyHouse = s.display.split(', ').last;
            _houseCtrl.text = onlyHouse;
            setState(() {});
          },
          emptyBuilder: (_) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Домов не найдено'),
          ),
        ),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _openMapAndFill3,
          icon: const Icon(Icons.map_outlined),
          label: Text(label('open_map', 'Выбрать на карте')),
        ),
      ],
    );
  }

  Widget _routeInputs() {
    final title = label('title', 'Маршрут');
    final pointLabel = label('point', 'Адрес точки');
    final addPoint = label('add_point', 'Добавить точку');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        const SizedBox(height: 12),
        for (int i = 0; i < _routeCtrls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _routeCtrls[i],
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: '$pointLabel ${i + 1}',
                      hintText: 'Город, улица, дом',
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintStyle: const TextStyle(color: Colors.black45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Выбрать на карте',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _busy
                      ? null
                      : () async {
                          final p = await Navigator.push<pick.LatLngPick>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const pick.MapPickPage()),
                          );
                          if (p == null) return;
                          setState(() => _busy = true);
                          try {
                            final addr = p.address ??
                                await geo.LocalGeocoder.instance
                                    .reverse(p.lat, p.lng);
                            if (addr != null) _routeCtrls[i].text = addr;
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
                IconButton(
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _routeCtrls.length > cfg.minPoints
                      ? () => setState(() => _routeCtrls.removeAt(i).dispose())
                      : null,
                ),
              ],
            ),
          ),
        if (_routeCtrls.length < cfg.maxPoints)
          TextButton.icon(
            onPressed: () =>
                setState(() => _routeCtrls.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: Text(addPoint),
          ),
      ],
    );
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = [];

    if (_isMulti) {
      body.add(_routeInputs());
    } else {
      body.add(_radioTopOptions());
      if (_needAddress3) {
        body.add(_cascadeFields3());
      }
    }

    if (_busy) {
      body.add(const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ));
    }

    // Условия «Далее»
    final canNext = () {
      if (_variant == null) return false; // пока ничего не выбрано
      if (_isMulti) return _hasAddressOk;

      switch (_variant!) {
        case PlaceVariant.remote:
          return true; // адрес не нужен
        case PlaceVariant.onsite:
        case PlaceVariant.atCustomer:
          return _hasAddressOk; // нужен адрес 3 строки
        case PlaceVariant.atPerformer:
        case PlaceVariant.any:
          return true; // адрес не нужен
      }
    }();

    return _wrapWithLocalTheme(
      context,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: body,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy || !canNext
                      ? null
                      : () {
                          if (_isMulti) {
                            widget.draft.addressPoints = _routeCtrls
                                .map((c) => c.text.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            widget.draft.address =
                                widget.draft.addressPoints.isNotEmpty
                                    ? widget.draft.addressPoints.first
                                    : '';
                            widget.draft.isRemote = false;
                            widget.draft.placeMode = 'route';
                          } else {
                            // Сохраняем по выбранному варианту
                            String placeMode = 'any';
                            bool isRemote = false;
                            String address = '';

                            switch (_variant!) {
                              case PlaceVariant.remote:
                                placeMode = 'remote';
                                isRemote = true;
                                address = '';
                                break;

                              case PlaceVariant.onsite:
                                placeMode = 'onsite';
                                isRemote = false;
                                address = _composeAddress();
                                break;

                              case PlaceVariant.atCustomer:
                                placeMode = 'atCustomer';
                                isRemote = false;
                                address = _composeAddress();
                                break;

                              case PlaceVariant.atPerformer:
                                placeMode = 'atPerformer';
                                isRemote = false;
                                address = '';
                                break;

                              case PlaceVariant.any:
                                placeMode = 'any';
                                isRemote = false;
                                address = '';
                                break;
                            }

                            widget.draft.address = address;
                            widget.draft.addressPoints = [];
                            widget.draft.placeMode = placeMode;
                            widget.draft.isRemote = isRemote;
                          }
                          widget.onNext();
                        },
                  child: const Text('Далее'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Локальная тема: серые радиокнопки ДО выбора, чёрный текст, белые поля
Theme _wrapWithLocalTheme(BuildContext context, {required Widget child}) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.black87;
          return Colors.black54; // «пустые» кружки видны
        }),
        overlayColor: MaterialStateProperty.all(Colors.black12),
      ),
      unselectedWidgetColor: Colors.black54,
      listTileTheme: const ListTileThemeData(
        textColor: Colors.black87,
        iconColor: Colors.black54,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.black54),
        hintStyle: TextStyle(color: Colors.black45),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black26, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black87, width: 1.4),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black87,
        selectionColor: Color(0x33555555),
        selectionHandleColor: Colors.black87,
      ),
    ),
    child: child,
  );
}
