// === file: lib/pages/create_job/create_job_wizard.dart
import 'package:flutter/material.dart';
import '../../api/wizard_api.dart';
import '../../models/job_draft.dart';
import '../../models/step_config.dart';
import '../../models/wizard_flow.dart' as wf
    show WizardFlow; // ← только WizardFlow
import '../../theme/app_colors.dart'; // ← путь поправлен

import 'steps/category_step.dart';
import 'steps/subcategories_step.dart';
import 'steps/title_step.dart';
import 'steps/details_step.dart';
import 'steps/budget_step.dart';
import 'steps/date_step.dart';
import 'steps/location_step.dart';
import 'steps/preview_step.dart';
import 'steps/dynamic_step_page.dart';

class CreateJobWizard extends StatefulWidget {
  const CreateJobWizard({super.key});
  @override
  State<CreateJobWizard> createState() => _CreateJobWizardState();
}

class _CreateJobWizardState extends State<CreateJobWizard> {
  final JobDraft draft = JobDraft();
  final PageController _pc = PageController();
  final _api = WizardApi('https://idoapi.tw1.ru');

  late List<StepConfig> _flow;
  int _step = 0;
  bool _loadingFlow = false;

  bool _savingDraft = false;
  bool _publishing = false;
  bool _deleting = false;

  AddressConfig? _addressCfg;

  @override
  void initState() {
    super.initState();
    _flow = _makeFullFlow(const []); // стартовый флоу без «середины»
  }

  // ---------- Flow

  List<StepConfig> _makeFullFlow(List<StepConfig> middle) {
    const head = [
      StepConfig(kind: StepKind.category, title: 'Категория'),
      StepConfig(kind: StepKind.subcategory, title: 'Подкатегория'),
      StepConfig(kind: StepKind.title, title: 'Как назвать задание?'),
    ];
    const tail = [
      StepConfig(kind: StepKind.address, title: 'Место оказания услуги'),
      StepConfig(
          kind: StepKind.date, title: 'Когда нужно приступить к работе?'),
      StepConfig(kind: StepKind.details, title: 'Уточните детали'),
      StepConfig(kind: StepKind.budget, title: 'Бюджет'),
      StepConfig(kind: StepKind.preview, title: 'Предпросмотр'),
    ];
    return [...head, ...middle, ...tail];
  }

  Future<void> _loadFlowForSubcategory() async {
    if (draft.subcategoryId == null) return;
    setState(() => _loadingFlow = true);
    try {
      final wf.WizardFlow data =
          await _api.fetchFlowBySubcategoryId(draft.subcategoryId!);

      final middle = data.steps
          .map((j) => StepConfig(
                kind: StepKind.customQ,
                title: j['title'] ?? 'Вопрос',
                props: {'json': j},
              ))
          .toList();

      _addressCfg = data.address; // AddressConfig из step_config.dart

      setState(() {
        _flow = _makeFullFlow(middle);
      });
    } catch (e) {
      _addressCfg = AddressConfig.fromJson(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить шаги: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFlow = false);
    }
  }

  // ---------- Навигация шагов

  void _next() {
    if (_step < _flow.length - 1) {
      setState(() => _step++);
      _pc.animateToPage(_step,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _pc.animateToPage(_step,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _confirmExit(); // с первого шага — спросить, что делать
    }
  }

  Future<bool> _onWillPop() async {
    if (_step > 0) {
      _prev();
      return false;
    }
    _confirmExit();
    return false;
  }

  // ---------- UI шагов

  Widget _buildStep(StepConfig sc) {
    switch (sc.kind) {
      case StepKind.category:
        return CategoryStep(
          draft: draft,
          onNext: () {
            draft.subcategoryId = null;
            draft.subcategoryName = null;
            draft.subcategorySlug = null;
            _next();
          },
        );

      case StepKind.subcategory:
        return SubcategoriesStep(
          draft: draft,
          onNext: () async {
            await _loadFlowForSubcategory();
            _next();
          },
        );

      case StepKind.title:
        return TitleStep(draft: draft, onNext: _next);

      case StepKind.customQ:
        {
          final json = sc.props?['json'] as Map<String, dynamic>;
          return DynamicStepPage.fromJson(
              draft: draft, json: json, onNext: _next);
        }

      case StepKind.address:
        return LocationStep(draft: draft, onNext: _next, config: _addressCfg);

      case StepKind.date:
        return DateStep(draft: draft, onNext: _next);

      case StepKind.details:
        return DetailsStep(draft: draft, onNext: _next);

      case StepKind.budget:
        return BudgetStep(draft: draft, onNext: _next);

      case StepKind.preview:
        return PreviewStep(
          draft: draft,
          onEdit: _jumpToStepBySection,
          embedded: true, // ← важно!
        );
    }
  }

  // ---------- Переход к нужной секции из превью

  void _jumpToStepBySection(PreviewSection s) {
    int? index;
    switch (s) {
      case PreviewSection.title:
        index = _flow.indexWhere((e) => e.kind == StepKind.title);
        break;
      case PreviewSection.details:
        index = _flow.indexWhere((e) => e.kind == StepKind.details);
        break;
      case PreviewSection.budget:
        index = _flow.indexWhere((e) => e.kind == StepKind.budget);
        break;
      case PreviewSection.payment:
        index = _flow.indexWhere(
            (e) => e.kind == StepKind.budget); // выбор оплаты на шаге бюджета
        break;
      case PreviewSection.date:
        index = _flow.indexWhere((e) => e.kind == StepKind.date);
        break;
      case PreviewSection.address:
        index = _flow.indexWhere((e) => e.kind == StepKind.address);
        break;
      case PreviewSection.dynamicAnswers:
        index = _flow.indexWhere(
            (e) => e.kind == StepKind.customQ); // первый динамический
        break;
    }
    if (index == null || index < 0) return;
    setState(() => _step = index!);
    _pc.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  // ---------- Диалог выхода

  bool get _hasAnyInput {
    return (draft.title.isNotEmpty) ||
        (draft.description.isNotEmpty) ||
        (draft.privateNote.isNotEmpty) ||
        (draft.categoryId != null) ||
        (draft.subcategoryId != null) ||
        (draft.mediaPaths.isNotEmpty) ||
        (draft.photoUrls.isNotEmpty) ||
        (draft.exactDateTime != null) ||
        (draft.periodFrom != null) ||
        (draft.periodTo != null) ||
        (draft.address.isNotEmpty) ||
        (draft.dynamicAnswers.isNotEmpty);
  }

  void _confirmExit() async {
    if (!_hasAnyInput) {
      if (mounted) Navigator.pop(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Выйти из создания задания?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 8),
                Text(
                  'Вы можете сохранить черновик и вернуться позже или удалить текущие изменения.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text.withOpacity(.7)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveDraft();
                      if (mounted) Navigator.pop(context); // выйти из мастера
                    },
                    child: _savingDraft
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Сохранить в черновики',
                            style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.danger.withOpacity(.6)),
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _deleteDraft();
                      if (mounted) Navigator.pop(context);
                    },
                    child: _deleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Удалить и выйти'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Продолжить заполнять',
                      style: TextStyle(color: AppColors.freelance)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Сохранение / Публикация (через WizardApi)

  Future<void> _saveDraft() async {
    if (_savingDraft) return;
    setState(() => _savingDraft = true);
    try {
      await _api.saveDraft(draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Черновик сохранён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения черновика: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await _api.publishJob(draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задание опубликовано')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка публикации: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _deleteDraft() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await _api.deleteDraft(draft);
      _resetDraft();
    } catch (_) {
      _resetDraft();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _resetDraft() {
    draft
      ..title = ''
      ..description = ''
      ..privateNote = ''
      ..mediaPaths.clear()
      ..photoUrls.clear()
      ..priceType = 'fixed'
      ..budgetPreset = null
      ..customBudget = null
      ..paymentType = 'direct'
      ..exactDateTime = null
      ..periodFrom = null
      ..periodTo = null
      ..isRemote = true
      ..address = ''
      ..addressPoints.clear()
      ..placeMode = 'any'
      ..categoryId = null
      ..categoryName = null
      ..categorySlug = null
      ..subcategoryId = null
      ..subcategoryName = null
      ..subcategorySlug = null
      ..dynamicAnswers.clear();
  }

  // ---------- Build

  @override
  Widget build(BuildContext context) {
    final titles = _flow.map((e) => e.title).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0.5,
          leading:
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prev),
          title: Text(
            titles[_step],
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w600),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _flow.length,
              minHeight: 3,
              color: AppColors.freelance,
              backgroundColor: AppColors.freelance.withOpacity(0.12),
            ),
          ),
          actions: [
            if (_loadingFlow)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            if (!_loadingFlow)
              TextButton(
                onPressed: _confirmExit,
                child: const Text('Отмена',
                    style: TextStyle(color: AppColors.freelance)),
              ),
          ],
        ),
        body: PageView.builder(
          controller: _pc,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _flow.length,
          itemBuilder: (_, i) => _buildStep(_flow[i]),
        ),
      ),
    );
  }
}
