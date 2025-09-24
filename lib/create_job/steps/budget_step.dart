// === file: lib/pages/create_job/steps/budget_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ido/theme/app_colors.dart';
import '../../../models/job_draft.dart';

class BudgetStep extends StatefulWidget {
  final JobDraft draft;
  final VoidCallback onNext;
  const BudgetStep({super.key, required this.draft, required this.onNext});

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  final _custom = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Префил из драфта (если возвращаемся назад)
    if (widget.draft.customBudget != null && widget.draft.customBudget! > 0) {
      _custom.text = widget.draft.customBudget!.toString();
    }

    // Синхронизация с драфтом по мере ввода
    _custom.addListener(() {
      final v = _custom.text.trim();
      final n = int.tryParse(v);
      if (n != null && n > 0) {
        widget.draft.priceType = 'fixed';
        widget.draft.budgetPreset = null;
        widget.draft.customBudget = n;
      } else {
        widget.draft.customBudget = null;
      }
      setState(() {}); // чтобы обновлялась доступность кнопки "Далее"
    });

    // Автооткрытие клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focus);
    });
  }

  @override
  void dispose() {
    _custom.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canNext {
    final v = int.tryParse(_custom.text.trim());
    return v != null && v > 0;
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    final hintStyle = TextStyle(
      color: AppColors.text.withOpacity(.45),
      fontSize: 15,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Укажите желаемый бюджет', style: titleStyle),
              const SizedBox(height: 12),

              TextField(
                controller: _custom,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                // ⬇️ убрали const
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: AppColors.freelance,
                style: const TextStyle(color: AppColors.text, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Сумма, ₽',
                  labelStyle: TextStyle(color: AppColors.text.withOpacity(.7)),
                  hintText: 'Например: 5000',
                  hintStyle: hintStyle,
                  prefixText: '₽ ',
                  prefixStyle: const TextStyle(
                    color: AppColors.freelance,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.freelance.withOpacity(.18)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.freelance, width: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                _canNext ? 'Сумма указана' : 'Укажите сумму, чтобы продолжить',
                style: TextStyle(
                  color: _canNext ? AppColors.text.withOpacity(.55) : AppColors.freelance,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => states.contains(MaterialState.disabled)
                            ? AppColors.freelance.withOpacity(.45)
                            : AppColors.freelance,
                      ),
                      foregroundColor: const MaterialStatePropertyAll<Color>(Colors.white),
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    onPressed: _canNext
                        ? () {
                            // Значение уже записано в draft из listener'а
                            widget.onNext();
                          }
                        : null,
                    child: const Text('Далее'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
