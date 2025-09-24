import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';

class VSalaryStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VSalaryStep({super.key, required this.draft, required this.onNext});

  @override
  State<VSalaryStep> createState() => _VSalaryStepState();
}

class _VSalaryStepState extends State<VSalaryStep> {
  final _from = TextEditingController();
  final _to = TextEditingController();

  // уточнение: оклад/премия
  bool _showBaseAndBonus = false;
  final _baseFrom = TextEditingController();
  final _baseTo = TextEditingController();
  final _bonus = TextEditingController();

  String period = 'month';      // month | week | day | hour | piece | per_shift
  String tax = 'gross';         // gross | net
  String freq = 'monthly';      // daily | weekly | twice_month | monthly | per_shift | per_hour

  // общий набор форматтеров «только цифры + разделитель тысяч пробелом»
  List<TextInputFormatter> get _moneyFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        const _ThousandsSpaceFormatter(),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.draft.salaryFrom != null) _from.text = _formatMoney(widget.draft.salaryFrom!);
    if (widget.draft.salaryTo != null) _to.text = _formatMoney(widget.draft.salaryTo!);

    period = widget.draft.salaryPeriod.isNotEmpty ? widget.draft.salaryPeriod : 'month';
    tax    = widget.draft.taxMode.isNotEmpty       ? widget.draft.taxMode       : 'gross';
    freq   = widget.draft.payoutFrequency.isNotEmpty ? widget.draft.payoutFrequency : 'monthly';

    // ✅ Допустимые значения частоты выплат (freq)
    const allowedFreq = {'monthly', 'weekly', 'twice_month', 'three_times_month'};
    if (!allowedFreq.contains(freq)) {
      freq = 'monthly';
    }

    // ✅ Допустимые значения периода зарплаты (period)
    const allowedPeriod = {'month', 'per_shift', 'hour'};
    if (!allowedPeriod.contains(period)) {
      period = 'month';
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _baseFrom.dispose();
    _baseTo.dispose();
    _bonus.dispose();
    super.dispose();
  }

  // --- validation ---
  bool get _isValid {
    final hasFrom = _parseMoney(_from.text) != null;
    final hasTo   = _parseMoney(_to.text)   != null;
    return hasFrom || hasTo; // «или от, или до» обязательно
  }

  // --- helpers ---

  String _formatMoney(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      final hasNext = i < s.length - 1;
      if (hasNext && idxFromEnd % 3 == 1) b.write(' ');
    }
    return b.toString();
  }

  int? _parseMoney(String s) {
    final onlyDigits = s.replaceAll(RegExp(r'\s+'), '');
    if (onlyDigits.isEmpty) return null;
    return int.tryParse(onlyDigits);
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.gray500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.vacancy, width: 1.8),
        ),
      );

  InputDecoration _dropdownDec() => _inputDec('').copyWith(hintText: null);

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      );

  Widget _dropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.entries
          .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) { if (v != null) setState(() => onChanged(v)); },
      isExpanded: true,
      decoration: _dropdownDec(),
      style: const TextStyle(color: AppColors.text),
      iconEnabledColor: AppColors.gray700,
      borderRadius: BorderRadius.circular(12),
    );
  }

  void _saveAndNext() {
    if (!_isValid) return; // страховка
    widget.draft
      ..salaryFrom = _parseMoney(_from.text)
      ..salaryTo = _parseMoney(_to.text)
      ..salaryPeriod = period
      ..taxMode = tax
      ..payoutFrequency = freq;
    // при появлении полей под оклад/премию — добавить присвоения
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid ? _saveAndNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vacancy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Далее'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          children: [
            _label('Зарплата'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    keyboardType: TextInputType.number,
                    inputFormatters: _moneyFormatters,
                    textAlign: TextAlign.right,
                    decoration: _inputDec('от ₽'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _to,
                    keyboardType: TextInputType.number,
                    inputFormatters: _moneyFormatters,
                    textAlign: TextAlign.right,
                    decoration: _inputDec('до ₽'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isValid
                  ? 'Хорошо: диапазон или точная сумма указаны.'
                  : 'Заполните хотя бы одно поле: «от» или «до».',
              style: TextStyle(color: _isValid ? AppColors.gray600 : Colors.redAccent),
            ),

            const SizedBox(height: 12),
            _label('Период зарплаты'),
            _dropdown(
              value: period,
              items: const {
                'month': 'в месяц',
                'per_shift': 'за смену',
                'hour': 'в час',
              },
              onChanged: (v) => period = v,
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _showBaseAndBonus,
                  onChanged: (v) => setState(() => _showBaseAndBonus = v),
                  activeColor: AppColors.vacancy,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Уточнить оклад и премию',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                ),
              ],
            ),

            if (_showBaseAndBonus) ...[
              const SizedBox(height: 8),
              _label('Оклад'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _baseFrom,
                      keyboardType: TextInputType.number,
                      inputFormatters: _moneyFormatters,
                      textAlign: TextAlign.right,
                      decoration: _inputDec('от ₽'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _baseTo,
                      keyboardType: TextInputType.number,
                      inputFormatters: _moneyFormatters,
                      textAlign: TextAlign.right,
                      decoration: _inputDec('до ₽'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Сумма, которую кандидат получит независимо от результатов работы.',
                style: TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              _label('Премия'),
              TextField(
                controller: _bonus,
                decoration: _inputDec('Например, 5% от продаж в месяц'),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),
            _label('Зарплата указана'),
            RadioListTile<String>(
              value: 'gross',
              groupValue: tax,
              onChanged: (v) => setState(() => tax = v!),
              title: const Text('До вычета налогов'),
              activeColor: AppColors.vacancy,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'net',
              groupValue: tax,
              onChanged: (v) => setState(() => tax = v!),
              title: const Text('На руки'),
              activeColor: AppColors.vacancy,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),
            _label('Частота выплат'),
            _dropdown(
              value: freq,
              items: const {
                'twice_month': 'Дважды в месяц',
                'weekly': 'Раз в неделю',
                'three_times_month': 'Три раза в месяц',
                'monthly': 'Раз в месяц',
              },
              onChanged: (v) => freq = v,
            ),
          ],
        ),
      ),
    );
  }
}

/// Форматтер, который добавляет пробелы как разделитель тысяч
class _ThousandsSpaceFormatter extends TextInputFormatter {
  const _ThousandsSpaceFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final chars = digits.split('');
    final buf = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      final idxFromEnd = chars.length - i;
      buf.write(chars[i]);
      final hasNext = i < chars.length - 1;
      if (hasNext && idxFromEnd % 3 == 1) buf.write(' ');
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
