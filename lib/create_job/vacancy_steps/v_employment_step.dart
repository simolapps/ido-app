import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';

class VEmploymentStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VEmploymentStep({super.key, required this.draft, required this.onNext});

  @override
  State<VEmploymentStep> createState() => _VEmploymentStepState();
}

class _VEmploymentStepState extends State<VEmploymentStep> {
  // Тип графика: rotational | shift | flexible | fixed
  String schedule = 'rotational';

  // Вахта
  int? rotation;
  final List<int> _rotations = const [10, 15, 20, 21, 25, 30, 33, 35, 45, 50, 60, 90];

  // Сменный
  final List<String> _shiftPatterns = const [
    '1 / 2','1 / 3','2 / 1','2 / 2','3 / 1','3 / 2','3 / 3',
    '4 / 2','4 / 3','5 / 2','6 / 1','7 / 0',
  ];
  String? shiftPattern;
  final List<String> _shiftTagsAll = const [
    'Утро','День','Вечер','Ночь','По выходным','Плавающие выходные',
  ];
  final Set<String> shiftTags = {};

  // Гибкий
  final List<String> _flexDays = const ['1–2 дня','3–4 дня','5 дней','6–7 дней'];
  String? flexDays;

  // Фиксированный
  String? fixedPattern;

  @override
  void initState() {
    super.initState();
    // начальные значения из драфта
    schedule = widget.draft.schedule.isNotEmpty ? widget.draft.schedule : schedule;
    rotation = widget.draft.rotationLengthDays;
  }

  // ---- VALIDATION ----
  bool get _isValid {
    switch (schedule) {
      case 'rotational': return rotation != null;
      case 'shift':      return shiftPattern != null;           // shiftTags опционально
      case 'flexible':   return flexDays != null;
      case 'fixed':      return fixedPattern != null;
      default:           return false;
    }
  }

  String? get _errorText {
    if (_isValid) return null;
    switch (schedule) {
      case 'rotational': return 'Выберите длительность вахты';
      case 'shift':      return 'Выберите схему смен';
      case 'flexible':   return 'Укажите кол-во рабочих дней в неделю';
      case 'fixed':      return 'Выберите режим работы';
    }
    return null;
  }

  // ---------- UI helpers

  Widget _groupTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: AppColors.text,
      ),
    ),
  );

  Widget _segment(String label, String value) {
    final selected = schedule == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.vacancy,
      backgroundColor: AppColors.gray100,
      checkmarkColor: Colors.white,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => setState(() {
        schedule = value;
        // при смене типа графика очищаем режимы других типов
        rotation = null;
        shiftPattern = null;
        shiftTags.clear();
        flexDays = null;
        fixedPattern = null;
      }),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.vacancy,
      backgroundColor: AppColors.gray100,
      checkmarkColor: Colors.white,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => onTap(),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.vacancy,
      backgroundColor: AppColors.gray100,
      checkmarkColor: Colors.white,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => onTap(),
    );
  }

  // ---------- Blocks

  Widget _rotationalBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupTitle('Длительность вахты'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _rotations
              .map((d) => _choiceChip(
                    label: '$d',
                    selected: rotation == d,
                    onTap: () => setState(() => rotation = d),
                  ))
              .toList(),
        ),
        if (_errorText != null && schedule == 'rotational')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  Widget _shiftBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupTitle('Смены'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _shiftPatterns
              .map((p) => _choiceChip(
                    label: p,
                    selected: shiftPattern == p,
                    onTap: () => setState(() => shiftPattern = p),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _shiftTagsAll
              .map((t) => _filterChip(
                    label: t,
                    selected: shiftTags.contains(t),
                    onTap: () => setState(() {
                      if (shiftTags.contains(t)) {
                        shiftTags.remove(t);
                      } else {
                        shiftTags.add(t);
                      }
                    }),
                  ))
              .toList(),
        ),
        if (_errorText != null && schedule == 'shift')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  Widget _flexibleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupTitle('Количество рабочих дней в неделю'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _flexDays
              .map((d) => _choiceChip(
                    label: d,
                    selected: flexDays == d,
                    onTap: () => setState(() => flexDays = d),
                  ))
              .toList(),
        ),
        if (_errorText != null && schedule == 'flexible')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  Widget _fixedBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupTitle('Режим работы'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _shiftPatterns
              .map((p) => _choiceChip(
                    label: p,
                    selected: fixedPattern == p,
                    onTap: () => setState(() => fixedPattern = p),
                  ))
              .toList(),
        ),
        if (_errorText != null && schedule == 'fixed')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  // ---------- Save

  void _saveAndNext() {
    // защита на случай внешнего вызова
    if (!_isValid) {
      setState(() {}); // чтобы показать подсказку
      return;
    }

    widget.draft
      ..schedule = schedule
      ..rotationLengthDays = (schedule == 'rotational') ? rotation : null;

    // Остальное оставляем как опциональные UI-поля (модель их пока не содержит).
    // При необходимости добавим в VacancyDraft и здесь проставим:
    // widget.draft.shiftPattern = shiftPattern;
    // widget.draft.shiftTags = shiftTags.toList();
    // widget.draft.flexDaysPerWeek = flexDays;
    // widget.draft.fixedPattern = fixedPattern;

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
            const Text(
              'График',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text),
            ),
            const SizedBox(height: 8),

            // Селектор типа графика
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _segment('Вахта', 'rotational'),
                _segment('Сменный', 'shift'),
                _segment('Гибкий', 'flexible'),
                _segment('Фиксированный', 'fixed'),
              ],
            ),

            const SizedBox(height: 16),

            if (schedule == 'rotational') _rotationalBlock(),
            if (schedule == 'shift') _shiftBlock(),
            if (schedule == 'flexible') _flexibleBlock(),
            if (schedule == 'fixed') _fixedBlock(),
          ],
        ),
      ),
    );
  }
}
