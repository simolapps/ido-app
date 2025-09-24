import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../../../models/vacancy_draft.dart';

class VContactsStep extends StatefulWidget {
  final VacancyDraft draft;
  final VoidCallback onNext;
  const VContactsStep({super.key, required this.draft, required this.onNext});

  @override
  State<VContactsStep> createState() => _VContactsStepState();
}

class _VContactsStepState extends State<VContactsStep> {
  // API
  static const _sendCodeUrl    = 'https://simolapps.tw1.ru/api/send_code.php';
  static const _verifyCodeUrl  = 'https://simolapps.tw1.ru/api/verify_code.php';
  static const _getUserPhone   = 'https://simolapps.tw1.ru/api/get_user_phone.php';

  // из аккаунта
  String _accountPhone = '';
  int? _accountId;
  bool _loadingAccount = true;

  // «другой номер»
  bool _useOtherPhone = false;
  final _otherPhone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _verified = false;
  bool _sending = false;
  bool _verifying = false;
  final _otherPhoneF = FocusNode();
  final _codeF = FocusNode();

  @override
  void initState() {
    super.initState();
    _bootstrapFromPrefsAndApi();

    _otherPhone.addListener(() {
      if (_codeSent || _verified) {
        setState(() {
          _codeSent = false;
          _verified = false;
        });
      }
      setState(() {});
    });
    _code.addListener(() => setState(() {}));
  }

  Future<void> _bootstrapFromPrefsAndApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      String phoneFromDraft = widget.draft.phone;

      if (id == null) {
        setState(() {
          _accountId = null;
          _accountPhone = phoneFromDraft;
          _loadingAccount = false;
        });
        return;
      }

      // тянем телефон по user_id
      String? serverPhone;
      try {
        final r = await http.post(
          Uri.parse(_getUserPhone),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': id}),
        );
        if (r.statusCode >= 200 && r.statusCode < 300) {
          final data = jsonDecode(r.body);
          if (data is Map && data['success'] == true && (data['phone'] ?? '').toString().isNotEmpty) {
            serverPhone = data['phone'].toString();
          }
        }
      } catch (_) {}

      setState(() {
        _accountId = id;
        _accountPhone = (serverPhone?.isNotEmpty == true)
            ? serverPhone!
            : (phoneFromDraft.isNotEmpty ? phoneFromDraft : '');
        _loadingAccount = false;
      });
    } catch (_) {
      setState(() {
        _accountId = null;
        _accountPhone = widget.draft.phone;
        _loadingAccount = false;
      });
    }
  }

  @override
  void dispose() {
    _otherPhone.dispose();
    _code.dispose();
    _otherPhoneF.dispose();
    _codeF.dispose();
    super.dispose();
  }

  // ===== validation =====
  bool get _isDigitsOnlyValid {
    final n = _otherPhone.text.replaceAll(RegExp(r'\D'), '');
    return n.length >= 10 && n.length <= 15;
  }

  bool get _canProceed {
    if (_useOtherPhone) return _verified && _isDigitsOnlyValid;
    return _accountPhone.trim().isNotEmpty; // можно идти с номером аккаунта
  }

  // ===== API: как в RegisterPage =====
  Future<bool> _sendCode() async {
    try {
      final r = await http.post(
        Uri.parse(_sendCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _otherPhone.text}),
      );
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyCode() async {
    try {
      final r = await http.post(
        Uri.parse(_verifyCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _otherPhone.text, 'code': _code.text}),
      );
      final data = jsonDecode(r.body);
      return data is Map && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ===== UI helpers =====
  InputDecoration _inputDec(String label, String? hint) => InputDecoration(
        labelText: label.isEmpty ? null : label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.gray700),
        hintStyle: TextStyle(color: AppColors.gray500),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.vacancy, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
      );

  Widget _kvRow(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: AppColors.gray700)),
          const SizedBox(width: 12),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      );

  void _onNext() {
    final chosen = _useOtherPhone ? _otherPhone.text : _accountPhone;
    widget.draft.phone = chosen; // сохраняем в драфт выбранный номер
    widget.onNext();
  }

  // ===== render =====
  @override
  Widget build(BuildContext context) {
    final accountIdText = _accountId != null ? '#$_accountId' : '—';

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProceed ? _onNext : null,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _label('Аккаунт'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: _loadingAccount
                  ? const Row(
                      children: [
                        SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Загружаем данные аккаунта…'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kvRow('ID аккаунта', accountIdText),
                        const SizedBox(height: 6),
                        _kvRow('Номер аккаунта', _accountPhone.isNotEmpty ? _accountPhone : '—'),
                      ],
                    ),
            ),

            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _useOtherPhone,
              onChanged: (v) {
                setState(() {
                  _useOtherPhone = v;
                  _codeSent = false;
                  _verified = false;
                  _otherPhone.clear();
                  _code.clear();
                });
                if (v) {
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) _otherPhoneF.requestFocus();
                  });
                }
              },
              activeColor: AppColors.vacancy,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Использовать другой номер',
                style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Новый номер нужно подтвердить кодом, как при регистрации.',
                style: TextStyle(color: AppColors.gray600),
              ),
            ),

            if (_useOtherPhone) ...[
              const SizedBox(height: 8),
              _label('Новый номер'),
              TextField(
                controller: _otherPhone,
                focusNode: _otherPhoneF,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: _inputDec('', 'Введите номер (только цифры)'),
              ),
              if (!_isDigitsOnlyValid && _otherPhone.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Номер должен содержать от 10 до 15 цифр.',
                      style: TextStyle(color: Colors.redAccent)),
                ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_isDigitsOnlyValid && !_sending)
                          ? () async {
                              setState(() => _sending = true);
                              final ok = await _sendCode();
                              setState(() {
                                _sending = false;
                                _codeSent = ok;
                              });
                              if (!ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Не удалось отправить код. Попробуйте позже.')),
                                );
                              } else if (ok) {
                                _codeF.requestFocus();
                              }
                            }
                          : null,
                      icon: _sending
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sms_outlined),
                      label: const Text('Отправить код'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.vacancy),
                        foregroundColor: AppColors.vacancy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Код придёт в WhatsApp / SMS на указанный номер.',
                    style: TextStyle(color: AppColors.gray600)),
              ),

              if (_codeSent) ...[
                const SizedBox(height: 16),
                _label('Код подтверждения'),
                TextField(
                  controller: _code,
                  focusNode: _codeF,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDec('', 'Введите код'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (_code.text.trim().length >= 4 && !_verifying)
                      ? () async {
                          setState(() => _verifying = true);
                          final ok = await _verifyCode();
                          setState(() {
                            _verifying = false;
                            _verified = ok;
                          });
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Неверный код. Попробуйте ещё раз.')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vacancy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Подтвердить номер'),
                ),
                if (_verified)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Номер подтверждён',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
