// === file: lib/pages/create_job/steps/date_step.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- делегаты
import '../../../models/job_draft.dart';
import '../../../theme/app_colors.dart';

class DateStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  const DateStep({super.key, required this.draft, required this.onNext});

  @override
  State<DateStep> createState() => _DateStepState();
}

class _DateStepState extends State<DateStep> {
  bool exact = true;
  DateTime? dateTime;
  DateTime? from;
  DateTime? to;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: AppColors.text,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    );
    final subStyle = TextStyle(
      color: AppColors.text.withOpacity(.7),
      fontSize: 15,
    );
    const cellText = TextStyle(color: AppColors.text, fontSize: 16);

    final canNext = exact
        ? dateTime != null
        : (from != null && to != null && !to!.isBefore(from!));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Когда нужно приступить к работе?', style: titleStyle),
              const SizedBox(height: 6),
              Text(
                'Укажите точную дату или период, когда нужно приступить к работе.',
                style: subStyle,
              ),
              const SizedBox(height: 16),

              _FullWidthSwitch(
                leftText: 'Точная дата',
                rightText: 'Период',
                value: exact,
                onChanged: (v) => setState(() => exact = v),
              ),

              const SizedBox(height: 16),
              if (exact) ...[
                _Cell(
                  icon: Icons.calendar_today_outlined,
                  text: dateTime == null ? 'Дата и время' : _fmtDT(dateTime!),
                  textStyle: cellText,
                  onTap: () async {
                    final picked = await _pickCupertino(
                      context,
                      initial: dateTime ?? DateTime.now(),
                      title: 'Начать работу',
                    );
                    if (picked != null) setState(() => dateTime = picked);
                  },
                ),
              ] else ...[
                _Cell(
                  icon: Icons.calendar_month_outlined,
                  text: from == null ? 'Дата и время начала' : _fmtDT(from!),
                  textStyle: cellText,
                  onTap: () async {
                    final picked = await _pickCupertino(
                      context,
                      initial: from ?? DateTime.now(),
                      title: 'Начать работу',
                    );
                    if (picked != null) setState(() => from = picked);
                  },
                ),
                const SizedBox(height: 8),
                _Cell(
                  icon: Icons.calendar_month_outlined,
                  text: to == null ? 'Дата и время завершения' : _fmtDT(to!),
                  textStyle: cellText,
                  onTap: () async {
                    final init = to ??
                        (from != null
                            ? from!.add(const Duration(hours: 1))
                            : DateTime.now().add(const Duration(hours: 1)));
                    final picked = await _pickCupertino(
                      context,
                      initial: init,
                      title: 'Завершить к',
                    );
                    if (picked != null) setState(() => to = picked);
                  },
                ),
                if (from != null && to != null && to!.isBefore(from!))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Дата завершения не может быть раньше начала.',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.freelance,
                  ),
                  onPressed: canNext
                      ? () {
                          if (exact) {
                            widget.draft.exactDateTime = dateTime;
                            widget.draft.periodFrom = null;
                            widget.draft.periodTo = null;
                          } else {
                            widget.draft.exactDateTime = null;
                            widget.draft.periodFrom = from;
                            widget.draft.periodTo = to;
                          }
                          widget.onNext();
                        }
                      : null,
                  child: const Text('Далее', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDT(DateTime dt) {
    final d = _fmtD(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d, $h:$m';
  }

  String _fmtD(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  /// Купертиновский пикер: светлая тема + русская локаль, делегаты внутри
  /// Купертиновский пикер: светлая тема + русская локаль
  Future<DateTime?> _pickCupertino(
    BuildContext context, {
    required DateTime initial,
    required String title,
  }) async {
    final min = DateTime.now();
    final safeInitial = initial.isBefore(min) ? min : initial;
    var temp = safeInitial;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) {
        return Material(
          color: Colors.black.withOpacity(.2),
          child: SafeArea(
            top: false,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Шапка
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE9E9EF))),
                    ),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          onPressed: () => Navigator.of(ctx).pop(temp),
                          child: const Text(
                            'Готово',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.freelance,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Сам пикер
                  Expanded(
                    child: Localizations.override(
                      context: ctx,
                      locale: const Locale('ru', 'RU'),
                      delegates: GlobalMaterialLocalizations.delegates,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness: Brightness.light,
                          primaryColor: AppColors.freelance,
                          textTheme: const CupertinoTextThemeData(
                            pickerTextStyle: TextStyle(
                              color: AppColors.text,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.dateAndTime,
                          minimumDate: min,
                          maximumDate: DateTime(min.year + 2),
                          initialDateTime: safeInitial,
                          use24hFormat: true,
                          onDateTimeChanged: (v) => temp = v,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

/// ===== UI helpers

class _Cell extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle textStyle;
  final VoidCallback onTap;

  const _Cell({
    required this.icon,
    required this.text,
    required this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.freelance),
        title: Text(text, style: textStyle),
        trailing: Icon(Icons.chevron_right, color: Colors.black.withOpacity(.2)),
        onTap: onTap,
      ),
    );
  }
}

/// Полноширинный двухпозиционный переключатель
class _FullWidthSwitch extends StatelessWidget {
  final String leftText;
  final String rightText;
  final bool value; // true = left, false = right
  final ValueChanged<bool> onChanged;
  const _FullWidthSwitch({
    required this.leftText,
    required this.rightText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.freelance.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.freelance.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          _seg(btnText: leftText, selected: value, onTap: () => onChanged(true)),
          _seg(btnText: rightText, selected: !value, onTap: () => onChanged(false)),
        ],
      ),
    );
  }

  Expanded _seg({required String btnText, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.freelance : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            btnText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.freelance,
            ),
          ),
        ),
      ),
    );
  }
}
