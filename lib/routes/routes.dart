import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';
import '../screens/moral_screens/moral_direccion_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/components/privacy_policy_screen.dart';
import '../screens/person_screens/contact_data_screen.dart';
import '../screens/person_screens/direccion_data_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/person_type_screen.dart';
import '../screens/person_screens/fisica_data_screen.dart';
import '../screens/moral_screens/moral_data_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const SplashScreen(),
  '/onboarding': (_) => const OnboardingScreen(),
  '/auth': (_) => const AuthScreen(),
  '/person-type': (_) => const PersonTypeScreen(),
  '/privacy': (_) => const PrivacyPolicyScreen(),
  '/fisica-data': (_) => const FisicaDataScreen(),
  '/moral-data': (_) => const MoralDataScreen(),
  '/direccion-data': (_) => const DireccionDataScreen(),
  '/direccion-moral': (_) => const DireccionMoralScreen(),
  '/contact-data': (_) => const ContactDataScreen(),
};
