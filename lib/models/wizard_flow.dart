// lib/models/wizard_flow.dart
//
// ВАЖНО: здесь НЕ объявляем AddressConfig!
// Используем AddressConfig из step_config.dart.

import 'step_config.dart'; // даёт AddressConfig

class WizardFlow {
  final List<Map<String, dynamic>> steps; // «сырые» JSON шаги
  final AddressConfig address;            // тип из step_config.dart

  const WizardFlow({
    required this.steps,
    required this.address,
  });

  factory WizardFlow.fromJson(Map<String, dynamic> j) {
    final steps = (j['steps'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final addrJson = (j['address'] as Map?)?.cast<String, dynamic>();
    final address = AddressConfig.fromJson(addrJson);

    return WizardFlow(steps: steps, address: address);
  }
}
