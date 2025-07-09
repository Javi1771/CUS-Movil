import 'package:cus_movil/screens/components/work_screens/work_contact_screen.dart';
import 'package:cus_movil/screens/components/work_screens/work_data_screen.dart';
import 'package:cus_movil/screens/components/work_screens/work_direccion_screen.dart';
import 'package:cus_movil/screens/components/work_screens/work_preview_screen.dart';
import 'package:cus_movil/screens/components/work_screens/work_terms__screen.dart';
import 'package:cus_movil/screens/mis_documentos_screen.dart';
import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login/auth_screen.dart';
import '../screens/login/password_recovery_screen.dart';
import '../screens/login/person_type_screen.dart';
import '../screens/components/privacy_policy_screen.dart';

// Rutas personas físicas
import '../screens/person_screens/fisica_data_screen.dart';
import '../screens/person_screens/direccion_data_screen.dart';
import '../screens/person_screens/contact_data_screen.dart';
import '../screens/person_screens/terms_data_screen.dart';
import '../screens/person_screens/preview_data_screen.dart';

// Rutas personas morales
import '../screens/moral_screens/moral_data_screen.dart';
import '../screens/moral_screens/moral_direccion_screen.dart';
import '../screens/moral_screens/moral_contact_screen.dart';
import '../screens/moral_screens/moral_terms_screen.dart';
import '../screens/moral_screens/moral_preview_screen.dart';

// Rutas trabajo
import '../screens/work_screens/work_data_screen.dart';
import '../screens/work_screens/work_direccion_screen.dart';
import '../screens/work_screens/work_contact_screen.dart';
import '../screens/work_screens/work_preview_screen.dart';

// Home y Mis Documentos
import '../screens/home_screen.dart';

// 🔹 Importa la pantalla de perfil del usuario
import '../screens/perfil_usuario_screen.dart';

// 🔹 RUTAS WORK (importa tus pantallas correspondientes)
import '../screens/work_screens/work_contact_screen.dart';
import '../screens/work_screens/work_direccion_screen.dart';
import '../screens/work_screens/work_preview_screen.dart';
import '../screens/work_screens/work_terms_screen.dart';
import '../screens/work_screens/work_data_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const SplashScreen(),
  '/onboarding': (_) => const OnboardingScreen(),
  '/auth': (_) => const AuthScreen(),
  '/password-recovery': (_) => const PasswordRecoveryScreen(),
  '/person-type': (_) => const PersonTypeScreen(),
  '/privacy': (_) => const PrivacyPolicyScreen(),

  // 🔹 RUTAS PERSONAS FÍSICAS
  '/fisica-data': (_) => const FisicaDataScreen(),
  '/direccion-data': (_) => const DireccionDataScreen(),
  '/contact-data': (_) => const ContactDataScreen(),
  '/terms-data': (_) => const TermsAndConditionsScreen(),
  '/preview-data': (_) => const PreviewScreen(),

  // 🔹 RUTAS PERSONAS MORALES
  '/contact-data': (_) => const ContactDataScreen(),
  '/direccion-data': (_) => const DireccionDataScreen(),
  '/terms-data': (_) => const TermsAndConditionsScreen(),
  '/preview-data': (_) => const PreviewScreen(),
  '/moral-data': (_) => const MoralDataScreen(),
  '/direccion-moral': (_) => const DireccionMoralScreen(),
  '/contact-moral': (_) => const ContactMoralScreen(),
  '/terms-moral': (_) => const TermsAndConditionsMoralScreen(),
  '/preview-moral': (_) => const PreviewMoralScreen(),

  // 🔹 RUTAS WORK (TRABAJO)
  '/work-data': (_) => const WorkDataScreen(),
  '/work-direccion': (_) =>
      const WorkDireccionScreen(), // 🔹 Aquí está el cambio
  '/work-contact': (_) => const ContactWorkScreen(),
  '/work-terms': (_) => const TermsAndConditionsWorkScreen(),
  '/work-preview': (_) => const PreviewWorkScreen(),

  // 🔹 GENERALES
  '/work-data': (_) => const WorkDataScreen(),
  '/work-direccion': (_) => const WorkDireccionScreen(),
  '/work-contact': (_) => const ContactWorkScreen(),
  '/work-preview': (_) => const PreviewWorkScreen(),
  '/home': (_) => const HomeScreen(),
  '/mis-documentos': (_) => MisDocumentosScreen(),

  // 🔹 Nueva ruta para PerfilUsuarioScreen
  '/perfil-usuario': (_) => const PerfilUsuarioScreen(userData: {}),
};
