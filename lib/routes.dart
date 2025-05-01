import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'screens/components/privacy_policy_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/person_type_screen.dart';
import 'screens/person_screens/fisica_data_screen.dart';
import 'screens/moral_screens/moral_data_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const SplashScreen(),
  '/onboarding': (_) => const OnboardingScreen(),
  '/person-type': (_) => const PersonTypeScreen(),
  '/privacy': (_) => const PrivacyPolicyScreen(),
  '/fisica-data': (_) => const FisicaDataScreen(),
  '/moral-data': (_) => const MoralDataScreen(),
};
