import 'package:flutter/material.dart';
import '../../api/wizard_api.dart';
import '../../models/bid_template.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({
    super.key,
    required this.api,
    required this.masterId,
    this.pickMode = false, // ⟵ режим выбора
  });

  final WizardApi api;
  final int masterId;
  final bool pickMode;

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  List<BidTemplate> _items = [];
  bool _loading = true;
  String? _error;
  

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=>_loading=true);
    try {
      _items = await widget.api.templatesList(masterId: widget.masterId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(()=>_loading=false);
    }
  }

  Future<void> _addOrEdit([BidTemplate? t]) async {
    if (widget.pickMode) return; // в режиме выбора не редактируем
    final res = await showDialog<_TemplateFormResult>(
      context: context,
      builder: (_) => _TemplateDialog(initial: t),
    );
    if (res == null) return;

    try {
      if (t == null) {
        final id = await widget.api.templateCreate(BidTemplate(
          id: 0,
          masterId: widget.masterId,
          title: res.title,
          body: res.body,
          priceSuggest: res.price,
          isDefault: res.isDefault,
        ));
        _items.insert(0, BidTemplate(
          id: id, masterId: widget.masterId,
          title: res.title, body: res.body,
          priceSuggest: res.price, isDefault: res.isDefault,
        ));
      } else {
       await widget.api.templateUpdate(
  id: t.id,
  masterId: widget.masterId,        // ← добавьте это
  title: res.title,
  body: res.body,
  priceSuggest: res.price,
  isDefault: res.isDefault,
);

        final i = _items.indexWhere((x)=>x.id==t.id);
        if (i>=0) _items[i] = BidTemplate(
          id: t.id, masterId: t.masterId,
          title: res.title, body: res.body,
          priceSuggest: res.price, isDefault: res.isDefault,
        );
        if (res.isDefault) {
          for (var j=0;j<_items.length;j++) {
            if (_items[j].id != t.id) {
              _items[j] = BidTemplate(
                id: _items[j].id,
                masterId: _items[j].masterId,
                title: _items[j].title,
                body: _items[j].body,
                priceSuggest: _items[j].priceSuggest,
                isDefault: false,
              );
            }
          }
        }
      }
      setState((){});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _delete(BidTemplate t) async {
    if (widget.pickMode) return; // в режиме выбора удаление не нужно
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: Text(t.title),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Отмена')),
          TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
     await widget.api.templateDelete(
  id: t.id,
  masterId: widget.masterId,        // ← добавьте это
);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Выбрать шаблон' : 'Шаблоны откликов'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Не удалось загрузить: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = _items[i];
                      return Dismissible(
                        key: ValueKey(t.id),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: widget.pickMode ? DismissDirection.none : DismissDirection.endToStart,
                        confirmDismiss: (_) async { await _delete(t); return false; },
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            onTap: widget.pickMode ? () => Navigator.pop(context, t) : () => _addOrEdit(t),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                if (t.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text('По умолчанию',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (t.priceSuggest != null)
                                  Text('Обычно прошу: ${_fmt(t.priceSuggest!)} ₽'),
                                const SizedBox(height: 4),
                                Text(t.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                                if (widget.pickMode) const SizedBox(height: 8),
                                if (widget.pickMode)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Выбрать'),
                                      onPressed: () => Navigator.pop(context, t),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: widget.pickMode
          ? null
          : FloatingActionButton.extended(
              onPressed: ()=>_addOrEdit(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
    );
  }

  static String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i=0;i<s.length;i++){
      final pos = s.length - i - 1;
      b.write(s[i]);
      if (pos % 3 == 0 && i != s.length-1) b.write(' ');
    }
    return b.toString();
  }
}

class _TemplateFormResult {
  final String title;
  final String body;
  final int? price;
  final bool isDefault;
  _TemplateFormResult(this.title, this.body, this.price, this.isDefault);
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.initial});
  final BidTemplate? initial;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  final _title = TextEditingController();
  final _body  = TextEditingController();
  final _price = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _title.text = i.title;
      _body.text  = i.body;
      if (i.priceSuggest != null) _price.text = i.priceSuggest.toString();
      _isDefault = i.isDefault;
    }
  }

  @override
  void dispose() {
    _title.dispose(); _body.dispose(); _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Новый шаблон' : 'Редактировать шаблон'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Текст отклика'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: const InputDecoration(labelText: 'Обычно прошу (₽), опционально'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (v)=>setState(()=>_isDefault=v??false),
              title: const Text('Сделать по умолчанию'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Отмена')),
        TextButton(
          onPressed: (){
            final t = _title.text.trim();
            final b = _body.text.trim();
            if (t.isEmpty || b.isEmpty) return;
            final p = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));
            Navigator.pop(context, _TemplateFormResult(t,b,p,_isDefault));
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
