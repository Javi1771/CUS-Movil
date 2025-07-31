// routes/secretarias_routes.dart

import 'package:flutter/material.dart';
import '../screens/secretarias_screen.dart';

final Map<String, WidgetBuilder> secretariasRoutes = {
  '/secretarias': (_) => const SecretariasScreen(),
};