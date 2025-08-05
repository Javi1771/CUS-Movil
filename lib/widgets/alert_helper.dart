// alert_helper.dart

import 'package:flutter/material.dart';

enum AlertType { success, error, warning }

class AlertHelper {
  //? 1) Key global para acceder siempre al ScaffoldMessenger
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showAlert(
    String message, {
    required AlertType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    late Color backgroundColor;
    late IconData icon;
    switch (type) {
      case AlertType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case AlertType.error:
        backgroundColor = Colors.red.shade700;
        icon = Icons.error_outline;
        break;
      case AlertType.warning:
        backgroundColor = Colors.amber.shade800;
        icon = Icons.warning_amber_rounded;
        break;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: backgroundColor,
      elevation: 6,
      duration: duration,
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Cerrar',
        textColor: Colors.white,
        //? 2) Aquí no usamos `context`, sino el messengerKey
        onPressed: () =>
            messengerKey.currentState?.hideCurrentSnackBar(),
      ),
    );

    //? 3) Mostrar usando el GlobalKey
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
