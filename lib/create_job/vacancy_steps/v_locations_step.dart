import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';
import '../../../services/dadata_suggest.dart';

class VLocationsStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VLocationsStep({super.key, required this.draft, required this.onNext});

  @override
  State<VLocationsStep> createState() => _VLocationsStepState();
}

class _VLocationsStepState extends State<VLocationsStep> {
  final _formKey = GlobalKey<FormState>();

  final _city   = TextEditingController();
  final _street = TextEditingController();
  final _house  = TextEditingController();

  final _fnCity   = FocusNode();
  final _fnStreet = FocusNode();
  final _fnHouse  = FocusNode();

  late final DadataSuggest _dd;

  DadataAddress? _selPlace;   // город или иной НП (settlement)
  DadataAddress? _selStreet;  // выбранная улица

  @override
  void initState() {
    super.initState();
    _dd = DadataSuggest('https://idoapi.tw1.ru/dadata_proxy.php');

    if (widget.draft.workAddresses.isNotEmpty) {
      final addr = widget.draft.workAddresses.first;
      final parts = addr.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) _city.text = parts[0];
      if (parts.length >= 2) _street.text = parts[1];
      if (parts.length >= 3) _house.text = parts.sublist(2).join(', ');
    }
  }

  @override
  void dispose() {
    _city.dispose();
    _street.dispose();
    _house.dispose();
    _fnCity.dispose();
    _fnStreet.dispose();
    _fnHouse.dispose();
    super.dispose();
  }

  // ✅ Теперь достаточно города/НП
  bool get _canNext => _city.text.trim().isNotEmpty;

  String _composeAddress() {
    final parts = <String>[];
    if (_city.text.trim().isNotEmpty)   parts.add(_city.text.trim());
    if (_street.text.trim().isNotEmpty) parts.add(_street.text.trim());
    if (_house.text.trim().isNotEmpty)  parts.add(_house.text.trim());
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxListH = min(MediaQuery.of(context).size.height * .45, 360.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? bottomInset + 12 : 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canNext
                  ? () {
                      widget.draft.workAddresses
                        ..clear()
                        ..add(_composeAddress());
                      widget.onNext();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canNext ? AppColors.vacancy : AppColors.gray300,
                foregroundColor: _canNext ? Colors.white : AppColors.gray600,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Далее'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            children: [
              const Text(
                'Где нужно работать',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 8),

              // --- Город / населённый пункт ---
              TypeAheadField<DadataAddress>(
                controller: _city,
                focusNode: _fnCity,
                debounceDuration: const Duration(milliseconds: 250),
                suggestionsCallback: (q) {
                  final t = q.trim();
                  if (t.length < 2) return Future.value(<DadataAddress>[]);
                  return _dd.suggestSettlements(t);
                },
                constraints: BoxConstraints(maxHeight: maxListH),
                loadingBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                emptyBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Начните вводить город или населённый пункт…',
                      style: TextStyle(color: AppColors.gray600)),
                ),
                itemBuilder: (_, s) {
                  final title = s.data['city_with_type']
                              ?? s.data['settlement_with_type']
                              ?? s.value;
                  final subtitle = s.data['region_with_type'] ?? '';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                },
                onSelected: (s) {
                  _selPlace = s;
                  _city.text = s.data['city_with_type']
                            ?? s.data['settlement_with_type']
                            ?? s.value;
                  // сбрасываем ниже
                  _street.clear();
                  _house.clear();
                  _selStreet = null;
                  setState(() {});
                  _fnStreet.requestFocus();
                },
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _fnStreet.requestFocus(),
                    decoration: _dec('Город / населённый пункт'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Укажите населённый пункт' : null,
                  );
                },
              ),

              const SizedBox(height: 12),

              // --- Улица (НЕОБЯЗАТЕЛЬНО) ---
              TypeAheadField<DadataAddress>(
                controller: _street,
                focusNode: _fnStreet,
                debounceDuration: const Duration(milliseconds: 300),
                suggestionsCallback: (q) {
                  final t = q.trim();
                  final cityFias = _selPlace?.data['city_fias_id'] as String?;
                  final settFias = _selPlace?.data['settlement_fias_id'] as String?;
                  if ((cityFias == null && settFias == null) || t.length < 2) {
                    return Future.value(<DadataAddress>[]);
                  }
                  return _dd.suggestStreets(
                    t,
                    cityFiasId: cityFias ?? settFias,
                  );
                },
                constraints: BoxConstraints(maxHeight: maxListH),
                loadingBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                emptyBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    (_selPlace == null)
                        ? 'Сначала выберите населённый пункт'
                        : 'Начните вводить улицу… (необязательно)',
                    style: TextStyle(color: AppColors.gray600),
                  ),
                ),
                itemBuilder: (_, s) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  title: Text(
                    s.data['street_with_type'] ?? s.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onSelected: (s) {
                  _selStreet = s;
                  _street.text = s.data['street_with_type'] ?? s.value;
                  setState(() {});
                  _fnHouse.requestFocus();
                },
                builder: (context, controller, focusNode) {
                  final enabled = _selPlace != null;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _fnHouse.requestFocus(),
                    decoration: _dec('Улица (необязательно)'),
                    // ❌ валидатор убран — поле необязательное
                  );
                },
              ),

              const SizedBox(height: 12),

              // --- Дом (можно вводить и без улицы; подсказки появятся, если улица выбрана) ---
              TypeAheadField<DadataAddress>(
                controller: _house,
                focusNode: _fnHouse,
                debounceDuration: const Duration(milliseconds: 250),
                suggestionsCallback: (q) {
                  final t = q.trim();
                  if (t.isEmpty || _selPlace == null || _selStreet == null) {
                    return Future.value(<DadataAddress>[]);
                  }
                  final cityFias = _selPlace!.data['city_fias_id'] as String?;
                  final settFias = _selPlace!.data['settlement_fias_id'] as String?;
                  final streetFias = _selStreet!.streetFias;
                  return _dd.suggestHouses(
                    t,
                    cityFiasId: cityFias ?? settFias,
                    streetFiasId: streetFias,
                  );
                },
                constraints: BoxConstraints(maxHeight: maxListH),
                loadingBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                emptyBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    (_selPlace == null)
                        ? 'Сначала выберите населённый пункт'
                        : (_selStreet == null
                            ? 'Можно указать дом вручную, подсказки появятся после выбора улицы'
                            : 'Начните вводить номер дома…'),
                    style: TextStyle(color: AppColors.gray600),
                  ),
                ),
                itemBuilder: (_, s) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  title: Text(
                    s.data['house'] ?? s.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onSelected: (s) {
                  _house.text = s.data['house'] ?? s.value;
                  setState(() {});
                },
                builder: (context, controller, focusNode) {
                  final enabled = _selPlace != null; // ✅ можно вводить без улицы
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: _dec('Дом, корпус, строение'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.gray500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.emerald600, width: 1.6),
        ),
      );
}
