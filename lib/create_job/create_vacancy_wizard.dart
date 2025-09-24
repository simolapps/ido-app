import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/vacancy_draft.dart';

import 'vacancy_steps/v_title_profession_step.dart';
import 'vacancy_steps/v_description_step.dart';
import 'vacancy_steps/v_employment_step.dart';
import 'vacancy_steps/v_salary_step.dart';
import 'vacancy_steps/v_locations_step.dart';
import 'vacancy_steps/v_contacts_step.dart';
import 'vacancy_steps/v_preview_step.dart';

class CreateVacancyWizard extends StatefulWidget {
  const CreateVacancyWizard({super.key});
  @override
  State<CreateVacancyWizard> createState() => _CreateVacancyWizardState();
}

class _CreateVacancyWizardState extends State<CreateVacancyWizard> {
  final VacancyDraft draft = VacancyDraft();
  final PageController _pc = PageController();
  int _step = 0;

  final _titles = const [
    'Название и профессия', // 0
    'Описание',             // 1 (новая страница)
    'График работы',        // 2
    'Зарплата',             // 3
    'География',            // 4
    'Контакты',             // 5
    'Предпросмотр',         // 6
  ];

  void _next() {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
      _pc.animateToPage(_step, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _pc.animateToPage(_step, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: .5,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prev),
        title: Text(_titles[_step], style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _titles.length,
            minHeight: 3,
            color: AppColors.vacancy,
            backgroundColor: AppColors.vacancy.withOpacity(.12),
          ),
        ),
      ),
      body: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          VTitleProfessionStep(draft: draft, onNext: _next), // 0
          VDescriptionStep(draft: draft, onNext: _next),     // 1
          VEmploymentStep(draft: draft, onNext: _next),      // 2
          VSalaryStep(draft: draft, onNext: _next),          // 3
          VLocationsStep(draft: draft, onNext: _next),       // 4
          VContactsStep(draft: draft, onNext: _next),        // 5
          VPreviewStep(
            draft: draft,
            onEdit: (i) {
              // Маппинг индексов в превью:
              // 0 — Название/Профессия, 1 — Описание,
              // 2 — График, 3 — Зарплата, 4 — География, 5 — Контакты.
              setState(() => _step = i);
              _pc.animateToPage(i, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
            },
          ),                                                 // 6
        ],
      ),
    );
  }
}
