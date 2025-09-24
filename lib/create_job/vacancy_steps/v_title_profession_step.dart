import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';
import '../../../services/vacancy_suggest_api.dart';

const _ZWSP = '\u200B'; // невидимый символ, чтобы открыть подсказки при фокусе

class VTitleProfessionStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VTitleProfessionStep({super.key, required this.draft, required this.onNext});

  @override
  State<VTitleProfessionStep> createState() => _VTitleProfessionStepState();
}

class _VTitleProfessionStepState extends State<VTitleProfessionStep> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _profession = TextEditingController();
  final _industry = TextEditingController();

  final _focusTitle = FocusNode();
  FocusNode? _professionFN;
  FocusNode? _industryFN;

  late final VacancySuggestApi _api;
  int? _pickedIndustryId;
  int? _pickedProfessionId;

  @override
  void initState() {
    super.initState();
    _api = VacancySuggestApi('https://idoapi.tw1.ru');

    _title.text = widget.draft.title;
    _profession.text = widget.draft.profession;
    _industry.text = widget.draft.industry;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusTitle.requestFocus();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _profession.dispose();
    _industry.dispose();
    _focusTitle.dispose();
    super.dispose();
  }

  bool get _canNext =>
      _title.text.trim().isNotEmpty &&
      _profession.text.replaceAll(_ZWSP, '').trim().isNotEmpty;

  String _norm(String s) => s.replaceAll(_ZWSP, '').trim();

  void _ensureZwsp(TextEditingController c, FocusNode fn) {
    if (fn.hasFocus && c.text.isEmpty) {
      c.text = _ZWSP;
      c.selection = const TextSelection.collapsed(offset: 1);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const black = AppColors.text;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vacancy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _canNext ? _goNext : null,
              child: const Text('Далее'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Название и профессия', style: TextStyle(color: black, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Компактный список полей (скроллится при нехватке места)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      TextFormField(
                        controller: _title,
                        focusNode: _focusTitle,
                        autofocus: true,
                        style: const TextStyle(color: black),
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: 4,
                        decoration: _ioDecoration(
                          label: 'Название объявления',
                          hint: 'Например, Требуется посудомойщик',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                        onFieldSubmitted: (_) {
                          if (_professionFN != null) FocusScope.of(context).requestFocus(_professionFN);
                        },
                      ),

                      const SizedBox(height: 12),
                      _label('Профессия'),
                      _typeaheadField(
                        controller: _profession,
                        focusNodeSetter: (fn) => _professionFN ??= fn,
                        hint: 'Посудомойщик',
                        suggestions: (q) => _api.professions(_norm(q), limit: 1000),
                        onSelected: (s) {
                          _profession.text = s.name;
                          _pickedProfessionId = s.id;
                          setState(() {});
                          if (_industryFN != null) FocusScope.of(context).requestFocus(_industryFN!);
                        },
                        onChanged: (_) {
                          _pickedProfessionId = null;
                          setState(() {});
                        },
                        onFieldFocus: (ctrl, fn) => _ensureZwsp(ctrl, fn),
                      ),

                      const SizedBox(height: 12),
                      _label('Вид деятельности компании'),
                      _typeaheadField(
                        controller: _industry,
                        focusNodeSetter: (fn) => _industryFN ??= fn,
                        hint: 'Общественное питание',
                        suggestions: (q) => _api.industries(_norm(q), limit: 200),
                        onSelected: (s) {
                          _industry.text = s.name;
                          _pickedIndustryId = s.id;
                          setState(() {});
                          FocusScope.of(context).unfocus();
                        },
                        onChanged: (_) {
                          _pickedIndustryId = null;
                          setState(() {});
                        },
                        onFieldFocus: (ctrl, fn) => _ensureZwsp(ctrl, fn),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --- helpers UI

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
      );

  InputDecoration _ioDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.gray700),
      hintStyle: TextStyle(color: AppColors.gray500),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.vacancy, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _typeaheadField({
    required TextEditingController controller,
    required void Function(FocusNode) focusNodeSetter,
    required String hint,
    required Future<List<SuggestItem>> Function(String q) suggestions,
    required void Function(SuggestItem s) onSelected,
    required void Function(String _) onChanged,
    required void Function(TextEditingController, FocusNode) onFieldFocus,
  }) {
    final maxH = min(MediaQuery.of(context).size.height * .55, 380.0);

    return TypeAheadField<SuggestItem>(
      controller: controller,
      suggestionsCallback: suggestions,
      hideOnEmpty: false,
      hideOnLoading: false,
      constraints: BoxConstraints(maxHeight: maxH),
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Ничего не найдено', style: TextStyle(color: AppColors.gray600)),
      ),
      itemBuilder: (context, s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          title: Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      onSelected: onSelected,
      builder: (context, textController, focusNode) {
        focusNodeSetter(focusNode);

        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            onFieldFocus(textController, focusNode);
          } else {
            if (textController.text == _ZWSP) {
              textController.clear();
            }
          }
        });

        return TextField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          onChanged: (v) {
            if (v.contains(_ZWSP)) {
              final cleaned = v.replaceAll(_ZWSP, '');
              if (cleaned != v) {
                textController.value = TextEditingValue(
                  text: cleaned,
                  selection: TextSelection.collapsed(offset: cleaned.length),
                );
              }
            }
            onChanged(textController.text);
          },
          decoration: _ioDecoration(label: '', hint: hint).copyWith(labelText: null),
        );
      },
    );
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) return;
    widget.draft
      ..title = _title.text.trim()
      ..profession = _norm(_profession.text)
      ..industry = _norm(_industry.text);
    widget.onNext();
  }
}
