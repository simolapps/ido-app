import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';

const kDescMinLen = 20;
const kDescMaxLen = 4000;

class VDescriptionStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VDescriptionStep({super.key, required this.draft, required this.onNext});

  @override
  State<VDescriptionStep> createState() => _VDescriptionStepState();
}

class _VDescriptionStepState extends State<VDescriptionStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _desc;
  final _focusDesc = FocusNode();

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.draft.description);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusDesc.requestFocus();
    });
  }

  @override
  void dispose() {
    _desc.dispose();
    _focusDesc.dispose();
    super.dispose();
  }

  bool get _canNext => (_desc.text.trim().length >= kDescMinLen);

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
              const Text('Описание вакансии и компании',
                  style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _desc,
                    focusNode: _focusDesc,
                    maxLines: null,
                    minLines: 12,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => setState(() {}),
                    maxLength: kDescMaxLen,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Опишите обязанности, условия, требования';
                      if (t.length < kDescMinLen) return 'Добавьте ещё ${kDescMinLen - t.length} символ(ов)';
                      return null;
                    },
                    decoration: _ioDecoration(
                      label: 'Описание',
                      hint: 'Обязанности, условия, график, зарплата, требования и пару слов о компании',
                    ).copyWith(
                      helperText: 'Минимум $kDescMinLen символов. Детали повышают качество откликов.',
                      counterText: '${_desc.text.length}/$kDescMaxLen',
                    ),
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

  void _goNext() {
    if (!_formKey.currentState!.validate()) return;
    widget.draft.description = _desc.text.trim();
    widget.onNext();
  }
}
