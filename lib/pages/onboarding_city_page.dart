import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class OnboardingCityPage extends StatelessWidget {
const OnboardingCityPage({super.key});
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Ваш город')),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
children: [
const Text('Укажите город работы или включите «Удалённо».',
style: TextStyle(color: Colors.white70)),
const SizedBox(height: 16),
TextField(
decoration: const InputDecoration(labelText: 'Город'),
style: const TextStyle(color: Colors.white),
),
const SizedBox(height: 24),
Row(children: [
const Icon(Icons.laptop, color: Colors.white70),
const SizedBox(width: 8),
const Expanded(
child: Text('Работаю удалённо',
style: TextStyle(color: Colors.white))),
Switch(value: true, onChanged: (v) {}),
]),
const Spacer(),
ElevatedButton(
onPressed: () => Navigator.pushReplacementNamed(context, '/onb/skills'),
child: const Text('Далее'),
)
],
),
),
);
}
}