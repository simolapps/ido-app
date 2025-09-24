// === file: register_page.dart ===
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../services/storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phone = TextEditingController(text: '8');
  final _code = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _middle = TextEditingController();

  final _phoneF = FocusNode();
  final _codeF = FocusNode();
  final _firstF = FocusNode();
  final _lastF = FocusNode();
  final _middleF = FocusNode();

  bool _codeSent = false;
  bool _codeVerified = false;
  bool _verifying = false;
  bool _autoSubmitted = false;

  static const _send = 'https://simolapps.tw1.ru/api/send_code.php';
  static const _verifyCodeUrl = 'https://simolapps.tw1.ru/api/verify_code.php';
  static const _reg = 'https://simolapps.tw1.ru/api/register_user_media.php';

  @override
  void initState() {
    super.initState();
    _phone.addListener(_onPhoneChanged);
    _code.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final logged = await Storage().isLoggedIn();
      if (!mounted) return;
      if (logged) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        _phoneF.requestFocus();
      }
    });
  }

  void _onPhoneChanged() {
    if (_phone.text == !_codeSent && !_codeVerified) {
      setState(() => _codeSent = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _codeF.requestFocus());
    }
  }

  void _onCodeChanged() {
    if (!_verifying && !_autoSubmitted && !_codeVerified) {
      _autoSubmitted = true;
      _verify();
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _first.dispose();
    _last.dispose();
    _middle.dispose();
    _phoneF.dispose();
    _codeF.dispose();
    _firstF.dispose();
    _lastF.dispose();
    _middleF.dispose();
    super.dispose();
  }

  Future<void> _postCode() async {
    final r = await http.post(Uri.parse(_send),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phone.text}));
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) setState(() => _codeSent = true);
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      final r = await http.post(Uri.parse(_verifyCodeUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': _phone.text, 'code': _code.text}));
      final data = jsonDecode(r.body);
      if (data['success'] == true && data['user'] != null) {
        final u = data['user'];

        final masterId = int.parse(u['master_id'].toString());
        final phone = (u['phone'] ?? _phone.text).toString();

        await Storage().saveAuth(
          masterId: masterId,
          phone: phone,
          name: ((u['first_name'] ?? '').toString()).trim(),
          access: data['tokens']?['access'],
          refresh: data['tokens']?['refresh'],
        );

        // сохраняем id в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', masterId);

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        return;
      }
      if (data['success'] == true && data['user']?['has_profile'] == false) {
        setState(() => _codeVerified = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _firstF.requestFocus());
        return;
      }
      _autoSubmitted = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный код. Попробуйте ещё раз.')),
        );
      }
    } catch (_) {
      _autoSubmitted = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка соединения. Повторите позже.')),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _register() async {
    final r = await http.post(Uri.parse(_reg),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phone.text,
          'first_name': _first.text,
          'last_name': _last.text,
          'middle_name': _middle.text,
        }));
    final data = jsonDecode(r.body);
    if (data['success'] == true && data['user'] != null) {
      final u = data['user'];
      final masterId = int.parse(u['master_id'].toString());

      await Storage().saveAuth(
        masterId: masterId,
        phone: (u['phone'] ?? _phone.text).toString(),
        name: (_first.text).trim(),
        access: data['tokens']?['access'],
        refresh: data['tokens']?['refresh'],
      );

      // сохраняем id
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', masterId);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/onb/city', (route) => false);
    }
  }

  InputDecoration _dec(String label, {bool focused = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autofocus = false,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.black), // чёрный текст
      decoration: _dec(label, focused: focusNode.hasFocus),
      onSubmitted: onSubmitted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLand = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Colors.white, // фон белый
      appBar: AppBar(
        title: const Text('Регистрация', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (Navigator.canPop(context))
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Center(
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: isLand
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_card(child: SizedBox(width: 360, child: _form()))],
                  )
                : _card(child: _form()),
          ),
          if (_verifying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _card({required Widget child}) => Card(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      );

  Widget _form() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_codeVerified) ...[
            _glassField(
              controller: _phone,
              focusNode: _phoneF,
              label: 'Номер телефона',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (!_codeSent)
              ElevatedButton(onPressed: _postCode, child: const Text('Отправить код')),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              _glassField(
                controller: _code,
                focusNode: _codeF,
                label: 'Код подтверждения',
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: const Text('Подтвердить код'),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              '📩 Код придёт в WhatsApp',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          if (_codeVerified) ...[
            _glassField(
              controller: _first,
              focusNode: _firstF,
              label: 'Имя',
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            _glassField(
              controller: _last,
              focusNode: _lastF,
              label: 'Фамилия',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _glassField(
              controller: _middle,
              focusNode: _middleF,
              label: 'Отчество',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifying ? null : _register,
              child: const Text('Завершить регистрацию'),
            ),
          ],
        ],
      );
}
