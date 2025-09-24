import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'app_router.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // (необязательно) отлавливаем необработанные ошибки
  runZonedGuarded(() async {
    final storage = Storage();
    final isLoggedIn = await storage.isLoggedIn();

    runApp(IdoApp(initialRoute: isLoggedIn ? '/home' : '/register'));
  }, (error, stack) {
    // TODO: добавить логирование/Crashlytics
    // print('Uncaught in main: $error\n$stack');
  });
}

class IdoApp extends StatelessWidget {
  final String initialRoute;
  const IdoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDO Jobs',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routes: AppRouter.routes,
      initialRoute: initialRoute,
    );
  }
}
