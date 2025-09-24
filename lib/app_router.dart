import 'package:flutter/material.dart';
import 'pages/register_page.dart';
import 'pages/onboarding_city_page.dart';
import 'pages/onboarding_skills_page.dart';
import 'pages/home_shell.dart';


class AppRouter {
static Map<String, WidgetBuilder> routes = {
'/': (_) => const RegisterPage(),
'/register': (_) => const RegisterPage(),
'/onb/city': (_) => const OnboardingCityPage(),
'/onb/skills': (_) => const OnboardingSkillsPage(),
'/home': (_) => const HomeShell(),
};
}