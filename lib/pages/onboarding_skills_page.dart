import 'package:flutter/material.dart';


class OnboardingSkillsPage extends StatelessWidget {
const OnboardingSkillsPage({super.key});
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Ваши навыки')),
body: Column(
children: [
const SizedBox(height: 12),
Wrap(spacing: 8, runSpacing: 8, children: const [
Chip(label: Text('Курьер')),
Chip(label: Text('Дизайн')),
Chip(label: Text('Сборка мебели')),
Chip(label: Text('Разработка Flutter')),
]),
const Spacer(),
Padding(
padding: const EdgeInsets.all(16.0),
child: ElevatedButton(
onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
child: const Text('Готово'),
),
),
],
),
);
}
}